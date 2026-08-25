# EOS-GOLIVE-05 - Fechamento de Caixa

**Objetivo:** Completar o ciclo operacional do caixa (Abertura -> Venda -> Fechamento).

**Implementação:**
- Backend: Criado POST /api/caixas/fechar calculando automaticamente o faturamento em sistema via JdbcTemplate consultando pedidos.
- Testes Backend: Adicionado echarCaixaComSucesso validando a resposta 200 OK e o cálculo da diferença.
- Flutter: Injetado endpoint no CaixaService e criada a interface _mostrarModalFechamentoCaixa no AppBar do Dashboard.

**Status:** Aprovado.
**Hash do Checkpoint:** d19ca96
