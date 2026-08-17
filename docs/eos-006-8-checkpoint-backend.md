# EOS-006.8 — Checkpoint da Fundação Backend e Transition Engine

**Status Global:** 🟢 Fundamentos Concluídos
**Componentes Validados:** PostgreSQL 16 (Nativo) + Spring Boot 3 (Nativo)

Este documento atua como checkpoint oficial após a materialização do esquema no PostgreSQL local e a validação ácida do seu motor de transição de status (Transition Engine), provando de vez a independência do ecossistema Supabase.

## 1. Organização e Limpeza
* **Laboratório:** Todos os arquivos SQL (seeds e scripts de teste de carga) foram migrados de escopo aberto e estão agora contidos com segurança em `backend/src/test/resources/lab-sql/`. Eles não correm o risco de serem engolidos pela rotina nativa do Flyway na inicialização real, sendo puramente evidências estáticas.
* **Git e Credenciais:** Não existem vazamentos de senhas reais no Git. As propriedades de segurança apontam senhas geradas programaticamente (`inMemoryUserDetailsManager` no profile `local`).
* **Testes Temporários:** O `BackendApplicationTests.java` original foi retornado à sua integridade estrutural (context-only validation). A prova viva de chamabilidade JDBC foi refatorada para um teste permanente: `TransitionEngineIntegrationTest.java`. Esse teste age como Guardrail Arquitetural — ele tentará invocar a RPC garantindo que, se no futuro o banco ficar dessincronizado, o CI falhe imediatamente na compilação.

## 2. Evidências de Homologação (EOS-006.7)
A Transition Engine provou sua robustez e blindagem nos cenários projetados:
* **Concorrência (50 requisições × 10 estoque):** O motor de travamento (`SELECT ... FOR UPDATE`) absorveu as compras garantindo aprovação estrita dos 10 primeiros lotes, injetando 40 recusas exatas (`Exception: Estoque esgotado`). **Overselling: 0**.
* **Idempotência:** Requisições clonadas via mensageria do WhatsApp foram rejeitadas na raiz via Unique Constraint dupla (`provedor_evento`, `external_event_id`). 
* **Rollback:** Uma anomalia simulada no módulo de pagamentos estourou corretamente a constraint monetária (`valor > 0`), disparando um *graceful rollback* absoluto que poupou inventário, pedido e itens gerados no meio da transação.
* **Integridade Java-JDBC:** O framework Spring Boot interpretou e transcreveu todas as anomalias nativas (`RAISE EXCEPTION` no PL/pgSQL) como `SQLException` seguras, atestando a via dupla de mão na arquitetura.

## 3. Estado Atual do Banco
* **PostgreSQL (Local):** `quentinhas` port 5440.
* **Camada Data:** `public` schema populado e limpo.
* **Camada RPC:** `rpc_processar_pedido` e `rpc_reservar_oferta_atomica` estão instanciadas nativamente.
* **Seed:** Banco está com o seed manual de laboratório inserido, pronto para ser expurgado caso precisemos de um *clean state*, ou preservado caso a construção da API queira usufruir da entidade para as primeiras requisições HTTP locais.

## 4. Estado da Suíte de Código
* `mvnw test`: 🟢 Passou (2 testes: Contexto & Integração Transition Engine).
* `flutter test`: 🟢 Passou (Suite Dart intacta - Supabase Mock Mockito mantido).
* `git diff --check`: 🟢 Limpo. Não existem detritos sintáticos.

## 5. Próximos Passos (Pendências)
A arquitetura base (Pilar de Dados) está 100% pronta. O bloqueio está cravado agora no domínio de Exposição.
Próxima diretriz de valor: **Construir os Endpoints REST da API**.
- Estruturação dos Data Transfer Objects (DTOs).
- Implementação dos `@RestController` em Spring MVC.
- Instanciação do `@Service` de vendas que delegará o Payload JSON direto para a nossa RPC JDBC blindada.
- Acoplamento posterior entre a interface Flutter e o novo Servidor.
