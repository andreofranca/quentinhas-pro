# Máquina de Estados e Transições (EOS-002.2 Fechado)

## 1. Diagrama Principal (Status Operacional)

```text
[CANAIS: WhatsApp / Web / Balcão]
               │
               ▼
           [ DRAFT ]  <-- Estado Efêmero. Avalia concorrência.
               │
         (Validado)
               │
               ▼
         [ RECEBIDO ]  <-- Aqui o pedido nasce Oficial. (Reserva Lógica efetuada).
               │
         (Aceito)
               │
               ▼
        [ CONFIRMADO ]
               │
        (Iniciar Produção)
               │
               ▼
       [ EM_PRODUCAO ] <-- Aqui ocorre o Consumo Físico de Estoque.
               │
        (Finalizar Produção)
               │
               ▼
           [ PRONTO ]
               │
    ┌──────────┴──────────┐
    ▼                     ▼
[ SAIU_PARA_ENTREGA ]   [ RETIRADO ]
    │                     │
    └──────────┬──────────┘
               ▼
          [ ENTREGUE ]
               │
               ▼
         [ FINALIZADO ]
```

## 2. Diagrama Secundário (Status Financeiro)
Paralelo ao status operacional, o Pedido possui:
- `PENDENTE`
- `PAGO`
- `ESTORNADO`

*Transições como Entregar um Pedido Pendente (pagar na maquininha) são nativamente suportadas.*

## 3. Matriz de Cancelamento
- **Cancelamento de Recebido/Confirmado:**
  - Libera Reserva de Oferta (O item volta pro Cardápio).
  - Status -> `CANCELADO`.
- **Cancelamento de Em_Producao/Pronto/Saiu_Entrega:**
  - NÃO libera a reserva do prato pro sistema.
  - NÃO devolve ingrediente automaticamente. 
  - Exige informar Destino (Perda, Refeitório, Doação).
  - Status -> `CANCELADO`.
