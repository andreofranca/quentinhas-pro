-- Migration 004: Auditoria de Operações Críticas

CREATE TABLE auditoria_operacoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES auth.users(id) ON DELETE RESTRICT, -- Quem fez
    operacao TEXT NOT NULL,                                       -- Ex: 'CANCELAMENTO_PEDIDO', 'AJUSTE_ESTOQUE'
    entidade_tipo TEXT NOT NULL,                                  -- Ex: 'pedidos', 'movimentacoes_estoque'
    entidade_id UUID NOT NULL,                                    -- Qual registro foi afetado
    motivo TEXT,                                                  -- Justificativa do operador
    estado_anterior JSONB,                                        -- Payload de como era
    estado_novo JSONB,                                            -- Payload de como ficou
    registrado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_auditoria_entidade ON auditoria_operacoes(entidade_tipo, entidade_id);
CREATE INDEX idx_auditoria_usuario ON auditoria_operacoes(usuario_id);
