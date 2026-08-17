SELECT rpc_processar_pedido('{
  "caixa_id": "00000000-0000-0000-0000-000000000006",
  "total": 200.00,
  "modalidade": "BALCAO",
  "provedor_evento": "BALCAO",
  "external_event_id": "msg_002",
  "itens": [
    {"oferta_id": "00000000-0000-0000-0000-000000000005", "quantidade": 11, "preco_unitario": 20.00, "subtotal": 200.00}
  ]
}'::jsonb);
