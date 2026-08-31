# EOS-PROD-04: Backoffice Real de Produtos

## 1. O que foi feito
- Eliminada a dependência do mock local cardapio nas telas TelaGestaoProdutos e TelaCadastroProduto.
- Adicionado o campo tivo (BOOLEAN) à tabela produtos via migração Flyway V3__add_ativo_produto.sql para suportar exclusão lógica (soft delete).
- Implementado CRUD completo no backend Spring Boot (ProdutoController, ProdutoService, ProdutoRepository).
- Implementado consumo do novo endpoint de produtos no Flutter via GestaoProdutosService.
- Atualizados os testes de integração do backend e testes unitários do Flutter.
- Refatorado o Produto.fromJsonFull no Dart para parse completo dos campos adicionados.

## 2. Migrações Executadas
- V3__add_ativo_produto.sql: ALTER TABLE produtos ADD COLUMN ativo BOOLEAN NOT NULL DEFAULT TRUE;
- Executadas tanto no banco quentinhas quanto quentinhas_test.

## 3. Mapeamento Final (Produto, Oferta, Tamanho)
- **Produto**: Entidade base do sistema, gerenciada em TelaGestaoProdutos. Contém nome, descrição, preço_base, categoria, ficha_tecnica, estoque_atual, estoque_minimo e tivo (true/false).
- **Oferta (OfertaQuentinha)**: Refere-se a um Produto dentro de um Cardápio ativo. O preço da oferta pode divergir do preço_base do Produto dependendo da estratégia. 
- **Oferta Tamanho (TamanhoQuentinha)**: Adicionais/Variações de uma Oferta que configuram multiplicadores de preço (ex: M, G) dependendo das configurações.
- **Relacionamento**: A deleção de um Produto foi feita de forma LÓGICA (tivo = false) para evitar violação de restrição de chave estrangeira nas tabelas ofertas e itens_ficha_tecnica, preservando o histórico de pedidos. O frontend agora ignora ou trata visualmente produtos desativados, permitindo o correto funcionamento do catálogo de ofertas sem corromper o banco.
