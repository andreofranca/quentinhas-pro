INSERT INTO ofertas (id, produto_id, preco_venda, tamanho, disponivel, ativo)
SELECT gen_random_uuid(), id, preco_base, 'M', true, true FROM produtos WHERE nome IN ('Quentinha Vegetariana', 'Quentinha de Linguiça Acebolada');
