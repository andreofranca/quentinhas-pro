-- Migration 002: Operação de Caixas e Pedidos

-- 1. Caixas
CREATE TABLE caixas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    operador_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    terminal_id TEXT NOT NULL DEFAULT 'CAIXA_BALCAO',
    aberto_em TIMESTAMPTZ DEFAULT NOW(),
    fechado_em TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'ABERTO' CHECK (status IN ('ABERTO', 'FECHADO')),
    saldo_inicial DECIMAL(10,2) DEFAULT 0,
    saldo_informado DECIMAL(10,2)
);
-- Regra de negócio corrigida: 1 gaveta/terminal só pode ter 1 caixa aberto, mas um operador pode abrir em outro terminal se precisar.
CREATE UNIQUE INDEX idx_caixa_unico_aberto_terminal ON caixas(terminal_id) WHERE status = 'ABERTO';

-- 2. Pedidos (Transition Engine)
CREATE TABLE pedidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cliente_id UUID REFERENCES clientes(id) ON DELETE RESTRICT,
    caixa_id UUID REFERENCES caixas(id) ON DELETE RESTRICT,
    total DECIMAL(10,2) NOT NULL DEFAULT 0,
    status_operacional TEXT NOT NULL DEFAULT 'RASCUNHO',
    status_financeiro TEXT NOT NULL DEFAULT 'PENDENTE',
    modalidade TEXT NOT NULL,
    endereco_entrega TEXT,
    provedor_evento TEXT,       -- Ex: 'WHATSAPP'
    external_event_id TEXT,     -- Ex: 'msg_123'
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    -- Idempotência Forte
    UNIQUE(provedor_evento, external_event_id)
);

CREATE INDEX idx_pedidos_caixa ON pedidos(caixa_id);
CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);

-- 3. Itens do Pedido (Imutáveis após confirmação)
CREATE TABLE itens_pedido (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id UUID REFERENCES pedidos(id) ON DELETE CASCADE,
    oferta_id UUID REFERENCES ofertas(id) ON DELETE RESTRICT,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL
);
CREATE INDEX idx_itens_pedido_oferta ON itens_pedido(oferta_id);
