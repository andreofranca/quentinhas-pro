-- V8__cardapio_completo.sql
-- Enriquecimento profissional do cardapio de quentinhas, bebidas e adicionais

-- 1. Inserir ou atualizar quentinhas completas
INSERT INTO produtos (id, nome, descricao, categoria, preco_base, ativo, estoque_atual, estoque_minimo) VALUES 
('b0849282-5ce9-408c-bd5b-f7bc8d5dd557', 'Bife de Carne Acebolado', 'Bife bovino macio acebolado, arroz branco, feijão carioca e purê de batatas', 'MARMITA', 23.00, true, 35, 8),
('00000000-0000-0000-0000-000000000003', 'Quentinha de Frango Grelhado', 'Filé de peito grelhado suculento com ervas finas, arroz soltinho, feijão e legumes salteados', 'MARMITA', 22.00, true, 40, 8),
('2b2bf144-3389-4bd5-af4f-194caab210c3', 'Quentinha Vegetariana', 'Mix de legumes frescos salteados no azeite, lentilha temperada, arroz integral e purê', 'MARMITA', 21.00, true, 30, 5),
('7cbda00d-fe64-46fe-9a54-db1a2a95022a', 'Quentinha de Linguiça Acebolada', 'Linguiça toscana mineira grelhada com cebola caramelizada, tutu de feijão, arroz e couve', 'MARMITA', 23.00, true, 30, 5),
('a1111111-1111-1111-1111-111111111111', 'Feijoada Completa Tradicional', 'Feijoada no capricho com carnes nobres, arroz branco, couve refogada, farofa crocante e laranja', 'MARMITA', 26.00, true, 45, 10),
('a2222222-2222-2222-2222-222222222222', 'Filé de Frango à Parmegiana', 'Filé crocante coberto com molho caseiro de tomate e queijo mussarela gratinado, arroz e fritas', 'MARMITA', 27.00, true, 35, 8)
ON CONFLICT (id) DO UPDATE SET 
    nome = EXCLUDED.nome,
    descricao = EXCLUDED.descricao,
    categoria = EXCLUDED.categoria,
    preco_base = EXCLUDED.preco_base,
    ativo = EXCLUDED.ativo,
    estoque_atual = EXCLUDED.estoque_atual,
    estoque_minimo = EXCLUDED.estoque_minimo;

-- 2. Inserir ou atualizar novas bebidas
INSERT INTO produtos (id, nome, descricao, categoria, preco_base, ativo, estoque_atual, estoque_minimo) VALUES 
('b1111111-1111-1111-1111-111111111111', 'Coca-Cola Zero 350ml', 'Lata gelada', 'BEBIDA', 5.00, true, 40, 10),
('b2222222-2222-2222-2222-222222222222', 'Suco Natural de Laranja 400ml', 'Garrafinha de suco 100% natural bem gelado', 'BEBIDA', 7.00, true, 30, 8),
('b3333333-3333-3333-3333-333333333333', 'Água Mineral c/ Gás 500ml', 'Garrafa gelada', 'BEBIDA', 4.00, true, 40, 10)
ON CONFLICT (id) DO UPDATE SET 
    nome = EXCLUDED.nome,
    descricao = EXCLUDED.descricao,
    categoria = EXCLUDED.categoria,
    preco_base = EXCLUDED.preco_base,
    ativo = EXCLUDED.ativo,
    estoque_atual = EXCLUDED.estoque_atual,
    estoque_minimo = EXCLUDED.estoque_minimo;

-- 3. Inserir ou atualizar variações completas (PEQUENA, MEDIA, GRANDE) para todas as quentinhas
-- Frango Grelhado
INSERT INTO produto_variacoes (id, produto_id, tamanho, preco, ativo) VALUES 
(gen_random_uuid(), '00000000-0000-0000-0000-000000000003', 'PEQUENA', 19.00, true),
(gen_random_uuid(), '00000000-0000-0000-0000-000000000003', 'MEDIA', 22.00, true),
(gen_random_uuid(), '00000000-0000-0000-0000-000000000003', 'GRANDE', 25.00, true)
ON CONFLICT (produto_id, tamanho) DO UPDATE SET preco = EXCLUDED.preco, ativo = true;

-- Vegetariana
INSERT INTO produto_variacoes (id, produto_id, tamanho, preco, ativo) VALUES 
(gen_random_uuid(), '2b2bf144-3389-4bd5-af4f-194caab210c3', 'PEQUENA', 18.00, true),
(gen_random_uuid(), '2b2bf144-3389-4bd5-af4f-194caab210c3', 'MEDIA', 21.00, true),
(gen_random_uuid(), '2b2bf144-3389-4bd5-af4f-194caab210c3', 'GRANDE', 24.00, true)
ON CONFLICT (produto_id, tamanho) DO UPDATE SET preco = EXCLUDED.preco, ativo = true;

-- Linguiça Acebolada
INSERT INTO produto_variacoes (id, produto_id, tamanho, preco, ativo) VALUES 
(gen_random_uuid(), '7cbda00d-fe64-46fe-9a54-db1a2a95022a', 'PEQUENA', 20.00, true),
(gen_random_uuid(), '7cbda00d-fe64-46fe-9a54-db1a2a95022a', 'MEDIA', 23.00, true),
(gen_random_uuid(), '7cbda00d-fe64-46fe-9a54-db1a2a95022a', 'GRANDE', 26.00, true)
ON CONFLICT (produto_id, tamanho) DO UPDATE SET preco = EXCLUDED.preco, ativo = true;

-- Bife Acebolado
INSERT INTO produto_variacoes (id, produto_id, tamanho, preco, ativo) VALUES 
(gen_random_uuid(), 'b0849282-5ce9-408c-bd5b-f7bc8d5dd557', 'PEQUENA', 20.00, true),
(gen_random_uuid(), 'b0849282-5ce9-408c-bd5b-f7bc8d5dd557', 'MEDIA', 23.00, true),
(gen_random_uuid(), 'b0849282-5ce9-408c-bd5b-f7bc8d5dd557', 'GRANDE', 27.00, true)
ON CONFLICT (produto_id, tamanho) DO UPDATE SET preco = EXCLUDED.preco, ativo = true;

-- Feijoada Completa
INSERT INTO produto_variacoes (id, produto_id, tamanho, preco, ativo) VALUES 
(gen_random_uuid(), 'a1111111-1111-1111-1111-111111111111', 'PEQUENA', 22.00, true),
(gen_random_uuid(), 'a1111111-1111-1111-1111-111111111111', 'MEDIA', 26.00, true),
(gen_random_uuid(), 'a1111111-1111-1111-1111-111111111111', 'GRANDE', 30.00, true)
ON CONFLICT (produto_id, tamanho) DO UPDATE SET preco = EXCLUDED.preco, ativo = true;

-- Filé de Frango à Parmegiana
INSERT INTO produto_variacoes (id, produto_id, tamanho, preco, ativo) VALUES 
(gen_random_uuid(), 'a2222222-2222-2222-2222-222222222222', 'PEQUENA', 23.00, true),
(gen_random_uuid(), 'a2222222-2222-2222-2222-222222222222', 'MEDIA', 27.00, true),
(gen_random_uuid(), 'a2222222-2222-2222-2222-222222222222', 'GRANDE', 31.00, true)
ON CONFLICT (produto_id, tamanho) DO UPDATE SET preco = EXCLUDED.preco, ativo = true;

-- 4. Inserir variações (UNICA) para as bebidas
INSERT INTO produto_variacoes (id, produto_id, tamanho, preco, ativo)
SELECT gen_random_uuid(), id, 'UNICA', preco_base, true
FROM produtos
WHERE categoria = 'BEBIDA' AND id NOT IN (SELECT produto_id FROM produto_variacoes)
ON CONFLICT (produto_id, tamanho) DO NOTHING;

-- 5. Inserir ou atualizar adicionais profissionais
INSERT INTO adicionais (id, nome, preco, ativo) VALUES 
('3485d8eb-a19e-4e03-a392-3a6c04095556', 'Ovo Frito na Manteiga', 3.00, true),
('332c3f25-3774-4c59-8042-f915957d8230', 'Torresmo Crocante Especial', 5.00, true),
('7dae0c00-21a3-494b-b223-48e556621e31', 'Batata Frita Crocante', 6.00, true),
('60d6d22f-ef21-4d2e-9e0e-7548cb6477c8', 'Farofa Especial c/ Bacon', 4.00, true),
('c312f853-2fc9-4dd8-880e-db24c932884c', 'Queijo Coalho Grelhado', 4.50, true),
('93400c10-247f-4ef7-856c-76d561d5aacf', 'Vinagrete da Casa', 3.00, true)
ON CONFLICT (id) DO UPDATE SET 
    nome = EXCLUDED.nome,
    preco = EXCLUDED.preco,
    ativo = EXCLUDED.ativo;
