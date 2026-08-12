# CHECKPOINT DE PROJETO - QUENTINHAS PRO

**Data do Congelamento:** 12 de Agosto de 2026
**Nome do Produto:** Quentinhas Pro (ERP para Comida Caseira, Quentinhas e Delivery)
**Repositório Legado:** `prj_lanchonete` (mantido temporariamente)

## 1. Origem e Objetivo
Evoluir o repositório legado Lanchonete Pro, reaproveitando a engine de templates de WhatsApp, UI e o núcleo de cadastro (Ingredientes/Ficha Técnica), mas refatorando totalmente o modelo de vendas em memória para um banco de dados real com *Atomic Locks*, Idempotência Forte e RLS baseado em perfis (Role Based Access Control).

## 2. Status das Fases (EOS)
- EOS-001 (Baseline) — ✅ APROVADA
- EOS-001.1 (Validação) — ✅ APROVADA
- EOS-002 (Domínio) — ✅ APROVADA
- EOS-002.1 (WhatsApp+Tamanhos) — ✅ APROVADA
- EOS-002.2 (Fechamento Domínio) — ✅ APROVADA
- EOS-003 (Modelo Planejamento) — ✅ PLANEJAMENTO APROVADO
- EOS-003.1 (DDL Preview) — ✅ DDL PREVIEW APROVADO
- EOS-003.2 (Plano de Migration) — ✅ PLANO DE MIGRATION APROVADO
- **EOS-003.3 (Code Review SQL) — ⏸️ PRÓXIMA MISSÃO**

## 3. Estado do Banco (Supabase)
**ZERO migrations executadas.**
O banco legado (ingredientes, produtos, ficha técnica e movimentações) está fisicamente preservado. Nenhum `DROP TABLE` ou `DROP SCHEMA` foi planejado ou executado.

## 4. Migrations Preparadas
Localizadas em `supabase/migrations/`:
- `20260812000001_fundacao.sql`
- `20260812000002_caixas_pedidos.sql`
- `20260812000003_pagamentos.sql`
- `20260812000004_auditoria.sql`
- `20260812000005_seguranca_rls.sql`

## 5. Resumo das Decisões de Domínio
- **Tamanhos e Porcionamento:** Ofertas usam dimensões formais (PEQUENA, MEDIA, GRANDE) ligadas a uma `regras_porcionamento` decimal.
- **Reserva vs Consumo:** Criação de pedido gera Reserva (Lock de registro); Produção física gera Consumo (Baixa na Ficha).
- **Idempotência:** Todo Request injeta UNIQUE(provedor, external_event_id). Impede compras duplicadas por retransmissão de webhook.
- **Concorrência Atômica:** Um RPC (`SELECT ... FOR UPDATE`) garante que duas compras simultâneas para a "Última quentinha" não completem, com o perdedor da corrida recebendo *Rollback*.
- **Relatórios:** Nenhuma tabela de totais criada. Cruzamento de matriz puramente por Fatos (`itens_pedido` x `ofertas` x `pagamentos`).
- **Segurança (RLS):** Supabase Auth JWT injeta Roles. Service Role (backend edge) assume apenas interações RPC, não ganhando bypass genérico de tabela.
- **Caixa:** Gavetas abertas amarradas ao terminal, permitindo que operadores circulem sem travamento indevido.
- **Auditoria:** Gravação de Payload (estado_anterior, estado_novo) em alterações críticas (Cancelamento/Ajuste).
- **Preço Congelado:** Histórico intocável. Alterar o preço no Catálogo do dia seguinte não contamina os relatórios antigos.

## 6. Riscos Mapeados
O maior risco operacional na retomada será o Seed de usuários. Como fechamos o RLS via Políticas de Autorização (Perfis), será necessário aprovisionar um usuário *ADMIN* diretamente na tabela `auth.users` e `perfis` para que o App Flutter consiga realizar as primeiras inserções/leituras do Cardápio de testes.

## 7. Testes Pendentes (Arquiteturais - Pós Code Review)
1. Concorrência (Corrida da última quentinha).
2. Idempotência (Webhook de WhatsApp clonado).
3. Histórico (Preço congelado após remarcação de cardápio).
4. Fechamento Analítico (Geração de matrizes agrupadas Prato x Tamanho).

## 8. Como retomar o trabalho
Peça ao agente de IA:
> **Iniciar a missão EOS-003.3 — Code Review dos SQLs.** Revise os cinco arquivos gerados em `supabase/migrations/` focando em integridade e idempotência, sem rodá-los contra o banco. Prepare o cenário para a execução física no Supabase.
