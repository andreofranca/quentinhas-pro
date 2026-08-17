# EOS-006.7 — Homologação da Transition Engine

**Timestamp:** 2026-08-15T14:32:50-03:00

Este documento apresenta as evidências do teste de stress e validação ácida do motor transacional (`rpc_processar_pedido` e `rpc_reservar_oferta_atomica`) materializado no banco nativo `quentinhas`, sem uso ou conexão com o ecossistema Supabase.

Para conduzir as baterias de testes, construímos as entidades de setup de infraestrutura (`test-seed.sql`) criando **01 Caixa, 01 Cliente, 01 Produto, 01 Oferta (limite_producao=10)**.

## Tabela de Homologação

| Teste | Esperado | Resultado | Status |
| :--- | :--- | :--- | :--- |
| Pedido válido (Happy Path) | 1 pedido gerado, 1 estoque debitado | **1 pedido, 1 estoque debitado** (`status: SUCCESS`) | 🟢 PASS |
| Overselling (Estoque=9, Pedido=11) | 0 pedidos gerados, rollback automático | **0 pedidos** (`Exception: Estoque esgotado`) | 🟢 PASS |
| Idempotência (Mesmo `external_event_id`) | 1 pedido (não pode duplicar o do Teste 1) | **Exception** (`violates unique constraint`) | 🟢 PASS |
| Rollback e Atomicidade (Pagamento negativo) | 0 resíduos parciais, 0 itens retirados do estoque | **Exception** (`violates check constraint pagamentos_valor_check`), Estoque mantido igual | 🟢 PASS |
| Concorrência PgBench 50 threads x 10 estoque | 10 aprovados / 40 rejeitados / 0 Overselling | **10 transações validadas**, **40 exceções**, Estoque final = 10/10 consumido | 🟢 PASS |
| Spring → RPC via JDBC/JPA | O pacote do pool consegue chamar a RPC passando jsonb e recebe Exceção mapeada corretamente | **O teste do Backend capturou `Exception: Caixa não está aberto` com sucesso.** | 🟢 PASS |

## Sumário e Recomendação
Todo o *stress test* evidenciou que a **Transition Engine não possuía dependência secreta do ecossistema Cloud ou de runtime do PostgREST/GoTrue.** A integridade de lock de linha (`FOR UPDATE`) funciona perfeitamente purista via PostgreSQL TCP (`port 5440`) com `HikariCP` chamando a RPC.

Nenhuma regra comercial precisou ser enxertada no código Java para mitigar falhas do banco — a infraestrutura atômica bloqueou todos os vetores de anomalias com suas restrições de validação e *unique keys*.

O ambiente foi validado. O Git permanece limpo na branch original (com exceção dos artefatos documentais gerados e do teste transiente adicionado na suíte do Backend).

🟢 **GO: BACKEND APROVADO**. A transposição estrutural e de inteligência SQL do Backend legado está **Concluída com louvor e segurança.**
