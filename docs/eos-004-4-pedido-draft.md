# Documentação: Pedido Draft e Validações de Domínio (EOS-004.4)

## O Papel do PedidoDraft
O `PedidoDraft` foi oficialmente consolidado como a **fronteira absoluta** entre a interface do usuário e o sistema de pedidos. 

**O Draft não é o Pedido.**
Ele representa uma *intenção de compra* validada em memória. O sistema só avança para a comunicação externa (WhatsApp) ou persistência (Supabase) se o Draft for válido segundo as regras da lanchonete.

## Invariantes Garantidos pelo Domínio
O construtor do `PedidoDraft` agora chama o método `validar()`, que atua como um escudo protegendo as instâncias de estados inconsistentes. Se a UI tentar gerar um Draft inválido, uma `Exception` será disparada, impedindo o fluxo.

As regras ativas (testadas e cobertas) são:
1.  **Dados do Cliente:** O `ClienteContato` e o telefone são de preenchimento obrigatório. Não existem rascunhos anônimos.
2.  **Conteúdo:** O carrinho não pode estar vazio (`itens.isNotEmpty`).
3.  **Quantidade e Preço:** Todo item precisa ter quantidade `> 0` e o preço do tamanho escolhido deve ser `>= 0`.
4.  **Consistência Matemática:** A soma aritmética dos itens (`calculoSubtotal`) deve bater exatamente com o `subtotalItens` passado. Isso previne que a UI injete valores corrompidos.
5.  **Logística Rígida:**
    *   `TipoEntrega.entrega`: Exige que o `EnderecoEntrega` seja não nulo.
    *   `TipoEntrega.retirada`: Exige que a `taxaEntrega` seja exatamente `0.0`. Não pode haver "taxa de balcão".
6.  **Preço Congelado:** O Draft grava o subtotal baseando-se no preço do tamanho *naquele momento*. Não há reconta de preço em APIs externas após a montagem do Draft.

## Representação Canônica de Tamanho
O enum `TamanhoQuentinha` (com os valores `P`, `M`, `G`) possui a propriedade estrita `.sigla`, que substituiu a propriedade `.nome` na montagem das strings oficiais. O WhatsAppMessageBuilder e os módulos de notificação passam a emitir "Frango Assado (M)" ao invés de "Frango Assado (Média)". A string `Média` foi banida de lógicas sistêmicas, ficando restrita apenas aos Labels de UI.

## Conclusões
- A arquitetura está preparada: **UI → Draft → Validação de Domínio → Canal (WhatsApp)**.
- Qualquer erro no preenchimento do formulário será barrado pela dupla barreira: a validação de form (Flutter) e a validação de Domínio (Modelo puro).
- O backend final (Transition Engine) assumirá que qualquer Draft entregue a ele já está logicamente coeso e matematicamente correto.
