# Modelo de Dados Lógico (EOS-003)

O modelo foi desenhado de forma incremental, preservando o núcleo físico de Estoque (existente) e criando as estruturas para suportar o Domínio Comida Caseira.

## 1. Núcleo Existente (Preservado / Leve Adaptação)
* **`ingredientes`**: Mantida intacta. (id, nome, unidade_medida, estoque_atual, custo_unitario).
* **`produtos`**: Mantida. O `preco_venda` atual passa a ser um "preço base sugerido", pois o preço real será fixado na `oferta`.
* **`itens_ficha_tecnica`**: Mantida. (produto_id, ingrediente_id, quantidade_utilizada). Esta é a receita base.
* **`movimentacoes_estoque`**: Mantida intacta para auditoria.

## 2. Novo Domínio: Porcionamento e Catálogo
* **`regras_porcionamento`**: Define como a Ficha Técnica base escala por Tamanho.
  - `id` (UUID)
  - `produto_id` (FK para produtos)
  - `tamanho` (Enum: PEQUENA, MEDIA, GRANDE)
  - `multiplicador` (Decimal, ex: 1.0 para média, 1.5 para grande).

## 3. Novo Domínio: Oferta e Venda
* **`cardapios`**: A âncora do dia.
  - `id` (UUID)
  - `data_referencia` (Date)
  - `status` (Enum: ABERTO, FECHADO)
* **`ofertas`**: A disponibilização real.
  - `id` (UUID)
  - `cardapio_id` (FK)
  - `produto_id` (FK)
  - `tamanho` (Enum: PEQUENA, MEDIA, GRANDE)
  - `preco_vigente` (Decimal)
  - `limite_producao` (Integer, nulo = sem limite)
  - `reservado_atual` (Integer, default 0) -> Usado para Atomic Lock.

## 4. Novo Domínio: Clientes e Transações
* **`clientes`**: CRM Mínimo Persistente.
  - `id` (UUID)
  - `telefone` (Text, formatado E.164, Unique)
  - `nome` (Text, Nullable)
  - `endereco_padrao` (Text, Nullable)
* **`pedidos`**: A Transition Engine.
  - `id` (UUID)
  - `cliente_id` (FK)
  - `caixa_id` (FK)
  - `total` (Decimal)
  - `status_operacional` (Enum: RASCUNHO, RECEBIDO, CONFIRMADO, EM_PRODUCAO, PRONTO, SAIU_ENTREGA, ENTREGUE, FINALIZADO, CANCELADO)
  - `status_financeiro` (Enum: PENDENTE, PAGO, ESTORNADO)
  - `modalidade` (Enum: ENTREGA, RETIRADA, MESA)
  - `endereco_entrega` (Text, Nullable)
  - `external_event_id` (Text, Nullable, Unique) -> Chave de Idempotência.
* **`itens_pedido`**: Contexto comercial preservado.
  - `id` (UUID)
  - `pedido_id` (FK)
  - `oferta_id` (FK)
  - `quantidade` (Integer)
  - `preco_unitario` (Decimal)
  - `subtotal` (Decimal)
* **`pagamentos`**: Subdomínio Financeiro.
  - `id` (UUID)
  - `pedido_id` (FK)
  - `forma_pagamento` (Enum: PIX, DINHEIRO, CARTAO, OUTROS)
  - `valor` (Decimal)
  - `external_transaction_id` (Text, Nullable)

## 5. Novo Domínio: Caixa
* **`caixas`**:
  - `id` (UUID)
  - `operador_id` (FK auth.users)
  - `aberto_em` (Timestamp)
  - `fechado_em` (Timestamp, Nullable)
  - `status` (Enum: ABERTO, FECHADO)
