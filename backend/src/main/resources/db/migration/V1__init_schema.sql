-- V1__init_schema.sql
-- Migração consolidada para PostgreSQL Nativo (Sem Supabase)

-- 1. Usuários e Autenticação (Substitui auth.users + perfis)
CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('ADMIN', 'GERENTE', 'ATENDENTE', 'COZINHA', 'CAIXA')),
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 2. CRM (Clientes)
CREATE TABLE clientes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    telefone TEXT NOT NULL UNIQUE,
    nome TEXT,
    endereco_padrao TEXT,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Estoque e Cardápio (Base legado incorporada e blindada)
CREATE TABLE ingredientes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL,
    unidade_medida TEXT NOT NULL,
    custo_unitario DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    estoque_atual DECIMAL(10,3) NOT NULL DEFAULT 0.0
);

CREATE TABLE produtos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL,
    descricao TEXT,
    categoria TEXT NOT NULL,
    preco_base DECIMAL(10,2) NOT NULL DEFAULT 0.0
);

CREATE TABLE itens_ficha_tecnica (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id UUID REFERENCES produtos(id) ON DELETE CASCADE,
    ingrediente_id UUID REFERENCES ingredientes(id) ON DELETE RESTRICT,
    quantidade DECIMAL(10,3) NOT NULL
);

CREATE TABLE regras_porcionamento (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id UUID REFERENCES produtos(id) ON DELETE CASCADE,
    tamanho TEXT NOT NULL CHECK (tamanho IN ('PEQUENA', 'MEDIA', 'GRANDE')),
    fator_multiplicador DECIMAL(5,3) NOT NULL DEFAULT 1.000,
    UNIQUE(produto_id, tamanho)
);

CREATE TABLE movimentacoes_estoque (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ingrediente_id UUID REFERENCES ingredientes(id) ON DELETE RESTRICT,
    tipo TEXT NOT NULL CHECK (tipo IN ('ENTRADA', 'SAIDA', 'PERDA')),
    quantidade DECIMAL(10,3) NOT NULL,
    registrado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Oferta do Dia
CREATE TABLE cardapios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data_referencia DATE NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'ABERTO' CHECK (status IN ('ABERTO', 'FECHADO', 'CANCELADO'))
);

CREATE TABLE ofertas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cardapio_id UUID REFERENCES cardapios(id) ON DELETE CASCADE,
    produto_id UUID REFERENCES produtos(id) ON DELETE RESTRICT,
    tamanho TEXT NOT NULL CHECK (tamanho IN ('PEQUENA', 'MEDIA', 'GRANDE')),
    preco_vigente DECIMAL(10,2) NOT NULL CHECK (preco_vigente >= 0),
    limite_producao INT CHECK (limite_producao >= 0),
    reservado_atual INT NOT NULL DEFAULT 0 CHECK (reservado_atual >= 0),
    UNIQUE(cardapio_id, produto_id, tamanho)
);

-- 5. Caixas
CREATE TABLE caixas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    operador_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    terminal_id TEXT NOT NULL DEFAULT 'CAIXA_BALCAO',
    aberto_em TIMESTAMPTZ DEFAULT NOW(),
    fechado_em TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'ABERTO' CHECK (status IN ('ABERTO', 'FECHADO')),
    saldo_inicial DECIMAL(10,2) DEFAULT 0 CHECK (saldo_inicial >= 0),
    saldo_informado DECIMAL(10,2) CHECK (saldo_informado >= 0)
);

CREATE UNIQUE INDEX idx_caixa_unico_aberto_terminal ON caixas(terminal_id) WHERE status = 'ABERTO';

-- 6. Pedidos (Núcleo Operacional)
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
    external_event_id TEXT,     -- Ex: 'msg_123'
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    -- Idempotência Forte
    UNIQUE(provedor_evento, external_event_id)
);

CREATE INDEX idx_pedidos_caixa ON pedidos(caixa_id);
CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);

CREATE TABLE itens_pedido (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id UUID REFERENCES pedidos(id) ON DELETE CASCADE,
    oferta_id UUID REFERENCES ofertas(id) ON DELETE RESTRICT,
    quantidade INT NOT NULL CHECK (quantidade > 0),
    preco_unitario DECIMAL(10,2) NOT NULL CHECK (preco_unitario >= 0),
    subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0)
);
CREATE INDEX idx_itens_pedido_oferta ON itens_pedido(oferta_id);

-- 7. Pagamentos (Trilha Financeira)
CREATE TABLE pagamentos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id UUID REFERENCES pedidos(id) ON DELETE CASCADE,
    forma_pagamento TEXT NOT NULL CHECK (forma_pagamento IN ('PIX', 'DINHEIRO', 'CARTAO', 'OUTROS')),
    valor DECIMAL(10,2) NOT NULL CHECK (valor > 0),
    valor_recebido DECIMAL(10,2) CHECK (valor_recebido >= valor),
    troco DECIMAL(10,2) CHECK (troco >= 0),
    status_financeiro TEXT NOT NULL DEFAULT 'CONCLUIDO' CHECK (status_financeiro IN ('PENDENTE', 'CONCLUIDO', 'CANCELADO', 'ESTORNADO')),
    provedor_pagamento TEXT,
    external_transaction_id TEXT,
    registrado_em TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(provedor_pagamento, external_transaction_id)
);

-- 8. Auditoria
CREATE TABLE auditoria_operacoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES usuarios(id) ON DELETE RESTRICT,
    operacao TEXT NOT NULL,
    entidade_tipo TEXT NOT NULL,
    entidade_id UUID NOT NULL,
    motivo TEXT,
    estado_anterior JSONB,
    estado_novo JSONB,
    registrado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_auditoria_entidade ON auditoria_operacoes(entidade_tipo, entidade_id);
CREATE INDEX idx_auditoria_usuario ON auditoria_operacoes(usuario_id);

-- 9. RPCs / Transition Engine
CREATE OR REPLACE FUNCTION rpc_reservar_oferta_atomica(
    p_oferta_id UUID,
    p_quantidade INT
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_limite INT;
    v_reservado INT;
BEGIN
    IF p_quantidade <= 0 THEN
        RETURN FALSE;
    END IF;

    -- Row-Level Lock
    SELECT limite_producao, reservado_atual 
    INTO v_limite, v_reservado 
    FROM ofertas 
    WHERE id = p_oferta_id 
    FOR UPDATE;

    IF v_limite IS NOT NULL AND (v_reservado + p_quantidade > v_limite) THEN
        RETURN FALSE;
    END IF;

    UPDATE ofertas 
    SET reservado_atual = reservado_atual + p_quantidade 
    WHERE id = p_oferta_id;

    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION rpc_processar_pedido(payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caixa_id UUID;
    v_cliente_id UUID;
    v_pedido_id UUID;
    v_item JSONB;
    v_limite INT;
    v_reservado INT;
    v_qtd INT;
    v_oferta_id UUID;
BEGIN
    -- 1. Validar Caixa Aberto
    v_caixa_id := (payload->>'caixa_id')::UUID;
    IF NOT EXISTS (SELECT 1 FROM caixas WHERE id = v_caixa_id AND status = 'ABERTO') THEN
        RAISE EXCEPTION 'Caixa % não está aberto.', v_caixa_id;
    END IF;

    -- 2. Upsert Cliente (por telefone)
    IF payload->'cliente' IS NOT NULL THEN
        INSERT INTO clientes (telefone, nome)
        VALUES (payload->'cliente'->>'telefone', payload->'cliente'->>'nome')
        ON CONFLICT (telefone) DO UPDATE SET nome = EXCLUDED.nome
        RETURNING id INTO v_cliente_id;
    END IF;

    -- 3. Pessimistic Lock & Baixa
    FOR v_item IN SELECT * FROM jsonb_array_elements(payload->'itens') ORDER BY (value->>'oferta_id')::UUID
    LOOP
        v_oferta_id := (v_item->>'oferta_id')::UUID;
        v_qtd := (v_item->>'quantidade')::INT;

        IF v_qtd <= 0 THEN
            RAISE EXCEPTION 'Quantidade inválida para oferta %', v_oferta_id;
        END IF;

        SELECT limite_producao, reservado_atual 
        INTO v_limite, v_reservado 
        FROM ofertas 
        WHERE id = v_oferta_id 
        FOR UPDATE;

        IF v_limite IS NOT NULL AND (v_reservado + v_qtd > v_limite) THEN
            RAISE EXCEPTION 'Estoque esgotado para a oferta %', v_oferta_id;
        END IF;

        UPDATE ofertas 
        SET reservado_atual = reservado_atual + v_qtd 
        WHERE id = v_oferta_id;
    END LOOP;

    -- 4. Criar Pedido
    INSERT INTO pedidos (
        caixa_id, cliente_id, total, modalidade, taxa_entrega, endereco_entrega, 
        observacoes, provedor_evento, external_event_id, status_operacional
    ) VALUES (
        v_caixa_id, 
        v_cliente_id, 
        (payload->>'total')::DECIMAL, 
        payload->>'modalidade', 
        COALESCE((payload->>'taxa_entrega')::DECIMAL, 0.00), 
        payload->>'endereco_entrega', 
        payload->>'observacoes', 
        payload->>'provedor_evento', 
        payload->>'external_event_id',
        'CONFIRMADO'
    ) RETURNING id INTO v_pedido_id;

    -- 5. Criar Itens do Pedido
    FOR v_item IN SELECT * FROM jsonb_array_elements(payload->'itens')
    LOOP
        INSERT INTO itens_pedido (
            pedido_id, oferta_id, quantidade, preco_unitario, subtotal
        ) VALUES (
            v_pedido_id, 
            (v_item->>'oferta_id')::UUID, 
            (v_item->>'quantidade')::INT, 
            (v_item->>'preco_unitario')::DECIMAL, 
            (v_item->>'subtotal')::DECIMAL
        );
    END LOOP;

    -- 6. Criar Pagamento
    IF payload->'pagamento' IS NOT NULL THEN
        INSERT INTO pagamentos (
            pedido_id, forma_pagamento, valor, valor_recebido, troco
        ) VALUES (
            v_pedido_id,
            payload->'pagamento'->>'forma_pagamento',
            (payload->'pagamento'->>'valor')::DECIMAL,
            (payload->'pagamento'->>'valor_recebido')::DECIMAL,
            (payload->'pagamento'->>'troco')::DECIMAL
        );
    END IF;

    RETURN jsonb_build_object('pedido_id', v_pedido_id, 'status', 'SUCCESS');
END;
$$;
