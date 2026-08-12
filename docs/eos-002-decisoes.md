# Decision Log & Decisões Aprovadas (EOS-002.2 Fechado)

### DEC-003: Reserva + Consumo
- **Decisão:** Pedido confirmado gera RESERVA. Produção gera CONSUMO (Baixa Física). Cancelamento pós-consumo não devolve estoque (exige justificar perda).
- **Status:** [ APROVADA ]

### DEC-004: Pagamento vs Logística
- **Decisão:** O status operacional é independente do status financeiro. Pedidos podem ser entregues estando como Pendentes (pagamento no ato da entrega).
- **Status:** [ APROVADA ]

### DEC-005: Cancelamento Após Consumo
- **Decisão:** O estoque físico não retorna. O sistema registrará o destino da ocorrência (ex: perda, descarte).
- **Status:** [ APROVADA ]

### DEC-006: Tratamento de Cliente Mínimo Persistente
- **Decisão:** O CRM no MVP é mínimo: ID, Nome, Telefone (chave para WhatsApp) e Endereços.
- **Status:** [ APROVADA ]

### DEC-007: Tamanhos (PEQ/MED/GDE)
- **Decisão:** Tamanhos são obrigatórios. Eles determinam o preço e a baixa de estoque proporcional.
- **Status:** [ APROVADA ]

### DEC-008: Tamanho como Dimensão Operacional
- **Decisão:** A Ficha Técnica possuirá regra de porcionamento ou adaptação na modelagem para que não exista repetição indevida, mas garantindo que o consumo varie pelo tamanho.
- **Status:** [ APROVADA ]

### DEC-009: WhatsApp como Requisito MVP
- **Decisão:** O código existente (Outbound via `url_launcher`) será documentado e adaptado/substituído gradativamente por um Bot Inbound. Templates textuais do prj_lanchonete atual serão fortemente reaproveitados.
- **Status:** [ APROVADA ]

### DEC-010: Reserva Atômica / Concurrency
- **Decisão:** A validação do Draft e conversão para Pedido oficial deve possuir travamento (lock) atômico no backend para impedir overselling simultâneo.
- **Status:** [ APROVADA ]

### DEC-011: Relatórios Prato × Tamanho
- **Decisão:** A arquitetura do `ItemPedido` assegurará agrupamentos sintéticos e analíticos de cruzamento matriz, identificando ranking e combinações campeãs de venda sem duplicação estrutural.
- **Status:** [ APROVADA ]
