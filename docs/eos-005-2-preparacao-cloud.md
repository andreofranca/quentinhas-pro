# EOS-005.2 — Preparação para o Ambiente Cloud

## 1. Objetivo
Garantir que os artefatos gerados, testados e validados no laboratório local estejam perfeitamente isolados e blindados para não poluírem o ambiente de Produção/Cloud do Quentinhas Pro. Validar o contrato do PedidoDraft com a RPC antes do apontamento definitivo.

## 2. Isolamento de Laboratório e Proteções (Gitignore)
- **`scratch/` Isolado:** O diretório `scratch/`, utilizado para armazenar os testes em Node.js (`test_concurrency.js`), seeds de teste (`seed_test.sql`), debug scripts, logs temporários e o mock da tabela de produtos (`000_legado_mock.sql`), foi explicitamente adicionado ao `.gitignore` na raiz do projeto.
- **Mock do Legado Removido das Migrations:** A migration `20260812000000_legado_mock.sql`, que recriava as tabelas do Lanchonete Pro no container limpo, foi varrida de `supabase/migrations/` e guardada em `scratch/`. Isso garante de forma determinística que o comando `supabase db push` **nunca** tentará recriar as tabelas `produtos` ou `ingredientes` no Cloud (onde elas já existem e contêm dados de produção).
- **Proteção de Credenciais:** As variações do arquivo `.env` (incluindo chaves de serviço) estão garantidas no `.gitignore`, evitando exposição acidental no versionamento da plataforma.

## 3. Validação do Contrato (Dart → RPC)
Após a massiva execução de testes locais (EOS-005.1), confirmamos a simetria exata de tipagem e payload entre o Dart e o PL/pgSQL:
1. `PedidoDraft.toRpcPayload()` produz um JSON determinístico.
2. `rpc_processar_pedido(payload JSONB)` consome nativamente os arrays e objetos deste JSON.
3. O uso explícito de `provedor_evento` e `external_event_id` (vindos do WhatsApp) tem constraint `UNIQUE` direto na tabela de `pedidos`, eliminando na raiz o risco de duplicação assíncrona.

## 4. Inventário de Deploy (O que vai para o Cloud)
O commit que encerrará a trilha estrutural da **Transition Engine** enviará os seguintes componentes vitais, prontos para a EOS-005.3:

### Migrations Supabase
1. `20260812000001_fundacao.sql` - Tabelas de ofertas, cardápios e regras de porcionamento.
2. `20260812000002_caixas_pedidos.sql` - Controle estrito de caixas abertos/fechados e tabela de pedidos com idempotência.
3. `20260812000003_pagamentos.sql` - Tabela restrita de pagamentos do fluxo.
4. `20260812000004_auditoria.sql` - Observabilidade e rastreabilidade da operação.
5. `20260812000005_seguranca_rls.sql` - Políticas RLS robustas e a compilação final da `rpc_processar_pedido` e `rpc_reservar_oferta_atomica` com *Pessimistic Lock*.

### Aplicação Flutter
- `PedidoDraft` preparado e integrado.
- Integração Mock UI (`tela_checkout_mock.dart` e `tela_dashboard_quentinhas.dart`) com validação de invariantes locais (Estoque, P/M/G).
- Todos os testes unitários passando.

## 5. Próximos Passos
O repositório local está limpo. O laboratório provou o funcionamento do ACIDI. Tudo que era estritamente local está isolado em `scratch/`.
O ambiente está **100% pronto** para iniciarmos a ponte real com o Supabase Cloud e o deploy das migrations.
