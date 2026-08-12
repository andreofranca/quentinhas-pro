# Revisão de Modelo e DDL Preview (EOS-003.1)

Em conformidade com a determinação da Tríade de não executar código no Supabase antes da prova formal, este documento contém o mapeamento analítico estrutural e o código DDL gerado para revisão Sênior.

## 1. Mapa de Migração Incremental

| Tabela Existente / Nova | Situação | Ação DDL |
| :--- | :--- | :--- |
| `ingredientes` | **Preservada** | `ALTER TABLE` (Dropar policy antiga, criar nova RLS Auth) |
| `produtos` | **Preservada** | `ALTER TABLE` (Dropar policy antiga, criar nova RLS Auth) |
| `itens_ficha_tecnica` | **Preservada** | `ALTER TABLE` (Dropar policy antiga, criar nova RLS Auth) |
| `movimentacoes_estoque` | **Preservada** | `ALTER TABLE` (Dropar policy antiga, criar nova RLS Auth) |
| `regras_porcionamento` | **Nova** | `CREATE TABLE` |
| `clientes` | **Nova** | `CREATE TABLE` |
| `cardapios` | **Nova** | `CREATE TABLE` |
| `ofertas` | **Nova** | `CREATE TABLE` |
| `caixas` | **Nova** | `CREATE TABLE` |
| `pedidos` | **Nova** | `CREATE TABLE` |
| `itens_pedido` | **Nova** | `CREATE TABLE` |
| `pagamentos` | **Nova** | `CREATE TABLE` |

---

## 2. Dicionário de Tabelas (Validação Técnica)

### `regras_porcionamento`
* **Finalidade:** Definir como a Ficha Técnica Base escala (fator multiplicador) para diferentes Tamanhos.
* **PK:** `id` (UUID)
* **FKs:** `produto_id` (-> produtos) ON DELETE CASCADE
* **Campos:** `tamanho` (TEXT), `fator_multiplicador` (DECIMAL(5,3) - precisão de 3 casas para suportar 0.333, etc).
* **Constraints:** `UNIQUE(produto_id, tamanho)` - um único fator por tamanho/prato.
* **Índices:** Não exige índices extras (tabela pequena, index na FK gerado nativamente se necessário).
* **RLS:** Acesso de Leitura/Escrita apenas para roles operacionais (Ex: ADMIN, GERENTE).

### `clientes`
* **Finalidade:** Armazenar dados persistentes mínimos para CRM e roteamento de WhatsApp.
* **PK:** `id` (UUID)
* **Campos:** `telefone` (TEXT), `nome` (TEXT), `endereco_padrao` (TEXT)
* **Constraints:** `UNIQUE(telefone)`
* **RLS:** Atendentes e Admin.

### `caixas`
* **Finalidade:** Sessão de responsabilidade financeira do operador.
* **PK:** `id` (UUID)
* **FKs:** `operador_id` (-> auth.users)
* **Campos:** `aberto_em` (TIMESTAMPTZ), `fechado_em` (TIMESTAMPTZ), `status` (TEXT: ABERTO, FECHADO), `saldo_inicial` (DECIMAL), `saldo_informado` (DECIMAL)
* **Constraints:** Validação de Integridade via RPC para garantir que um Operador só tenha 1 Caixa `ABERTO`. 
* **RLS:** Acesso pelo Operador dono e Admin.

### `cardapios`
* **Finalidade:** Agrupar as ofertas do dia.
* **PK:** `id` (UUID)
* **Campos:** `data_referencia` (DATE), `status` (TEXT: ABERTO, FECHADO)
* **Constraints:** `UNIQUE(data_referencia)` - Apenas um cardápio por dia.

### `ofertas`
* **Finalidade:** O "Prato do Dia". A intersecção entre Produto, Tamanho, Preço e Limite.
* **PK:** `id` (UUID)
* **FKs:** `cardapio_id` (-> cardapios) ON DELETE CASCADE, `produto_id` (-> produtos) ON DELETE RESTRICT
* **Campos:** `tamanho` (TEXT), `preco_vigente` (DECIMAL(10,2)), `limite_producao` (INT), `reservado_atual` (INT)
* **Constraints:** `UNIQUE(cardapio_id, produto_id, tamanho)`.

### `pedidos`
* **Finalidade:** A Transition Engine do sistema operacional. O "dono" do ciclo de vida da venda.
* **PK:** `id` (UUID)
* **FKs:** `cliente_id` (-> clientes) RESTRICT, `caixa_id` (-> caixas) RESTRICT
* **Campos:** `status_operacional` (TEXT), `status_financeiro` (TEXT), `modalidade` (TEXT), `total` (DECIMAL(10,2)), `endereco_entrega` (TEXT), `provedor_evento` (TEXT), `external_event_id` (TEXT).
* **Constraints:** `UNIQUE(provedor_evento, external_event_id)` -> Ex: ('WHATSAPP', 'msg-123'). Garante idempotência multi-provider.
* **Índices:** `idx_pedidos_caixa` (fechamento), `idx_pedidos_status` (Painel).

### `itens_pedido`
* **Finalidade:** Contexto comercial imutável (Tamanho, Preço e Prato).
* **PK:** `id` (UUID)
* **FKs:** `pedido_id` (-> pedidos) CASCADE, `oferta_id` (-> ofertas) RESTRICT.
* **Campos:** `quantidade` (INT), `preco_unitario` (DECIMAL(10,2)), `subtotal` (DECIMAL(10,2)).
* **Índices:** `idx_itens_pedido_oferta` para agilizar relatórios (Prato × Tamanho).

### `pagamentos`
* **Finalidade:** Subdomínio financeiro separado do logístico.
* **PK:** `id` (UUID)
* **FKs:** `pedido_id` (-> pedidos) CASCADE
* **Campos:** `forma_pagamento` (TEXT), `valor` (DECIMAL(10,2)), `status_financeiro` (TEXT), `provedor_pagamento` (TEXT), `external_transaction_id` (TEXT).
* **Constraints:** `UNIQUE(provedor_pagamento, external_transaction_id)`.

---

## 3. DDL Preview (SQL Lógico - NÃO EXECUTADO)

```sql
-- DDL PREVIEW: Criação e Migração do Domínio Comida Caseira

-- 1. Drop de Políticas Abertas (Legado)
DROP POLICY IF EXISTS "Permitir tudo para testes em ingredientes" ON ingredientes;
DROP POLICY IF EXISTS "Permitir tudo para testes em produtos" ON produtos;
DROP POLICY IF EXISTS "Permitir tudo para testes em ficha_tecnica" ON itens_ficha_tecnica;
DROP POLICY IF EXISTS "Permitir tudo para testes em movimentacoes_estoque" ON movimentacoes_estoque;

-- 2. Novas Tabelas

CREATE TABLE clientes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    telefone TEXT NOT NULL UNIQUE,
    nome TEXT,
    endereco_padrao TEXT,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE caixas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    operador_id UUID NOT NULL, -- references auth.users
    aberto_em TIMESTAMPTZ DEFAULT NOW(),
    fechado_em TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'ABERTO',
    saldo_inicial DECIMAL(10,2) DEFAULT 0,
    saldo_informado DECIMAL(10,2)
);
CREATE UNIQUE INDEX idx_caixa_unico_aberto ON caixas(operador_id) WHERE status = 'ABERTO'; -- Evita 2 caixas abertos pelo mesmo operador

CREATE TABLE regras_porcionamento (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    produto_id UUID REFERENCES produtos(id) ON DELETE CASCADE,
    tamanho TEXT NOT NULL,
    fator_multiplicador DECIMAL(5,3) NOT NULL DEFAULT 1.000,
    UNIQUE(produto_id, tamanho)
);

CREATE TABLE cardapios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data_referencia DATE NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'ABERTO'
);

CREATE TABLE ofertas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cardapio_id UUID REFERENCES cardapios(id) ON DELETE CASCADE,
    produto_id UUID REFERENCES produtos(id) ON DELETE RESTRICT,
    tamanho TEXT NOT NULL,
    preco_vigente DECIMAL(10,2) NOT NULL,
    limite_producao INT,
    reservado_atual INT NOT NULL DEFAULT 0,
    UNIQUE(cardapio_id, produto_id, tamanho)
);

CREATE TABLE pedidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cliente_id UUID REFERENCES clientes(id) ON DELETE RESTRICT,
    caixa_id UUID REFERENCES caixas(id) ON DELETE RESTRICT,
    total DECIMAL(10,2) NOT NULL DEFAULT 0,
    status_operacional TEXT NOT NULL DEFAULT 'RASCUNHO',
    status_financeiro TEXT NOT NULL DEFAULT 'PENDENTE',
    modalidade TEXT NOT NULL,
    endereco_entrega TEXT,
    provedor_evento TEXT,
    external_event_id TEXT,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(provedor_evento, external_event_id)
);

CREATE TABLE itens_pedido (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id UUID REFERENCES pedidos(id) ON DELETE CASCADE,
    oferta_id UUID REFERENCES ofertas(id) ON DELETE RESTRICT,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL
);

CREATE TABLE pagamentos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id UUID REFERENCES pedidos(id) ON DELETE CASCADE,
    forma_pagamento TEXT NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    status_financeiro TEXT NOT NULL DEFAULT 'CONCLUIDO',
    provedor_pagamento TEXT,
    external_transaction_id TEXT,
    UNIQUE(provedor_pagamento, external_transaction_id)
);

-- 3. Habilitação de RLS e Security
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE caixas ENABLE ROW LEVEL SECURITY;
ALTER TABLE regras_porcionamento ENABLE ROW LEVEL SECURITY;
ALTER TABLE cardapios ENABLE ROW LEVEL SECURITY;
ALTER TABLE ofertas ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE itens_pedido ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagamentos ENABLE ROW LEVEL SECURITY;

-- 4. Exemplo de Policy baseada em RBAC (Contexto de Autorização e não só Authentication)
-- (No MVP real, criaremos policies filtrando pelo perfil do auth.jwt())
CREATE POLICY "Acesso Interno Loja" ON pedidos
FOR ALL USING (auth.role() = 'authenticated'); 
```

## 4. Concorrência e Domain Operations
Para não poluir o arquivo DDL, destaco que operações como `confirmar_pedido(draft_id)` serão materializadas como **Stored Procedures (RPC)** em `PL/pgSQL`. 
O `WhatsApp Webhook (Edge Function)` chamará a API RPC usando uma *Service Role Key*, passando os dados do Draft. A RPC, rodando *dentro do banco*, fará o `SELECT ... FOR UPDATE` na tabela `ofertas`, validará o limite, gravará o `pedido` e `itens_pedido`, e fará o `COMMIT`. A Service Role servirá apenas de ponte autenticada e não como permissão irrestrita.

## 5. Risco Analisado no Preview
- **Risco de Orfandade de Histórico:** O comando `ON DELETE RESTRICT` foi usado intencionalmente nas conexões ao Pedido (`cliente_id`, `caixa_id`, `oferta_id`). Isso impede deleções acidentais que destruiriam a validade do caixa.
- **Risco de Lock Escalation:** Como a reserva atualiza a linha da Oferta, se muitos usuários comprarem *A MESMA OFERTA* no mesmo segundo, haverá enfileiramento (Lock Contention). Para o tráfego de uma lanchonete, isso gerará esperas na casa dos milissegundos (invisível ao cliente) e não é um risco material de queda de banco, mas garante 100% de precisão de inventário.
