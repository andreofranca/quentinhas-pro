# EOS-006.11 - Catálogo e Ofertas REST

## 1. Estrutura Encontrada no Banco (`V1__init_schema.sql`)
- **`produtos`**: id, nome, descricao, categoria, preco_base.
- **`cardapios`**: id, data_referencia, status (`ABERTO`, `FECHADO`, `CANCELADO`).
- **`ofertas`**: id, cardapio_id, produto_id, tamanho (`PEQUENA`, `MEDIA`, `GRANDE`), preco_vigente, limite_producao, reservado_atual.

## 2. Endpoints
- `GET /api/catalogo`: Retorna os produtos e suas ofertas ativas para o cardápio 'ABERTO'.
- `GET /api/ofertas/{id}`: Detalhes de uma oferta específica.
- Ambos os endpoints são **públicos**.

## 3. DTOs
- `CatalogoResponse`, `ProdutoCatalogoResponse`, `TamanhoCatalogoResponse`
- `OfertaDetalheResponse`

## 4. Queries (Performance)
- `SELECT o FROM Oferta o JOIN FETCH o.produto p JOIN o.cardapio c WHERE c.status = 'ABERTO'`
Evita N+1 buscando as ofertas ativas e efetuando join fetch com produto.

## 5. Regras de Disponibilidade (Estoque)
- O estoque não é decrementado pelo GET.
- Disponibilidade = `limite_producao IS NULL OR limite_producao > reservado_atual`.
- Siglas retornadas: `PEQUENA -> P`, `MEDIA -> M`, `GRANDE -> G`.

## 6. Testes
Os testes englobam:
1. Catálogo populado;
2. Catálogo vazio;
3. Oferta existente (com e sem limite de produção);
4. 404 para oferta inexistente;
5. Segurança de endpoints públicos.
6. Isolamento do banco.

## 7. Impacto Futuro (Flutter)
- O aplicativo consumirá `/api/catalogo` para montar a interface inicial.
- As regras de indisponibilidade bloquearão cliques na interface, mas o backend continuará a arbitrar transações de fato no endpoint de Pedidos (usando Lock e RPC).

## 8. Checkpoint
- **Commit Hash:** `cc26bed` (feat(catalogo): implementar catalogo e ofertas REST)
