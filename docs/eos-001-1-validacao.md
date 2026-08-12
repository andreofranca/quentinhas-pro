# Validação da Baseline (EOS-001.1)

Em conformidade com a nova diretriz ("Não projetar contra suposições"), realizei a escavação dos metadados e da estruturação do código atual, mapeando campo a campo.

## 1. Modelo Atual Real (Supabase)
As únicas tabelas que *realmente existem* e persistem dados na aplicação atualmente são as 4 abaixo:

### Tabela `ingredientes`
- **PK:** `id` (UUID)
- **Colunas:** `nome` (TEXT), `unidade_medida` (TEXT), `estoque_atual` (DECIMAL), `estoque_minimo` (DECIMAL), `custo_unitario` (DECIMAL), `criado_em` (TIMESTAMP).
- **FKs:** Nenhuma.
- **Constraints/Índices:** Não definidos explicitamente (além da PK).
- **RLS / Policies:** Habilitado. Possui a política `"Permitir tudo para testes em ingredientes"` com `USING (true) WITH CHECK (true)`.

### Tabela `produtos`
- **PK:** `id` (UUID)
- **Colunas:** `nome` (TEXT), `preco_venda` (DECIMAL), `categoria` (TEXT), `criado_em` (TIMESTAMP).
- **FKs:** Nenhuma.
- **RLS / Policies:** Habilitado. Política `"Permitir tudo para testes em produtos"` com `USING (true) WITH CHECK (true)`.

### Tabela `itens_ficha_tecnica`
- **PK:** Composta por (`produto_id`, `ingrediente_id`)
- **Colunas:** `quantidade_utilizada` (DECIMAL).
- **FKs:** 
  - `produto_id` referencia `produtos(id)` ON DELETE CASCADE
  - `ingrediente_id` referencia `ingredientes(id)` ON DELETE RESTRICT
- **RLS / Policies:** Habilitado. Política com `USING (true) WITH CHECK (true)`.

### Tabela `movimentacoes_estoque`
- **PK:** `id` (UUID)
- **Colunas:** `ingrediente_nome` (TEXT), `tipo_movimentacao` (TEXT), `quantidade_movimentada` (DECIMAL), `estoque_anterior` (DECIMAL), `estoque_atual` (DECIMAL), `observacao` (TEXT), `registrado_em` (TIMESTAMP).
- **FKs:** `ingrediente_id` referencia `ingredientes(id)` ON DELETE RESTRICT
- **RLS / Policies:** Habilitado. Política com `USING (true) WITH CHECK (true)`.

---

## 2. Modelo Flutter (`main.dart`)
O arquivo `main.dart` possui 166KB e é um monolito maciço. Extraí as estruturas lógicas dele:

- **Entidades Mockadas (Classes Locais):** 
  - `Usuario`
  - `Pedido`
  - `ItemCarrinho`
  - `RegistroDiferencaCaixa`
  - `ResultadoNotificacaoWhatsApp`
- **Estados/Memória:** Existem listas globais gerenciando dados efêmeros, como `listaUsuarios` e prováveis listas para `aguardandoPagamento`, `opAtivas`, `concluidos`.
- **Serviços/Roteiros (Telas):** `PainelTesteCompleto`, `TelaCardapioCliente`, `TelaCheckoutExpresso`, `TelaLogin`, `TelaDashboard`, `TelaRelatoriosFinanceiros`, `TelaControleEstoqueRapido`, `TelaGestaoEquipe`, `TelaGestaoPedidos`, `TelaGestaoProdutos`.
- **Validações e Permissões:**
  - `_tentarLogin()`: Testa contra a lista em memória.
  - `_solicitarAutorizacaoGerente()`: Requer cargo 'ADMIN' dentro da lista local.
- **Transições:** `_adicionarAoCarrinho()`, `_finalizarPedido()`, `_executarFechamento()`.

> **Conclusão:** Todo o módulo de vendas, caixa, clientes e atendimento foi construído exclusivamente na camada visual (UI) e estado local (Dart).

---

## 3. Matriz de Verdade

| Funcionalidade | UI | Memória | Supabase | Regra Identificada (No Código) | Situação |
| :--- | :---: | :---: | :---: | :--- | :--- |
| **Login** | ✅ | ✅ | ❌ | `_tentarLogin` testa contra array | Substituir |
| **Usuários** | ✅ | ✅ | ❌ | Mock em `Usuario` e `listaUsuarios` | Substituir |
| **Produtos** | ✅ | ✅ | ✅ | Salvo em tabela `produtos` | Adaptar |
| **Ingredientes** | ❌ | ❌ | ✅ | Base sólida em tabela | Reutilizar |
| **Ficha Técnica** | ❌ | ❌ | ✅ | Tabela com restrição `RESTRICT` | Reutilizar |
| **Estoque** | ✅ | ❌ | ✅ | Lê/Grava no BD | Reutilizar |
| **Vendas/Pedidos** | ✅ | ✅ | ❌ | `Pedido` e `ItemCarrinho` no Dart | NOVO |
| **Caixa** | ✅ | ✅ | ❌ | `RegistroDiferencaCaixa` no Dart | NOVO |
| **Relatórios** | ✅ | ✅ | ❌ | Tela lê do estado em memória | NOVO |
| **Auditoria** | ❌ | ❌ | ✅ | Disparada pela tabela de estoque | Reutilizar |
| **WhatsApp** | ✅ | ❌ | ❌ | `_abrirConversaWhatsApp` (Launcher simples) | NOVO |

*(O símbolo ❌ em UI para Ingredientes/Ficha/Auditoria indica que não encontrei classes/telas específicas para isso, elas devem estar diluídas no `PainelTesteCompleto` ou `EstoqueRapido`).*
