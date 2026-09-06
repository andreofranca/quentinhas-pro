INSERT INTO ofertas (id, produto_id, preco_vigente, tamanho, ativo)
SELECT gen_random_uuid(), id, preco_base, 'MEDIA', true FROM produtos WHERE nome IN ('Quentinha Vegetariana', 'Quentinha de Linguiça Acebolada');
