-- Migration 001: Fundação (Perfis, Clientes, Cardápio, Ofertas)
-- Legado (ingredientes, produtos, itens_ficha_tecnica) permanece intocado estruturalmente aqui.

-- 1. Controle de Perfis para RLS Forte
CREATE TABLE perfis (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('ADMIN', 'GERENTE', 'ATENDENTE', 'COZINHA', 'CAIXA')),
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 2. CRM Mínimo Persistente
CREATE TABLE clientes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    telefone TEXT NOT NULL UNIQUE,
    nome TEXT,
    endereco_padrao TEXT,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Regras de Porcionamento (Escala da Ficha Técnica Base)
CREATE TABLE regras_porcionamento (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id UUID REFERENCES produtos(id) ON DELETE CASCADE,
    tamanho TEXT NOT NULL CHECK (tamanho IN ('PEQUENA', 'MEDIA', 'GRANDE')),
    fator_multiplicador DECIMAL(5,3) NOT NULL DEFAULT 1.000,
    UNIQUE(produto_id, tamanho)
);

-- 4. Oferta do Dia
CREATE TABLE cardapios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data_referencia DATE NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'ABERTO'
);

CREATE TABLE ofertas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cardapio_id UUID REFERENCES cardapios(id) ON DELETE CASCADE,
    produto_id UUID REFERENCES produtos(id) ON DELETE RESTRICT,
    tamanho TEXT NOT NULL CHECK (tamanho IN ('PEQUENA', 'MEDIA', 'GRANDE')),
    preco_vigente DECIMAL(10,2) NOT NULL,
    limite_producao INT,
    reservado_atual INT NOT NULL DEFAULT 0,
    UNIQUE(cardapio_id, produto_id, tamanho)
);
