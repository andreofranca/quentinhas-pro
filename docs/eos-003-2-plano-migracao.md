# Plano de Migração e Testes (EOS-003.2)

Este documento atesta a sanidade do DDL planejado e formaliza a estratégia de execução segura. NENHUM SQL foi executado no banco.

## 1. Sequência das Migrations (DDL Fracionado)
Os arquivos foram gerados na pasta `supabase/migrations/` e devem ser executados via Supabase CLI (`supabase db push` ou `supabase migration up`) para garantir histórico irreversível no painel:
1. `20260812000001_fundacao.sql` (Perfis, Clientes, Regras, Ofertas)
2. `20260812000002_caixas_pedidos.sql` (Engine de Pedidos, Itens, Caixa por Terminal)
3. `20260812000003_pagamentos.sql` (Financeiro)
4. `20260812000004_auditoria.sql` (Log Imutável Crítico)
5. `20260812000005_seguranca_rls.sql` (Expurgo do RLS aberto, Autorização por Role, RPC de Atomic Lock)

## 2. Confirmação de Segurança do Legado
- **Nenhum comando DROP TABLE** foi utilizado.
- As tabelas `ingredientes`, `produtos`, `itens_ficha_tecnica` e `movimentacoes_estoque` são alvos puramente de `ALTER TABLE` para ativar a nova segurança RLS. Os dados atuais seguirão perfeitos.
- O histórico não será apagado, utilizamos status lógicos.

## 3. Plano de Rollback
O Supabase CLI permite criar scripts *down* para reversão. Se houver falha crítica durante as migrations, o plano de rollback imediato envolverá o comando `supabase db reset` (caso em ambiente local/staging) ou a execução de scripts em cascata reversa:
- Drop tables (na ordem inversa das FKs): `pagamentos`, `itens_pedido`, `pedidos`, `caixas`, `ofertas`, `cardapios`, `regras_porcionamento`, `clientes`, `perfis`, `auditoria_operacoes`.
- Recriação das vulnerabilidades antigas de RLS (apenas para recuperar o estado pré-migration).
- **Importante:** Em Produção, exige-se o dump do banco (`pg_dump`) antes do deployment da Sprint.

## 4. Plano de Validação (Testes Unitários de Arquitetura)

### Teste 1: A Última Quentinha (Concorrência)
**Objetivo:** Validar o `rpc_reservar_oferta_atomica` e o Row-Level Lock (`FOR UPDATE`).
**Cenário:** Cadastramos Frango Grande com `limite_producao = 1`. Abrimos duas conexões simultâneas tentando rodar o RPC pedindo 1 unidade.
**Resultado Esperado:** A transação A retorna `TRUE` (Commit) e reserva. A transação B retorna `FALSE` (Rollback) por falta de saldo.

### Teste 2: Webhook Duplicado (Idempotência)
**Objetivo:** Validar a constraint UNIQUE.
**Cenário:** O script insere `pedidos` passando `provedor_evento = 'WHATSAPP'` e `external_event_id = 'XYZ123'`. Imediatamente enviamos a mesma requisição SQL.
**Resultado Esperado:** O PostgreSQL bloqueia a segunda inserção com Erro Padrão de violação de Unique Constraint. Nenhum pedido duplo é criado.

### Teste 3: Alteração de Preço (Congelamento)
**Objetivo:** Validar a integridade financeira no decorrer do tempo.
**Cenário:** Criar uma Oferta a R$ 22,00. Registrar um Pedido. A trigger (ou aplicação) salva R$ 22,00 no `itens_pedido`. No dia seguinte, alteramos o `preco_vigente` da Oferta para R$ 25,00. Consultamos o subtotal do Pedido antigo.
**Resultado Esperado:** O subtotal do Pedido continua apontando a matemática contra os R$ 22,00 (Preço congelado).

### Teste 4: Fechamento Analítico (Matriz)
**Objetivo:** Validar os relatórios derivados do agrupamento.
**Cenário:** Geramos 4 pedidos espalhados em tamanhos e pratos. Disparamos a query base de relatórios (Um `GROUP BY` triplo no SQL associando `itens_pedido` -> `ofertas`).
**Resultado Esperado:** A query retorna as 3 visões (Por Tamanho, Por Prato, Matriz Prato × Tamanho) em milissegundos usando apenas a matemática dos fatos puros, sem precisar de tabela de redundância.

## 5. Riscos Mapeados
O maior risco operacional na aplicação prática desse modelo é o processo de inicialização de usuários (Seed de Auth). Como o RLS foi fechado radicalmente, sem um script inicial que injete usuários na tabela `auth.users` e no respectivo `perfis`, o App Flutter não conseguirá ler o cardápio. Para sanar isso, a Migration de Produção exigirá inserção de usuários primordiais ou um fluxo bypass (Ex: tela pública "Menu Web" poderá precisar de liberação de Leitura `SELECT` sem auth para clientes visitarem o site de cardápio).
