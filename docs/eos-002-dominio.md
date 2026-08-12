# Domínio Comida Caseira (EOS-002.2 Fechado)

## 1. Glossário do Domínio
- **Produto (Catálogo):** Elemento permanente, o prato base cadastrado no sistema (ex: "Frango Assado").
- **Ingrediente:** Matéria-prima base para compor um produto.
- **Ficha Técnica:** Base de custeio/consumo. Pode possuir "Regra de Porcionamento" por Tamanho.
- **Prato do Dia (Oferta do Dia):** O que efetivamente está disponível para venda hoje (Data, Disponibilidade, Quantidade Limitada).
- **Tamanho:** Dimensão formal obrigatória (PEQUENA, MÉDIA, GRANDE), podendo influenciar preço, estoque e limite.
- **Item Comercializável:** A oferta concreta (Prato do Dia + Tamanho).
- **Draft de Pedido (Canal):** Intenção de compra originada no WhatsApp, Balcão ou Web, aguardando validação atômica.
- **Pedido:** A unidade central (Transition Engine) da venda.
- **Item do Pedido:** Preserva o contexto comercial (Prato, Tamanho, Preço congelado).
- **Produção:** Transformação física. Separa o que foi *oferecido*, *reservado*, e *efetivamente consumido*.
- **Entrega / Retirada:** Operação logística.
- **Pagamento:** Estado financeiro independente da operação logística.
- **Caixa e Relatórios:** Sessão financeira que exige fechamento Sintético e Analítico, agrupando vendas em Matriz (Prato × Tamanho).
- **Cliente:** Entidade persistente mínima (Identificação, Telefone, Nome, Endereços e Histórico).

---

## 2. Ciclo de Vida do Estoque e Produção
Para suportar o controle operacional e evitar overselling, o estoque/produção opera em dois tempos:
1. **Reserva (Lógica):** Ao confirmar o Pedido, o sistema trava a quantidade disponível do Prato do Dia. Não altera o físico ainda.
2. **Consumo (Físico):** Durante a Produção, a Ficha Técnica atrelada ao Tamanho deduz os Ingredientes do estoque físico real.

---

## 3. Entidades Centrais do Domínio

### Cliente (Mínimo Persistente)
- **Atributos:** ID, Telefone (Chave para WhatsApp), Nome, Endereço Padrão.

### Prato do Dia (Cardápio)
- **Atributos:** Data, Produto_ID, Status.

### Oferta Comercial (Prato × Tamanho)
- **Atributos:** Preço Específico, Limite de Produção Específico. Permite que PEQUENA custe X e tenha limite Y, e GRANDE custe Z.

### Pedido (Transition Engine)
- **Atributos:** ID, Cliente_ID, Total, Status Operacional, Modalidade, Status Financeiro.

### ItemPedido
- **Atributos:** Pedido_ID, Oferta_ID (Prato+Tamanho), Quantidade, Preço Unitário Congelado, Subtotal.

### Sessão de Caixa
- **Atributos:** Abertura, Fechamento, Operador.
- **Responsabilidade:** Consolidar financeiro x operacional (cruzamento matriz Prato x Tamanho).
