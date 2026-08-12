# Estratégia de Índices (EOS-003)

O banco deve performar tanto para consultas analíticas (relatórios de fechamento de caixa) quanto para chaves de Idempotência.

## 1. Índices Operacionais Básicos (Leitura)
- **`idx_ofertas_cardapio`**: Em `ofertas(cardapio_id)`. Otimiza a listagem de pratos do dia no App e no WhatsApp.
- **`idx_pedidos_cliente`**: Em `pedidos(cliente_id)`. Otimiza buscar histórico de um usuário que chamou no bot.
- **`idx_pedidos_status`**: Em `pedidos(status_operacional, status_financeiro)`. Para as abas do Frontend (Painel da Cozinha / Balcão).
- **`idx_pedidos_caixa`**: Em `pedidos(caixa_id)`. Para fechar o caixa rapidamente.

## 2. Índices de Relatórios Matriz (Prato × Tamanho)
Os relatórios não requerem tabelas redundantes, pois os cruzamentos serão resolvidos em tempo real via SQL. Para suportar isso de forma leve:
- **`idx_itens_pedido_oferta`**: Em `itens_pedido(oferta_id)`. O agrupamento buscará os itens associados às ofertas (que trazem o Prato e o Tamanho implicitamente).
- Como `ItemPedido` já tem `quantidade` e `subtotal`, os `GROUP BY` e `SUM()` do PostgreSQL rodarão em milissegundos utilizando este índice acoplado ao FK do pedido e data do Caixa.

## 3. Índices de Idempotência e Concorrência (Cruciais)
- **`idx_pedidos_external_event`**: Em `pedidos(external_event_id)` com regra **UNIQUE**.
  - Impede a anomalia: Webhook do WhatsApp retransmite uma intenção de compra, o banco bloqueia via *Constraint Violation* se o ID externo do bot já existir na base, garantindo processamento único.
- **`idx_pagamentos_external_tx`**: Em `pagamentos(external_transaction_id)` com regra **UNIQUE**. Evita duplo crédito de um mesmo PIX recebido.
