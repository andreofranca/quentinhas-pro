# EOS-006.6 — Materialização do Schema V1

**Timestamp:** 2026-08-15T14:19:15-03:00
**Banco Alvo:** `quentinhas` (PostgreSQL 16)
**Container Alvo:** `quentinhas_pro_pg` (Porta 5440)

## 1. Auditoria Pré-Execução
Antes de injetar o Schema:
- Confirmamos que o banco estava absolutamente vazio (`Did not find any relations.`).
- Confirmamos que o alvo era restrito ao laboratório PostgreSQL provisionado pela imagem base Alpine, não tendo relação alguma com a Cloud do Supabase ou com o projeto herdado `lanchonete-controle`.
- O login ocorreu corretamente usando `quentinhas_app`.

## 2. Resultado da Aplicação (Deployment)
O arquivo `backend/src/main/resources/db/migration/V1__init_schema.sql` foi transferido e carregado com proteção transacional nativa (`ON_ERROR_STOP=1`). O comando rodou **exatamente uma vez**.
Nenhum artefato destrutivo foi usado (nada de `db reset`).

### Objetos Criados
14 Tabelas e 2 Funções transacionais materializadas perfeitamente:
- `auditoria_operacoes`
- `caixas`
- `cardapios`
- `clientes`
- `ingredientes`
- `itens_ficha_tecnica`
- `itens_pedido`
- `movimentacoes_estoque`
- `ofertas`
- `pagamentos`
- `pedidos`
- `produtos`
- `regras_porcionamento`
- `usuarios`

**Transition Engine RPCs:**
- `rpc_processar_pedido(jsonb)`
- `rpc_reservar_oferta_atomica(uuid, integer)`

## 3. Verificação de Integridade
- **Banco:** Permanece aberto, aceitando conexões normalmente pela porta 5440.
- **Spring Boot Conectividade:** O `mvnw test` foi executado com sucesso e injetou as conexões reais. O pool `HikariCP` autenticou contra o database materializado. O contexto do Spring provou resiliência. Nenhuma anomalia de DDL ou bloqueio foi acusada.
- **Warnings:** O Spring logou avisos comuns (ex: gerando senha `inMemoryUserDetailsManager` e `spring.jpa.open-in-view enabled`), típicos da fundação e que serão blindados oportunamente. Nada referente a risco arquitetural ou de banco de dados.

## 4. Estado Atual e Recomendação
O ambiente transacional raiz do **Quentinhas Pro** agora existe, isolado e perfeitamente estruturado. O núcleo `V1` provou funcionalidade estática, integridade DDL e sintonia Java/JPA.
Nenhum dado real foi semeado e os diretórios do Supabase local permanecem intactos.

🟢 **Recomendação: GO PARA TESTES DA TRANSITION ENGINE.**
Podemos proceder com os testes funcionais e provar a idempotência nativa, isolada de Supabase!
