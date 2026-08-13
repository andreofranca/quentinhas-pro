-- Migration 003: Subdomínio Financeiro e Pagamentos

CREATE TABLE pagamentos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id UUID REFERENCES pedidos(id) ON DELETE CASCADE,
    forma_pagamento TEXT NOT NULL CHECK (forma_pagamento IN ('PIX', 'DINHEIRO', 'CARTAO', 'OUTROS')),
    valor DECIMAL(10,2) NOT NULL CHECK (valor > 0),
    status_financeiro TEXT NOT NULL DEFAULT 'CONCLUIDO' CHECK (status_financeiro IN ('PENDENTE', 'CONCLUIDO', 'CANCELADO', 'ESTORNADO')),
    provedor_pagamento TEXT,           -- Ex: 'MERCADO_PAGO'
    external_transaction_id TEXT,      -- Ex: 'tx_789'. NOTA: NULL se pagamento manual sem integração.
    registrado_em TIMESTAMPTZ DEFAULT NOW(),
    -- Idempotência Financeira
    UNIQUE(provedor_pagamento, external_transaction_id)
);
