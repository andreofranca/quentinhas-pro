-- V6__nucleo_comercial.sql
CREATE SEQUENCE IF NOT EXISTS seq_pedido_comercial START WITH 1001;
ALTER TABLE pedidos ADD COLUMN IF NOT EXISTS numero_comercial VARCHAR(20);

CREATE TABLE IF NOT EXISTS produto_variacoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id UUID NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    tamanho VARCHAR(50) NOT NULL,
    preco NUMERIC(10,2) NOT NULL CHECK (preco >= 0),
    ativo BOOLEAN NOT NULL DEFAULT true,
    UNIQUE(produto_id, tamanho)
);

CREATE TABLE IF NOT EXISTS adicionais (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(100) NOT NULL,
    preco NUMERIC(10,2) NOT NULL CHECK (preco >= 0),
    ativo BOOLEAN NOT NULL DEFAULT true
);

ALTER TABLE itens_pedido ADD COLUMN IF NOT EXISTS variacao_id UUID REFERENCES produto_variacoes(id) ON DELETE RESTRICT;
ALTER TABLE itens_pedido ADD COLUMN IF NOT EXISTS observacoes TEXT;
ALTER TABLE itens_pedido ADD COLUMN IF NOT EXISTS preco_unitario_aplicado NUMERIC(10,2);
ALTER TABLE itens_pedido ADD COLUMN IF NOT EXISTS subtotal_aplicado NUMERIC(10,2);

CREATE TABLE IF NOT EXISTS pedido_item_adicionais (
    item_pedido_id UUID NOT NULL REFERENCES itens_pedido(id) ON DELETE CASCADE,
    adicional_id UUID NOT NULL REFERENCES adicionais(id) ON DELETE RESTRICT,
    preco_aplicado NUMERIC(10,2) NOT NULL CHECK (preco_aplicado >= 0),
    PRIMARY KEY(item_pedido_id, adicional_id)
);

-- We don't drop anything to preserve legacy support if needed, but we start using these new tables.
-- Actually, the user says: "Preservar compatibilidade com o modelo atual... NÃO usar DROP destrutivo"
