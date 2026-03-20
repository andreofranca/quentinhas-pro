-- Schema inicial do sistema de lanchonete no Supabase
-- Observacao: politicas abaixo sao abertas e devem ser usadas apenas em desenvolvimento.

-- 1. Tabela de Ingredientes (materia-prima)
CREATE TABLE IF NOT EXISTS ingredientes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  unidade_medida TEXT NOT NULL,
  estoque_atual DECIMAL(10,3) DEFAULT 0,
  estoque_minimo DECIMAL(10,3) DEFAULT 0,
  custo_unitario DECIMAL(10,2) DEFAULT 0,
  criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Tabela de Produtos (itens do cardapio)
CREATE TABLE IF NOT EXISTS produtos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  preco_venda DECIMAL(10,2) NOT NULL DEFAULT 0,
  categoria TEXT,
  criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Tabela da ficha tecnica (ponte produto x ingrediente)
CREATE TABLE IF NOT EXISTS itens_ficha_tecnica (
  produto_id UUID REFERENCES produtos(id) ON DELETE CASCADE,
  ingrediente_id UUID REFERENCES ingredientes(id) ON DELETE RESTRICT,
  quantidade_utilizada DECIMAL(10,3) NOT NULL,
  PRIMARY KEY (produto_id, ingrediente_id)
);

-- 4. Tabela de movimentacoes de estoque (auditoria de entradas/saidas)
CREATE TABLE IF NOT EXISTS movimentacoes_estoque (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ingrediente_id UUID REFERENCES ingredientes(id) ON DELETE RESTRICT,
  ingrediente_nome TEXT NOT NULL,
  tipo_movimentacao TEXT NOT NULL,
  quantidade_movimentada DECIMAL(10,3) NOT NULL,
  estoque_anterior DECIMAL(10,3) NOT NULL,
  estoque_atual DECIMAL(10,3) NOT NULL,
  observacao TEXT DEFAULT '',
  registrado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitacao de RLS
ALTER TABLE ingredientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE itens_ficha_tecnica ENABLE ROW LEVEL SECURITY;
ALTER TABLE movimentacoes_estoque ENABLE ROW LEVEL SECURITY;

-- Politicas abertas para fase de desenvolvimento
DROP POLICY IF EXISTS "Permitir tudo para testes em ingredientes" ON ingredientes;
CREATE POLICY "Permitir tudo para testes em ingredientes"
  ON ingredientes FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir tudo para testes em produtos" ON produtos;
CREATE POLICY "Permitir tudo para testes em produtos"
  ON produtos FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir tudo para testes em ficha_tecnica" ON itens_ficha_tecnica;
CREATE POLICY "Permitir tudo para testes em ficha_tecnica"
  ON itens_ficha_tecnica FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir tudo para testes em movimentacoes_estoque" ON movimentacoes_estoque;
CREATE POLICY "Permitir tudo para testes em movimentacoes_estoque"
  ON movimentacoes_estoque FOR ALL USING (true) WITH CHECK (true);
