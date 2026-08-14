# Validação Visual e Primeiro Fluxo Operacional (EOS-004.2)

## 1. Execução Real e Teste de Usabilidade
O fluxo de atendimento foi validado através de simulação de toque programático e renderização real (Widget Tests / Integração), confirmando que a arquitetura consegue suportar o "Rush" do almoço.

**Cenário de Teste Executado:**
1. 1x Frango Assado (M)
2. 2x Bife Acebolado (G)
3. 1x Feijoada (M)

**Tempo Estimado de Ação:** O atendente não precisa abrir modais, menus suspensos ou trocar de aba. As pílulas gigantes de tamanho `[ P ] [ M ] [ G ]` em cada card permitem a inclusão de 3 itens distintos no carrinho com exatos **4 toques (Taps)** diretos na tela principal, facilmente realizáveis em **menos de 5 segundos**.

## 2. P/M/G e Modelo de Dados
O modelo `TamanhoOpcao` foi isolado para garantir que a pílula de tamanho não seja apenas um elemento de design, mas sim uma entidade funcional contendo:
- Sigla do Tamanho (`P`, `M`, `G`)
- Preço Específico (ex: `R$ 25.00`)
- Flag de Disponibilidade (`disponivel: true/false`)

## 3. Gestão de Esgotamento (UX)
Validamos o comportamento crítico de controle de estoque visual:
- **Esgotamento Parcial (Feijoada P):** Apenas o botão `[ P ]` da Feijoada é desabilitado (cinza com o texto "Esgotado"). Os tamanhos `[ M ]` e `[ G ]` continuam clicáveis e o prato continua em evidência.
- **Esgotamento Total (Frango à Parmegiana):** Como todos os tamanhos (`P`, `M`, `G`) estão `disponivel: false`, o card inteiro é esmaecido, o título recebe um *strikethrough* e uma flag vermelha `ESGOTADO` aparece no topo.

## 4. UX do Carrinho Operacional
O `CarrinhoLateralWidget` concentra toda a manipulação do pedido ativo:
- Os itens não precisam ser clicados para abrir detalhes. Os botões de `+` e `-` já estão expostos ao lado da quantidade.
- Se a quantidade chegar a zero ao pressionar `-`, o item é automaticamente removido.
- O Total e Subtotal são recalculados instantaneamente via `setState` no pai (`TelaDashboardQuentinhas`).

## 5. Fluxo de Pagamento (Mock)
Criada a `TelaCheckoutMock`, que substitui o antigo popup genérico e implementa a visão final:
- **Resumo do Pedido:** (Esquerda) com a listagem consolidada.
- **Forma de Pagamento:** (Direita) com blocos selecionáveis (PIX, DINHEIRO, CARTÃO, PENDENTE).
- O botão finaliza e devolve o fluxo limpo ao Dashboard. O *Draft de Pedido* está estabilizado no front-end para que futuras integrações de WhatsApp e Balcão desemboquem na mesma estrutura.

## O que já está excelente
- **Velocidade de Toque:** A conversão em "Cards + Botões Gigantes" erradicou o fluxo demorado de navegação.
- **Tratamento de Estoque na Veia:** O conceito de "Esgotado por Tamanho" resolve o problema clássico de "Temos o prato, mas acabou a embalagem G".
- **Identidade Visual Focada:** Layout "Split-View" no Desktop/Tablet é o estado-da-arte para PDV de Balcão.

## O que precisamos melhorar / Deixar para depois
- **Ajustes Mínimos:** Em telas muito estreitas (Mobile antigo), a pílula de texto pode precisar de um ajuste de `FittedBox` para evitar estouro caso os preços passem de R$ 99,00.
- **Para Depois (Conexão Supabase):** A hidratação do `mockCardapioHoje` deve vir da Tabela de Ofertas/Pratos do Dia do banco. A função `_finalizarPedido` precisará despachar a transação real.
