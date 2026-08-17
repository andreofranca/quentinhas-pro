SELECT rpc_processar_pedido(
  jsonb_build_object(
    'caixa_id', '00000000-0000-0000-0000-000000000006',
    'total', 20.00,
    'modalidade', 'DELIVERY',
    'itens', jsonb_build_array(
      jsonb_build_object(
        'oferta_id', '00000000-0000-0000-0000-000000000005',
        'quantidade', 1,
        'preco_unitario', 20.00,
        'subtotal', 20.00
      )
    )
  )
);
