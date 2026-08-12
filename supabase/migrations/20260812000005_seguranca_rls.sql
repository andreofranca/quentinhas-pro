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
-- Exemplo: Acesso Administrativo Completo
CREATE POLICY "Acesso Admin Total" ON ingredientes FOR ALL 
USING (EXISTS (SELECT 1 FROM perfis WHERE perfis.id = auth.uid() AND perfis.role IN ('ADMIN', 'GERENTE')));

-- (No futuro, serão expandidas policies granulares por perfil e entidade)
-- Importante: A Service Role do Backend ignora o RLS naturalmente.

-- 4. Função RPC Esqueleto para Lock Atômico
CREATE OR REPLACE FUNCTION rpc_reservar_oferta_atomica(
    p_oferta_id UUID,
    p_quantidade INT
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER -- Roda com privilégio do criador, permitindo que a Edge Function execute sem expor permissão direta de tabela
AS $$
DECLARE
    v_limite INT;
    v_reservado INT;
BEGIN
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
