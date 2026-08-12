# Regras de Negócio (Baseline)

As seguintes regras foram identificadas pela leitura da UI e dos Repositórios:

1. **Baixa de Estoque:** Ao confirmar a venda/produção de um Produto, o sistema varre a Ficha Técnica e reduz proporcionalmente o estoque de cada Ingrediente.
2. **Auditoria Obrigatória:** Toda alteração no saldo do ingrediente (entrada ou saída) gera obrigatoriamente um registro em `movimentacoes_estoque`.
3. **Autorização de Exceções:** Ações críticas, como cancelar um pedido, exigem intervenção/assinatura de um usuário com o cargo `ADMIN`. (Atualmente validado localmente contra lista em memória).
4. **Proteção do Admin:** O usuário Administrador Mestre não pode ser desativado do sistema.
5. **Composição Restrita:** Um `ItemFichaTecnica` restringe a exclusão de Ingredientes (ON DELETE RESTRICT no banco), impedindo que a receita de um produto fique quebrada por exclusão acidental.
