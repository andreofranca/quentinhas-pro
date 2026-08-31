# Finalization status — 2026-08-31

## Estado auditado

O repositório contém Flutter, Spring Boot, PostgreSQL e Flyway. A árvore de trabalho já possuía uma implementação não commitada de Produtos e Estoque. Ela foi corrigida para compilar: o CRUD usa `ProdutoService`, a rota Flutter de atualização de estoque inclui o identificador do produto e os testes de integração recém-adicionados foram alinhados ao contrato atual.

## Funcionalidades reais

- Autenticação JWT, catálogo, caixa, pedidos, transição de pedido, cardápio/ofertas e relatórios possuem controllers e serviços Spring, além de consumidores Flutter.
- Produtos e estoque possuem migration Flyway (`V3` e `V4`), entidades, endpoints e serviços Flutter. A validação de integração com PostgreSQL está pendente do banco de testes.

## Funcionalidades parciais ou mockadas

- O ponto de entrada do Flutter usa `TelaDashboardQuentinhas`, que abre `TelaCheckoutMock`; taxa de entrega e telefone da cozinha são dados simulados.
- `listaUsuarios` mantém usuários, senhas e autorização administrativa em memória. A gestão de equipe não está conectada ao backend e não deve ser tratada como funcional.
- O catálogo estático `cardapio` ainda abastece fluxos fora das telas de Produtos/Estoque; precisa ser removido ou isolado após a migração dos consumidores.
- Mocks em `test/` são testes legítimos e devem ser preservados.

## Endpoints auditados

- Consumidos pelo Flutter: autenticação, catálogo, caixas, pedidos, gestão de ofertas, produtos e estoque.
- Endpoints de Produtos: `GET/POST /api/gestao/produtos`, `GET /api/gestao/produtos/ativos`, `GET/PUT/DELETE /api/gestao/produtos/{id}`.
- Endpoints de Estoque: `GET /api/gestao/estoque`, `GET/PUT /api/gestao/estoque/{id}`.

## Validação executada

- `flutter analyze`: PASS (0 issues).
- `flutter test`: PASS (57 testes).
- `mvnw clean package -DskipTests`: PASS.
- `mvnw clean test`: bloqueado antes da execução dos testes porque PostgreSQL em `localhost:5440` recusou conexão. O Docker Desktop não está em execução; portanto não houve validação de migrations, APIs ou E2E real nesta sessão.

## Blockers e próximos passos

1. Iniciar Docker Desktop e `docker compose up -d` em `backend/`; executar `mvnw clean test`.
2. Substituir checkout/WhatsApp mockado por fluxo de pedido real.
3. Implementar gestão de usuários persistida, sem senhas na UI, e remover `listaUsuarios`.
4. Executar o fluxo manual completo com banco real antes de considerar o MVP finalizado.
