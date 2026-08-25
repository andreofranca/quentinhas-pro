# EOS-GOLIVE-02: Abertura de Caixa

## Objetivo
Implementar a abertura de caixa pelo operador para permitir o registro de pedidos reais, removendo o bloqueio principal do fluxo de vendas.

## Escopo Realizado
- Backend: Criado POST /api/caixas/abrir com validao de saldo >= 0 e bloqueio de caixas duplicados (HTTP 409).
- Frontend: Implementado modal iterativo na TelaCheckoutMock para solicitar o saldo inicial caso o operador no possua caixa ativo (capturando HTTP 404), integrando automaticamente ao fluxo contnuo de fechamento de pedido.
- Testes: Adicionados testes de integrao robustos validando segurana (JWT), restries e fluxo port-abertura. Todos os 32 testes do Backend e 56 do Frontend passando.

## Checkpoints
- **Feature**: `7dae6ee` - feat(caixa): implementar abertura de caixa
