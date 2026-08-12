-- Migration 003: Subdomínio Financeiro e Pagamentos

CREATE TABLE pagamentos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id UUID REFERENCES pedidos(id) ON DELETE CASCADE,
    forma_pagamento TEXT NOT NULL CHECK (forma_pagamento IN ('PIX', 'DINHEIRO', 'CARTAO', 'OUTROS')),
    valor DECIMAL(10,2) NOT NULL,
    status_financeiro TEXT NOT NULL DEFAULT 'CONCLUIDO',
    provedor_pagamento TEXT,           -- Ex: 'MERCADO_PAGO'
    external_transaction_id TEXT,      -- Ex: 'tx_789'
    registrado_em TIMESTAMPTZ DEFAULT NOW(),
    -- Idempotência Financeira
    UNIQUE(provedor_pagamento, external_transaction_id)
);
