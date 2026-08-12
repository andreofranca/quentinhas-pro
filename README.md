# Quentinhas Pro
### ERP para Comida Caseira, Quentinhas e Delivery

**Origem:** Este projeto nasce da evolução estrutural do ERP Lanchonete Pro (`prj_lanchonete`), preservando o patrimônio histórico e verticalizando-o para o domínio de Comida Caseira (ofertas do dia, porcionamento, controle rígido de concorrência e idempotência logística/financeira).

## Visão Geral da Arquitetura
O sistema opera através de uma **Transition Engine** centralizada em PostgreSQL (Supabase), permitindo que fluxos híbridos (WhatsApp, Web, Flutter de Balcão) entrem concorrentemente sem causar inconsistências de banco, travamento de estoque (overselling) ou duplicação de pagamentos (idempotência webhooks).

## Status de Deploy (Supabase)
⚠️ **NENHUMA** migração do novo modelo (EOS-003) foi executada contra a base. O schema do Supabase atualmente permanece intocado (Legado).

## Engenharia Orientada a Sistemas (EOS)
A trilha de construção atual está pausada formalmente no checkpoint `EOS-003.2`. 
Para detalhes arquiteturais, veja a pasta `docs/` e o documento principal `docs/PROJECT_CHECKPOINT.md`.

## Próxima Etapa de Retomada
Para retomar a construção, a missão mandatória é a **EOS-003.3 — Code Review dos SQLs**.
