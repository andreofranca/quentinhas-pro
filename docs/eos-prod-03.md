# EOS-PROD-03: Conectar Relatórios aos Pedidos Reais

## Objetivo
Eliminar o último mock funcional do núcleo operacional (listaPedidosGerais) e integrar as abas de Relatório Sintético e Analítico para consumir os pedidos reais via GET /api/pedidos através do DashboardPedidoService. Além disso, limpar dezenas de linhas de código morto identificadas na auditoria anterior.

## Arquivos Alterados
- lib/main.dart
- lib/models/models_quentinha.dart

## Mocks Removidos
- listaPedidosGerais (mock funcional)
- carrinhoAtual (código morto)
- mockCardapioHoje (código morto)
- TelaCardapioCliente (código morto)
- TelaCheckoutExpresso (código morto)
- PainelTesteCompleto (código morto)

## Endpoints Utilizados
- GET /api/pedidos

## Testes Executados
- lutter analyze: PASS (0 issues)
- lutter test: PASS (57 testes)
- .\mvnw clean test: PASS (43 testes)

## Resultado
A Tela de Relatórios Financeiros foi reescrita para possuir estado de carregamento (_isLoading) e erro (_erro), carregando dinamicamente os pedidos através do DashboardPedidoService().obterPedidos(). Os relatórios sintéticos e analíticos agora calculam ticket médio, faturamento bruto e volume de pedidos baseados em dados persistidos no PostgreSQL pelo Spring Boot.

## Hash do Commit
1a8ebaf
