# Modelo Relacional e Chaves (EOS-003)

Para garantir integridade transacional forte e evitar órfãos, o modelo segue regras estritas de Foreign Keys (FK).

## 1. Relacionamentos do Core de Produtos
- **`itens_ficha_tecnica`**: `produto_id` ON DELETE CASCADE, `ingrediente_id` ON DELETE RESTRICT (Impede deletar ingrediente usado).
- **`regras_porcionamento`**: `produto_id` ON DELETE CASCADE. Se o produto for excluído, as regras somem.

## 2. Relacionamentos de Oferta
- **`ofertas`**: `cardapio_id` ON DELETE CASCADE. `produto_id` ON DELETE RESTRICT (Não posso deletar um produto se ele já foi ofertado).

## 3. Relacionamentos Transacionais (Engine)
- **`pedidos`**: 
  - `cliente_id` ON DELETE RESTRICT (Pedidos históricos nunca perdem o dono).
  - `caixa_id` ON DELETE RESTRICT (Impede deleção acidental de sessões de caixa faturadas).
- **`itens_pedido`**: 
  - `pedido_id` ON DELETE CASCADE (Se expurgar o pedido rascunho, seus itens morrem).
  - `oferta_id` ON DELETE RESTRICT (Não se apaga uma oferta se houver vendas atreladas a ela).
- **`pagamentos`**:
  - `pedido_id` ON DELETE CASCADE (Rascunhos ou pedidos expurgados levam as tentativas de pagamento).

## 4. Chaves Compostas e Únicas (Constraints)
- **`cardapios`**: UNIQUE(`data_referencia`) - Apenas um cardápio por dia.
- **`ofertas`**: UNIQUE(`cardapio_id`, `produto_id`, `tamanho`) - Não posso ofertar duas "Cachorro-Quente GRANDE" no mesmo dia.
- **`clientes`**: UNIQUE(`telefone`) - Telefone é a chave de identidade principal para WhatsApp.
- **`regras_porcionamento`**: UNIQUE(`produto_id`, `tamanho`) - Apenas uma regra (multiplicador) por prato e por tamanho.
