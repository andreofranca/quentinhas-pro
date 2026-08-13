-- Migration 005: RLS Forte, Dropping Legado e RPC

-- 1. Dropar vulnerabilidades antigas
DROP POLICY IF EXISTS "Permitir tudo para testes em ingredientes" ON ingredientes;
DROP POLICY IF EXISTS "Permitir tudo para testes em produtos" ON produtos;
DROP POLICY IF EXISTS "Permitir tudo para testes em ficha_tecnica" ON itens_ficha_tecnica;
DROP POLICY IF EXISTS "Permitir tudo para testes em movimentacoes_estoque" ON movimentacoes_estoque;

-- 2. Habilitar RLS em tudo
ALTER TABLE ingredientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE itens_ficha_tecnica ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimentacoes_estoque ENABLE ROW LEVEL SECURITY;
ALTER TABLE perfis ENABLE ROW LEVEL SECURITY;
ALTER TABLE regras_porcionamento ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE cardapios ENABLE ROW LEVEL SECURITY;
ALTER TABLE ofertas ENABLE ROW LEVEL SECURITY;
ALTER TABLE caixas ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE itens_pedido ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE auditoria_operacoes ENABLE ROW LEVEL SECURITY;

-- 3. Criar Políticas Baseadas em Perfil (Identity / Authorization)

-- Políticas de Leitura Global para Autenticados (Evita recursão no perfil)
CREATE POLICY "Leitura Publica Perfis" ON perfis FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Leitura Publica Cardapios" ON cardapios FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Leitura Publica Ofertas" ON ofertas FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Leitura Publica Clientes" ON clientes FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Leitura Publica Produtos" ON produtos FOR SELECT USING (auth.role() = 'authenticated');

-- Gestao de Cardapios e Ofertas (INSERT/UPDATE/DELETE por ADMIN/GERENTE)
CREATE POLICY "Gestao Escrita Cardapios" ON cardapios FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE')));
CREATE POLICY "Gestao Atualizacao Cardapios" ON cardapios FOR UPDATE USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE')));
CREATE POLICY "Gestao Exclusao Cardapios" ON cardapios FOR DELETE USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE')));

CREATE POLICY "Gestao Escrita Ofertas" ON ofertas FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE')));
CREATE POLICY "Gestao Atualizacao Ofertas" ON ofertas FOR UPDATE USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE')));
CREATE POLICY "Gestao Exclusao Ofertas" ON ofertas FOR DELETE USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE')));

CREATE POLICY "Gestao Escrita Produtos" ON produtos FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE')));
CREATE POLICY "Gestao Atualizacao Produtos" ON produtos FOR UPDATE USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE')));
CREATE POLICY "Gestao Exclusao Produtos" ON produtos FOR DELETE USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE')));

CREATE POLICY "Leitura Regras Porcionamento" ON regras_porcionamento FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Escrita Regras Porcionamento" ON regras_porcionamento FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE')));
CREATE POLICY "Atualizacao Regras Porcionamento" ON regras_porcionamento FOR UPDATE USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE')));
CREATE POLICY "Exclusao Regras Porcionamento" ON regras_porcionamento FOR DELETE USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE')));

-- Operacao Pedidos (Transition Engine Protection)
-- SELECT: Todos os operadores
CREATE POLICY "Leitura Pedidos" ON pedidos FOR SELECT USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE', 'ATENDENTE', 'CAIXA')));
-- INSERT: Operadores
CREATE POLICY "Criacao Pedidos" ON pedidos FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE', 'ATENDENTE', 'CAIXA')));
-- UPDATE: Bloqueado por default via RLS (Default Deny). Toda mutação de estado será via RPC/Transition Engine.
-- DELETE: Bloqueado. Histórico não se apaga.

-- Operacao Itens Pedido (Imutáveis após confirmação)
CREATE POLICY "Leitura Itens Pedido" ON itens_pedido FOR SELECT USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE', 'ATENDENTE', 'CAIXA')));
CREATE POLICY "Criacao Itens Pedido" ON itens_pedido FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE', 'ATENDENTE', 'CAIXA')));
-- UPDATE / DELETE: Bloqueados (Default Deny)

-- Operacao Clientes (CRM Base)
CREATE POLICY "Criacao Clientes" ON clientes FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE', 'ATENDENTE', 'CAIXA')));
CREATE POLICY "Atualizacao Clientes" ON clientes FOR UPDATE USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE', 'ATENDENTE', 'CAIXA')));
CREATE POLICY "Exclusao Clientes" ON clientes FOR DELETE USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role = 'ADMIN'));

-- Pagamentos (Trilha Financeira)
CREATE POLICY "Leitura Pagamentos" ON pagamentos FOR SELECT USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE', 'CAIXA')));
CREATE POLICY "Criacao Pagamentos" ON pagamentos FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE', 'CAIXA')));
-- UPDATE / DELETE: Bloqueados para garantir integridade fiscal.

-- Caixas
CREATE POLICY "Leitura Caixas" ON caixas FOR SELECT USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE', 'CAIXA')));
CREATE POLICY "Criacao Caixas" ON caixas FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE', 'CAIXA')));
CREATE POLICY "Atualizacao Caixas" ON caixas FOR UPDATE USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE', 'CAIXA')));
-- DELETE: Bloqueado. Histórico financeiro intocável.

-- Estoque e Fichas
CREATE POLICY "Leitura Estoque" ON ingredientes FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Escrita Estoque" ON ingredientes FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE', 'COZINHA')));
CREATE POLICY "Atualizacao Estoque" ON ingredientes FOR UPDATE USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE', 'COZINHA')));
CREATE POLICY "Exclusao Estoque" ON ingredientes FOR DELETE USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE')));

CREATE POLICY "Leitura Fichas" ON itens_ficha_tecnica FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Escrita Fichas" ON itens_ficha_tecnica FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE', 'COZINHA')));
CREATE POLICY "Atualizacao Fichas" ON itens_ficha_tecnica FOR UPDATE USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE', 'COZINHA')));
CREATE POLICY "Exclusao Fichas" ON itens_ficha_tecnica FOR DELETE USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE')));

CREATE POLICY "Leitura Movimentacoes" ON movimentacoes_estoque FOR SELECT USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE', 'COZINHA', 'CAIXA')));
CREATE POLICY "Criacao Movimentacoes" ON movimentacoes_estoque FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE', 'COZINHA')));
-- UPDATE / DELETE Movimentacoes: Bloqueados (Append-Only)

-- Auditoria (Append-Only rigoroso)
CREATE POLICY "Leitura Auditoria" ON auditoria_operacoes FOR SELECT USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE')));
CREATE POLICY "Escrita Auditoria" ON auditoria_operacoes FOR INSERT WITH CHECK (auth.uid() = usuario_id);
-- UPDATE / DELETE: Bloqueados implicitamente (Default Deny)

-- Perfis
CREATE POLICY "Escrita Perfis Admin" ON perfis FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role = 'ADMIN'));
CREATE POLICY "Atualizacao Perfis Admin" ON perfis FOR UPDATE USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role = 'ADMIN'));
CREATE POLICY "Exclusao Perfis Admin" ON perfis FOR DELETE USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role = 'ADMIN'));

-- Importante: A Service Role do Backend ignora o RLS naturalmente.

-- 4. Função RPC Esqueleto para Lock Atômico
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
    -- Validação vital contra burla de quantidade
    IF p_quantidade <= 0 THEN
        RETURN FALSE;
    END IF;

    -- Row-Level Lock na Oferta
    SELECT limite_producao, reservado_atual 
    INTO v_limite, v_reservado 
    FROM ofertas 
    WHERE id = p_oferta_id 
    FOR UPDATE;

    -- Se tem limite e a reserva estoura o limite, aborta.
    IF v_limite IS NOT NULL AND (v_reservado + p_quantidade > v_limite) THEN
        RETURN FALSE;
    END IF;

    -- Efetua a reserva
    UPDATE ofertas 
    SET reservado_atual = reservado_atual + p_quantidade 
    WHERE id = p_oferta_id;

    RETURN TRUE;
END;
$$;
