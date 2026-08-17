# EOS-006.5 — Adaptação de Schema para PostgreSQL Nativo

Este documento formaliza a separação do código legado do Supabase e o planejamento e estruturação do banco de dados relacional puro (PostgreSQL 16) para a camada Spring Boot.

## 1. Auditoria das Migrations Legadas (`001` a `005`)

Foram identificados nas migrations originais os seguintes elementos incompatíveis com uma arquitetura 3-Tier limpa:
- **`auth.users`:** Tabela injetada e controlada pelo sistema GoTrue do Supabase. Totalmente inacessível via ORMs tradicionais na mesma transação.
- **`RLS (Row Level Security)`:** Todas as tabelas dependiam do RLS com as funções `auth.uid()` e `auth.role()`. Num backend Spring Boot com Connection Pooling (HikariCP), as conexões são reaproveitadas por múltiplos usuários, inviabilizando o uso seguro do `auth.uid()` em nível de banco de forma performática sem gambiarras de *session variables*.
- **Policies:** Todas as regras de negócio de `INSERT/UPDATE/DELETE` estavam chumbadas em `CREATE POLICY`.
- **Foreign Keys Quebradas:** Muitas tabelas referiam-se às tabelas base do domínio sem que estas tivessem sido portadas nas migrations do Supabase (o Supabase assumia a infraestrutura base do Laboratório `lanchonete-controle` já instanciada e injetada no Cloud do laboratório via CLI, sem explicitamente detalhar `produtos` ou `ingredientes` em DDL).

## 2. A Nova Estrutura (PostgreSQL Puro)

Desenvolvemos o arquivo consolidado de schema: `backend/src/main/resources/db/migration/V1__init_schema.sql` (Padrão Flyway).

Este script unifica o domínio completo:
1. **Domínio Segurança/Usuários:** Criamos a tabela nativa `public.usuarios`, que absorve as colunas da antiga tabela associativa `perfis`. Essa tabela guardará o `password_hash` que será gerido pelo Spring Security.
2. **Domínio Operacional/Estoque:** Estruturas base (`produtos`, `ingredientes`, `itens_ficha_tecnica`, `movimentacoes_estoque`) foram documentadas em código e portadas.
3. **Domínio Vendas/Ofertas:** `regras_porcionamento`, `cardapios`, `ofertas`.
4. **Domínio Transacional e Caixas:** `caixas` (referenciando `usuarios`), `pedidos` (idempotente com `external_event_id`), `itens_pedido`, `pagamentos` e `auditoria_operacoes`.
5. **Master Transition Engine:** As RPCs `rpc_reservar_oferta_atomica` e `rpc_processar_pedido` foram transpostas com sucesso. Todas as referências a `auth.users` foram substituídas pela tabela `usuarios`.

## 3. Arquitetura de Segurança Atualizada

Em concordância com a regra de "não perder segurança ao retirar o Supabase":
- **Garantia de Integridade e ACID:** O `SELECT ... FOR UPDATE` (Pessimistic Locking) continua vivo dentro das funções transacionais, prevenindo overbooking.
- **Garantia de Idempotência:** A constraint de `UNIQUE(provedor_evento, external_event_id)` em pedidos e pagamentos continua travando repetições do WhatsApp.
- **Supressão do RLS:** O RLS foi descartado. O controle de quem pode visualizar/alterar um pedido agora pertence exclusivamente aos `@RestController` e `@Service` do Java, usando JWT. O backend será a única "Service Role" comunicando-se com o banco de dados.

## 4. Estado da Missão
O script DDL `V1__init_schema.sql` está criado, mas **nenhuma migration foi rodada**. O banco de dados local `quentinhas` continua vazio e seguro, aguardando aprovação técnica final do Arquiteto/PO.

A integridade do código original (`lanchonete-controle`) ou ambiente Cloud não sofreu interferências.
