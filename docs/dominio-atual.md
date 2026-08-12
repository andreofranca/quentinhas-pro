# Domínio Atual (Baseline)

O modelo de domínio atual do projeto encontra-se particionado em duas realidades: o que está modelado no banco de dados e o que está modelado apenas em memória (mock).

## Domínio Persistido (Supabase)
- **Ingrediente:** Entidade primária do estoque (matéria-prima). Contém custos, unidade de medida e limites.
- **Produto:** Item de venda ao consumidor final. Contém preço e categoria.
- **Item Ficha Técnica:** Relacionamento que descreve a composição (Ingredientes e Quantidades) necessária para formar um Produto.
- **Movimentação Estoque:** Entidade de auditoria que registra cada alteração no estoque de ingredientes.

## Domínio em Memória (Mocks)
- **Usuário:** Representa o funcionário/admin do sistema. (Mocado em `listaUsuarios`).
- **Pedido:** Representa a venda (carrinho de produtos, status de pagamento, mesa/delivery). Atualmente existe apenas no estado efêmero do Flutter.
- **Caixa:** Agrupamento de pedidos (pendentes, concluídos, cancelados).

## Conclusão de Domínio
O domínio de **Estoque e Ficha Técnica** está maduro e testado. O domínio de **Operações e Vendas** é um rascunho funcional que requer modelagem real (Entidades e Repositórios).
