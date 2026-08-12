# Banco de Dados Atual (Baseline)

## Supabase (PostgreSQL)

O banco atual foi inicializado através do arquivo `schema_inicial.sql`.

### Tabelas
1. `ingredientes`: ID (UUID), Nome, Unidade, Estoque Atual, Estoque Mínimo, Custo.
2. `produtos`: ID (UUID), Nome, Preço Venda, Categoria.
3. `itens_ficha_tecnica`: FK_Produto, FK_Ingrediente, Quantidade (Chave primária composta).
4. `movimentacoes_estoque`: ID (UUID), FK_Ingrediente, Tipo Movimentação, Quantidade, Estoque Anterior/Atual, Observação.

### Segurança (RLS - Row Level Security)
- O RLS está *habilitado* em todas as tabelas.
- As políticas atuais (`POLICY`) estão configuradas como **permissivas totais** (`USING (true)`).
- **Alerta de Segurança:** Essas políticas são abertas para desenvolvimento e não devem ir para produção.

### Autenticação
- Não constam tabelas de usuários proprietárias nem uso ativo do módulo Supabase Auth no esquema mapeado.
