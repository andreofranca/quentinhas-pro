# Integridade, Concorrência e Idempotência (EOS-003)

Esta camada garante que falhas de rede, webhooks duplicados ou clientes clicando rápido demais não corrompam a produção.

## 1. Idempotência por Design
- **Origem (Edge):** O Webhook (WhatsApp) ou o Cliente envia um request de compra com um `UUID` gerado no dispositivo ou fornecido pela Meta (`external_event_id`).
- **Barreira (DB):** A tabela `pedidos` possui restrição UNIQUE para este campo.
- **Efeito:** Múltiplos requests idênticos resultam em `HTTP 409 Conflict` (ou o banco devolve silenciosamente o registro já criado), garantindo exatamente 1 pedido na esteira.

## 2. Lock Atômico (Atomicidade Transacional)
Para resolver a "Corrida da Última Quentinha", transferimos a responsabilidade do Frontend (Dart) para o Banco (PostgreSQL).

- **O Problema:** A Oferta tem `limite_producao = 30`. O `reservado_atual = 29`. Dois clientes confirmam o pedido no mesmo milissegundo.
- **A Solução (PL/pgSQL RPC):** Não usaremos dois comandos separados (`SELECT` seguido de `UPDATE`). Usaremos uma função RPC no Supabase (ex: `rpc_confirmar_pedido_v1`) que aplica um *Row-Level Lock*:

```sql
-- Esboço Lógico da Transação Interna
BEGIN;
SELECT reservado_atual, limite_producao 
FROM ofertas 
WHERE id = OfertaX FOR UPDATE; -- Bloqueia a linha da oferta para outras sessões

IF (reservado_atual + qtd_solicitada) > limite_producao THEN
   ROLLBACK; -- Excede o limite. Falha.
ELSE
   UPDATE ofertas SET reservado_atual = reservado_atual + qtd_solicitada;
   UPDATE pedidos SET status_operacional = 'RECEBIDO' WHERE id = PedidoY;
   COMMIT; -- Sucesso atômico.
END IF;
```

## 3. Desacoplamento da Interface Logística
Como definido pelo PO (DEC-004), o status financeiro e operacional correm paralelos.
Uma transação de "Baixa de Entrega" altera estritamente `status_operacional -> ENTREGUE`. 
O "Pagamento PIX Confirmado" afeta `pagamentos` e altera `status_financeiro -> PAGO`. 
Somente a transação "Finalizar Venda no Caixa" valida se ambas as dimensões permitem a conclusão.
