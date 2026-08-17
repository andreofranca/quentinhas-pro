SELECT rpc_processar_pedido('{
  "caixa_id": "00000000-0000-0000-0000-000000000006",
  "cliente": {"telefone": "11999999999", "nome": "Cliente Lab"},
  "total": 20.00,
  "modalidade": "DELIVERY",
  "taxa_entrega": 0.00,
  "provedor_evento": "WHATSAPP",
  "external_event_id": "msg_001",
  "itens": [
    {"oferta_id": "00000000-0000-0000-0000-000000000005", "quantidade": 1, "preco_unitario": 20.00, "subtotal": 20.00}
  ],
  "pagamento": {
    "forma_pagamento": "PIX",
    "valor": 20.00,
    "valor_recebido": 20.00,
    "troco": 0.00
  }
}'::jsonb);
