INSERT INTO produtos (id, nome, descricao, categoria, preco_base, ativo, estoque_atual, estoque_minimo) VALUES 
(gen_random_uuid(), 'Coca-Cola 350ml', 'Lata', 'BEBIDA', 5.00, true, 50, 10),
(gen_random_uuid(), 'Guaraná Antarctica 350ml', 'Lata', 'BEBIDA', 5.00, true, 50, 10),
(gen_random_uuid(), 'Água Mineral 500ml', 'Sem Gás', 'BEBIDA', 3.00, true, 50, 10);

INSERT INTO produto_variacoes (id, produto_id, tamanho, preco, ativo)
SELECT gen_random_uuid(), id, 'UNICA', preco_base, true
FROM produtos
WHERE categoria = 'BEBIDA' AND id NOT IN (SELECT produto_id FROM produto_variacoes);
