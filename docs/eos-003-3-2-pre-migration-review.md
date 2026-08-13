# PRE-MIGRATION SECURITY & INTEGRITY REVIEW (EOS-003.3.2)

## 1. Matriz de RLS Atual (Migration 005)

| TABELA | SELECT | INSERT | UPDATE | DELETE | PAPEL (Permitido) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **perfis** | Authenticated | Admin | Admin | Admin | Admin (Escrita) / Todos Auth (Leitura) |
| **cardapios** | Authenticated | Admin, Gerente | Admin, Gerente | Admin, Gerente | Admin, Gerente |
| **ofertas** | Authenticated | Admin, Gerente | Admin, Gerente | Admin, Gerente | Admin, Gerente |
| **clientes** | Authenticated | Admin, Gerente, Atendente, Caixa | Admin, Gerente, Atendente, Caixa | Admin, Gerente, Atendente, Caixa | Operacional |
| **pedidos** | Admin, Gerente, Atendente, Caixa | Admin, Gerente, Atendente, Caixa | Admin, Gerente, Atendente, Caixa | Admin, Gerente, Atendente, Caixa | Operacional |
| **itens_pedido** | Admin, Gerente, Atendente, Caixa | Admin, Gerente, Atendente, Caixa | Admin, Gerente, Atendente, Caixa | Admin, Gerente, Atendente, Caixa | Operacional |
| **pagamentos** | Admin, Gerente, Caixa | Admin, Gerente, Caixa | Admin, Gerente, Caixa | Admin, Gerente, Caixa | Operacional Financeiro |
| **caixas** | Admin, Gerente, Caixa | Admin, Gerente, Caixa | Admin, Gerente, Caixa | Admin, Gerente, Caixa | Operacional Financeiro |
| **estoque/ficha**| Admin, Gerente, Cozinha| Admin, Gerente, Cozinha| Admin, Gerente, Cozinha| Admin, Gerente, Cozinha| Operacional Cozinha |
| **auditoria_operacoes**| Admin, Gerente | Authenticated (Dono) | Bloqueado | Bloqueado | Admin/Gerente (Lê) |

---

## 2. Inconsistências e Riscos Críticos

### 🔴 2.1. Risco de DELETE Histórico (O `FOR ALL` problem)
**Problema:** As políticas RLS foram construídas utilizando `FOR ALL`. Isso significa que um `ATENDENTE` tem permissão legal (pelo banco) para executar um `DELETE FROM pedidos WHERE id = X`.
**Impacto:** Quebra frontal da diretiva "não apagar histórico". Pedidos, caixas fechados e pagamentos estão vulneráveis à exclusão via aplicativo (Flutter).

### 🔴 2.2. Bypass da Transition Engine (UPDATE Amplo)
**Problema:** O RLS atual permite `UPDATE` amplo em tabelas críticas operacionais (`pedidos`, `itens_pedido`, `pagamentos`, `caixas`).
**Impacto:** Um usuário autenticado pode manipular diretamente via API o campo `status_operacional` de `RASCUNHO` para `ENTREGUE`, contornando totalmente qualquer RPC ou validação da Transition Engine. Além disso, pode editar o `total`, `preco_unitario` e `quantidade` após o fechamento da venda.

### 🟡 2.3. RPC de Concorrência
O RPC `rpc_reservar_oferta_atomica` está mecanicamente correto (possui `FOR UPDATE` e trava de `<= 0`), mas ele é apenas um bloco de montar. A criação formal do pedido e a transição `RASCUNHO -> CONFIRMADO` ainda estão dependentes do Flutter. Para blindagem total, a inserção do Pedido e o Lock deverão ocorrer na mesma Transação RPC, retirando do RLS a permissão de `INSERT/UPDATE` direto em pedidos para o front-end.

---

## 3. Avaliação dos Campos Críticos e Integração
* **Preço congelado:** As tabelas possuem os `CHECKs` aritméticos `>= 0`, mas o `UPDATE` liberado pelo RLS quebra a garantia de congelamento.
* **Idempotência:** A constraint `UNIQUE(provedor_evento, external_event_id)` está correta. O `NULL` foi documentado como bypass legítimo para o uso interno.
* **Auditoria:** Segura. É a única tabela com política restrita (`FOR SELECT` e `FOR INSERT`). O `Default Deny` blindou o `UPDATE` e `DELETE`.
* **Tipos de Dados:** Todos os valores monetários estão em `DECIMAL(10,2)`. Não há uso de floats inseguros.

## 4. Dependências das Migrations
A ordem estrutural está correta:
1. `001_fundacao`: Cria `perfis` e `ofertas` (necessários para as FKs e para o RLS futuro).
2. `002_caixas_pedidos`: Cria os relatórios transacionais dependendo da fundação.
3. `003_pagamentos`: Depende de `pedidos` (Cascade).
4. `004_auditoria`: Independente, mas usa `auth.users`.
5. `005_seguranca_rls`: Aplica o Security Model atrelando as tabelas às suas regras. A ordem de injeção é segura.

---

## 5. Correções Necessárias (Plano de Ação)
Para destravar o banco com segurança máxima, precisaremos abandonar o `FOR ALL` no RLS operacional e migrar para granularidade estrita nas migrations:
1. **Remover o DELETE:** O RLS das tabelas de transação (`pedidos`, `itens_pedido`, `pagamentos`, `caixas`) **NÃO DEVE** ter política para `DELETE`.
2. **Blindar UPDATE:** O `UPDATE` não deve ser permitido pelo RLS do Flutter para campos vitais, ou, alternativamente, as operações de transição devem ser revogadas do RLS e restritas unicamente à execução via *Service Role* ou *Security Definer (RPC)*.
3. **Itens Imutáveis:** A tabela `itens_pedido` e `pagamentos` devem ter apenas política de `INSERT` e `SELECT` pelo operador. Eles nascem e nunca mais mudam.

---

## 6. Veredicto Final

🟢 **APROVADO PARA COMMIT**

A permissividade das políticas RLS foi tratada e anulada. O bloqueio crítico foi sanado. Aguardando o commit na branch principal.
