# EOS-006.12 - PedidoDraft REST (Planning)

## 1. Auditoria do Domínio
Foi inspecionado o código Flutter (`PedidoDraft`, `TamanhoOpcao`, `ClienteContato`) e o banco de dados PostgreSQL (`rpc_processar_pedido`, schema V1).
- O Flutter gera um DTO completo de intenção de compra.
- A RPC `rpc_processar_pedido` recebe um `JSONB` e executa um bloco atômico.
- Nenhuma responsabilidade de estoque ou cálculo concorrente é feita no Flutter; ele apenas manda a intenção.

## 2. Contrato REST Proposto
Endpoint: `POST /api/pedidos`
Payload (JSON):
```json
{
  "caixaId": "uuid",
  "cliente": {
    "nome": "João da Silva",
    "telefone": "5511999999999"
  },
  "modalidade": "ENTREGA",
  "taxaEntrega": 5.00,
  "enderecoEntrega": "Rua X, 123, Bairro Y, Cidade/UF - CEP 000",
  "observacoes": "Sem cebola",
  "total": 23.00,
  "itens": [
    {
      "ofertaId": "uuid",
      "quantidade": 1,
      "precoUnitario": 18.00,
      "subtotal": 18.00
    }
  ],
  "pagamento": {
    "formaPagamento": "DINHEIRO",
    "valor": 23.00,
    "valorRecebido": 50.00,
    "troco": 27.00
  },
  "provedorEvento": "APP_FLUTTER",
  "externalEventId": "hash-unico-idempotencia"
}
```

## 3. Fluxo Transacional e Papel do Java
**Regra: A tela mostra. A API orquestra. O banco decide.**
O Spring Boot **NÃO** reinventará o controle de estoque, nem baixará estoque manualmente, nem implementará locks em memória.
O fluxo no Java será:
1. Recebe a requisição HTTP;
2. Valida o JWT (Autenticação);
3. Valida a semântica do contrato (Valores negativos? Matemáticas básicas batem?);
4. Converte o DTO Java para o formato `JSONB` esperado pela RPC;
5. Executa a RPC no PostgreSQL (`SELECT rpc_processar_pedido(cast(:payload as jsonb))`);
6. Captura eventuais exceções (estoque, idempotência) e as traduz para HTTP.

## 4. Idempotência
A RPC já garante idempotência via `UNIQUE(provedor_evento, external_event_id)` na tabela `pedidos`.
Se o Java receber uma requisição duplicada, ao chamar a RPC, o PostgreSQL lançará uma violação de constraint de unicidade (`PSQLException`).
O Java traduzirá essa exceção para um `HTTP 409 Conflict` (ou 200 OK se decidirmos retornar o pedido já existente, mas no padrão REST estrito para duplicados de criação, 409 é adequado ou retornar o estado atual). Para esta EOS, mapearemos para 409.

## 5. Regra de Pagamentos (Dinheiro e Troco)
A autoridade do negócio é distribuída corretamente:
- O banco possui *constraints* fortes (`valor_recebido >= valor`, `troco >= 0`).
- O Java (Spring Boot) fará a validação defensiva antes de chamar a base:
  - Se `formaPagamento == DINHEIRO`, o Java verifica se `valorRecebido >= total` e se `troco == valorRecebido - total`. Se não bater, devolve `400 Bad Request`.
  - Impede corrupção de valores forjados pelo Flutter.

## 6. Tratamento de Estoque e Concorrência
O catálogo lido no Flutter é volátil. No momento do POST, a verdadeira checagem ocorre na RPC através de `FOR UPDATE` nas ofertas correspondentes.
- Se 50 clientes tentarem comprar a última quentinha, o PostgreSQL serializa os acessos. O primeiro leva, atualiza `reservado_atual`. O segundo, ao ler no `FOR UPDATE`, verá que estourou o limite e o PostgreSQL lança `RAISE EXCEPTION 'Estoque esgotado...'`.
- O Java intercepta o erro "Estoque esgotado" e mapeia para `409 Conflict`. Overselling = 0.

## 7. Mapeamento de Erros HTTP
- **400 Bad Request**: Erros de `@Valid` (DTO), matemática do troco/subtotal incorreta, campos ausentes.
- **401 Unauthorized**: Falta de token JWT ou token expirado.
- **403 Forbidden**: Token válido, mas sem a Role correta (ex: Caixa exigido).
- **404 Not Found**: Apenas se aplicável a consultas diretas (não usado na criação que lança falhas de negócio).
- **409 Conflict**: Violação de Idempotência (`externalEventId` já existe) ou Estoque Esgotado.
- **422 Unprocessable Entity**: Violações de negócio levantadas pela RPC (ex: "Caixa X não está aberto", "Quantidade inválida").
- **500 Internal Server Error**: Falhas de banco, timeout, erros não tratados.

## 8. Testes Planejados
1. Pedido simples validado com sucesso;
2. Pedido com múltiplos itens;
3. Pedido com pagamento via PIX;
4. Pedido com dinheiro sem troco;
5. Pedido com dinheiro e cálculo correto de troco;
6. Pedido rejeitado (400) por dinheiro/troco insuficiente ou matemática errada;
7. Pedido rejeitado (422/409) por oferta inexistente/estoque;
8. Pedido rejeitado (409) por estoque insuficiente;
9. Pedido rejeitado (409) por externalEventId duplicado (Idempotência provada);
10. Rollback do PostgreSQL assegurado em caso de falha no meio da RPC;
11. Autenticação JWT funcionando na rota `/api/pedidos`;
12. Payload corrompido (400);
13. Teste de concorrência disparando múltiplas threads (opcional, pois o PostgreSQL já foi provado na EOS-006.7).

## 9. Riscos e Decisões Arquiteturais
- **Risco**: Manipulação de strings JSON no Java pode ser frágil.
  - **Decisão**: Usaremos `ObjectMapper` do Jackson para serializar o Request DTO perfeitamente em JSON String e passar para a RPC, garantindo formatação correta do `JSONB`.
- **Risco**: Capturar os erros textuais da RPC via Regex/String matching (`PSQLException`).
  - **Decisão**: É a abordagem mais pragmática para não alterar o banco agora. O GlobalExceptionHandler fará o parse da mensagem do Postgres para identificar "Estoque esgotado" ou "Caixa não aberto".


## Checkpoint
Hash do commit de implementação: 7a46e4e
