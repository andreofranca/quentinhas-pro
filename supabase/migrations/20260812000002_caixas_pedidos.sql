-- Migration 002: Operação de Caixas e Pedidos

-- 1. Caixas
CREATE TABLE caixas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    operador_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    terminal_id TEXT NOT NULL DEFAULT 'CAIXA_BALCAO',
    aberto_em TIMESTAMPTZ DEFAULT NOW(),
    fechado_em TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'ABERTO' CHECK (status IN ('ABERTO', 'FECHADO')),
    saldo_inicial DECIMAL(10,2) DEFAULT 0 CHECK (saldo_inicial >= 0),
    saldo_informado DECIMAL(10,2) CHECK (saldo_informado >= 0)
);
-- Regra de negócio corrigida: 1 gaveta/terminal só pode ter 1 caixa aberto, mas um operador pode abrir em outro terminal se precisar.
CREATE UNIQUE INDEX idx_caixa_unico_aberto_terminal ON caixas(terminal_id) WHERE status = 'ABERTO';

-- 2. Pedidos (Transition Engine)
CREATE TABLE pedidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cliente_id UUID REFERENCES clientes(id) ON DELETE RESTRICT,
    caixa_id UUID REFERENCES caixas(id) ON DELETE RESTRICT,
    total DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
    status_operacional TEXT NOT NULL DEFAULT 'RASCUNHO' CHECK (status_operacional IN ('RASCUNHO', 'CONFIRMADO', 'EM_PRODUCAO', 'PRONTO', 'SAIU_ENTREGA', 'ENTREGUE', 'CANCELADO')),
    status_financeiro TEXT NOT NULL DEFAULT 'PENDENTE' CHECK (status_financeiro IN ('PENDENTE', 'PAGO', 'ESTORNADO')),
    modalidade TEXT NOT NULL,
    taxa_entrega DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (taxa_entrega >= 0),
    endereco_entrega TEXT,
    observacoes TEXT,
    provedor_evento TEXT,       -- Ex: 'WHATSAPP'
    external_event_id TEXT,     -- Ex: 'msg_123'. NOTA: Se NULL, indica pedido interno sem evento externo (NULL não colide no UNIQUE).
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
    quantidade INT NOT NULL CHECK (quantidade > 0),
    preco_unitario DECIMAL(10,2) NOT NULL CHECK (preco_unitario >= 0),
    subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0)
);
CREATE INDEX idx_itens_pedido_oferta ON itens_pedido(oferta_id);
