# Invariantes e Regras de Negócio (EOS-002.2 Fechado)

As invariantes são regras imutáveis que garantem a integridade da Transition Engine e do Banco de Dados.

### 1. Invariantes de Produto e Estoque (Reserva vs Consumo)
- **INV-EST-001 (Reserva):** A confirmação de um pedido converte o Draft em Pedido e gera uma *Reserva* imediata do Produto/Oferta no Cardápio do dia.
- **INV-EST-002 (Consumo):** O avanço para a etapa de *Produção* consolida o consumo físico dos ingredientes da Ficha Técnica.
- **INV-EST-003 (Cancelamento Lógico):** Cancelar um pedido ANTES da produção devolve a Reserva da Oferta imediatamente.
- **INV-EST-004 (Cancelamento Físico):** Cancelar um pedido DEPOIS da produção (consumo físico realizado) NÃO devolve ingredientes ao estoque automaticamente. Exige registro de destinação (Ex: Perda).

### 2. Invariantes de Pedido (Domain Engine)
- **INV-PED-001 (Concorrência Atômica):** A transformação de Draft em Pedido confirmado deve validar e reservar a disponibilidade de forma atômica (Lock) no Banco de Dados. Impede overselling.
- **INV-PED-002 (Preço Congelado):** O preço comercial efetivamente praticado deve ser preservado fisicamente no `ItemPedido` na hora da confirmação.
- **INV-PED-003 (Tamanho Operacional):** O tamanho (PEQ/MED/GDE) é parte do contexto comercial do `ItemPedido` e não pode ser tratado como campo de texto livre.

### 3. Invariantes Financeiras e Logísticas
- **INV-PAG-001 (Independência):** O estado Operacional (Ex: `SAIU_PARA_ENTREGA`) e o estado Financeiro (Ex: `PENDENTE`) são mutuamente independentes. O pagamento não bloqueia a logística.
- **INV-LOG-001:** Pedidos de Entrega exigem endereço no fluxo de Draft.

### 4. Invariantes de Relatório e Caixa
- **INV-REP-001:** O banco não deve possuir tabelas de totais redundantes. Todo `ItemPedido` validado deve preservar atributos para que relatórios analíticos cruzem `(Prato × Tamanho × Quantidade × Data)`.
- **INV-CAIXA-001:** O fechamento de caixa deve permitir agrupamento Sintético (Qtd e Valor total agrupado por Tamanho) e Analítico (Tamanho -> Prato -> Qtd -> Preço).
