-- test-seed.sql
DELETE FROM pagamentos;
DELETE FROM itens_pedido;
DELETE FROM pedidos;
DELETE FROM ofertas;
DELETE FROM cardapios;
DELETE FROM regras_porcionamento;
DELETE FROM caixas;
DELETE FROM clientes;
DELETE FROM usuarios;
DELETE FROM produtos;

INSERT INTO usuarios (id, nome, email, password_hash, role) VALUES ('00000000-0000-0000-0000-000000000001', 'Operador Lab', 'lab@quentinhas.com', 'hash', 'CAIXA');
INSERT INTO clientes (id, telefone, nome) VALUES ('00000000-0000-0000-0000-000000000002', '11999999999', 'Cliente Lab');
INSERT INTO produtos (id, nome, categoria, preco_base) VALUES ('00000000-0000-0000-0000-000000000003', 'Marmita Teste', 'MARMITA', 20.00);
INSERT INTO cardapios (id, data_referencia, status) VALUES ('00000000-0000-0000-0000-000000000004', '2026-08-15', 'ABERTO');
-- Oferta inicial com limite 10
INSERT INTO ofertas (id, cardapio_id, produto_id, tamanho, preco_vigente, limite_producao, reservado_atual) VALUES ('00000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000003', 'MEDIA', 20.00, 10, 0);
INSERT INTO caixas (id, operador_id, terminal_id, status) VALUES ('00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', 'CAIXA_TESTE', 'ABERTO');
