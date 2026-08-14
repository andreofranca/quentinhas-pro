# EOS-005: Supabase Transition Engine e Canais

Este documento registra as definições arquiteturais aplicadas à **Transition Engine** do Lanchonete Pro / Quentinhas Pro, garantindo que o PostgreSQL (Supabase) atue como o dono absoluto das regras de negócio.

## 1. O Ponto Central da Arquitetura

1. **Os Canais Não Têm Inteligência Mestra**
   Nem o Flutter Dashboard, nem o WhatsApp Mock, nem qualquer futura IA possuem autoridade para confirmar um pedido. O `PedidoDraft` serve apenas como intenção do cliente, estabilizada no Frontend.

2. **Supabase Transition Engine (Master RPC)**
   O Supabase recebeu a function `rpc_processar_pedido(payload JSONB)`. Esta RPC faz:
   - Bloqueio atômico de linha para prevenção estrita de overselling (`SELECT ... FOR UPDATE`).
   - Verificação e Upsert de cliente na base (CRM).
   - Verificação de estado do Caixa (só vende se caixa estiver `ABERTO`).
   - Escrita atômica do `pedido`, `itens_pedido` e `pagamentos`.
   - Se houver falha de estoque, a transação aborta (Rollback) e o Canal recebe a exceção (ex: "Item esgotado").

## 2. Ajustes de Domínio nas Migrations

Para suprir o gap de modelagem entre o antigo e a evolução operacional do Mock, alteramos os schemas localmente:
- Em `002_caixas_pedidos.sql`: Adicionadas colunas `taxa_entrega` e `observacoes`.
- Em `003_pagamentos.sql`: Adicionadas colunas `valor_recebido` e `troco`.
- Em `005_seguranca_rls.sql`: A antiga `rpc_reservar_oferta_atomica` foi substituída pelo processo master `rpc_processar_pedido`.

## 3. Serialização Flutter -> PostgreSQL

O objeto `PedidoDraft` recebeu o método `toRpcPayload()`. O Flutter passa este Map JSON diretamente para a API do Supabase, o qual o Supabase lê recursivamente em PLPGSQL, convertendo de JSONB nativo para as queries transacionais.

Exemplo do Output do Flutter (`toRpcPayload()`):
```json
{
  "caixa_id": "UUID_DO_CAIXA",
  "cliente": { "nome": "André", "telefone": "5521999999999" },
  "modalidade": "ENTREGA",
  "taxa_entrega": 5.00,
  "endereco_entrega": "Rua X, 12 - Centro/RJ - CEP: 00000-000",
  "observacoes": "Sem cebola",
  "total": 55.00,
  "itens": [
    {
      "oferta_id": "UUID_DA_OFERTA",
      "quantidade": 1,
      "preco_unitario": 50.00,
      "subtotal": 50.00
    }
  ],
  "pagamento": {
    "forma_pagamento": "DINHEIRO",
    "valor": 55.00,
    "valor_recebido": 100.00,
    "troco": 45.00
  },
  "provedor_evento": "ATENDENTE_DASHBOARD"
}
```

## 4. Estado Físico e Limitações (Pre-Flight)

Os arquivos SQL foram editados e testados a nível semântico, mas a execução final no `npx supabase start` falhou por inacessibilidade ao Named Pipe do Docker Desktop no ambiente atual (`//./pipe/dockerDesktopLinuxEngine`).

**Ação Pendente:**
Assim que o Host (Windows) reestabelecer a conexão correta de CLI com o daemon do Docker ou for providenciado o `supabase link` para um Cloud Lab, a suíte de SQL estará pronta para provisionamento via `supabase db push`. O frontend testado está síncrono com essa promessa estrutural.
