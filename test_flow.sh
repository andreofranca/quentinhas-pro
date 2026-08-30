#!/bin/bash
echo "1. Criando Pedido"
RESPONSE=$(curl -s -X POST http://localhost:8080/api/pedidos \
-H "Content-Type: application/json" \
-d '{
  "caixaId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "cliente": {
    "nome": "João E2E",
    "telefone": "11999999999"
  },
  "modalidade": "ENTREGA",
  "taxaEntrega": 5.0,
  "enderecoEntrega": "Rua Teste, 123",
  "totalBase": 20.0,
  "itens": [
    {
      "produtoId": "a2b0e6e7-005d-4009-8d8a-92c90c74deaa",
      "quantidade": 2,
      "precoUnitario": 10.0,
      "subtotal": 20.0
    }
  ],
  "pagamento": {
    "formaPagamento": "DINHEIRO",
    "valor": 25.0
  },
  "provedorEvento": "LOCAL",
  "externalEventId": "evt_1234567"
}')
echo $RESPONSE

sleep 1

echo "2. Buscando pedidos reais da KDS"
curl -s http://localhost:8080/api/pedidos | grep "João E2E"

echo "3. Transicionando Status para EM_PRODUCAO"
PEDIDO_ID=$(curl -s http://localhost:8080/api/pedidos | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
curl -s -X POST http://localhost:8080/api/pedidos/$PEDIDO_ID/transicao \
-H "Content-Type: application/json" \
-d '{"novoStatus": "EM_PRODUCAO"}'

echo "4. Verificando Status no Banco"
curl -s http://localhost:8080/api/pedidos | grep "EM_PRODUCAO"
