# EOS-004.7.1 — Benchmark Completo: Motor de Pedidos via WhatsApp (Lanchonete Pro vs Quentinhas Pro)

## 1. Mapeamento das Capacidades Legadas
Durante a auditoria profunda na base de código original (`lib/main.dart` do Lanchonete Pro), mapeamos as capacidades do fluxo de checkout expresso (`_TelaCheckoutExpressoState`).

**Como o legado funcionava:**
- Formulário capturava Cliente, Tipo de Entrega, CEP (com busca direta na UI), Endereço, Forma de Pagamento e **Troco**.
- Havia validação se o valor "Troco para" era menor que o total.
- Subtraía o estoque local imediatamente.
- Construía **duas mensagens distintas**: uma com foco na logística e produção (`_montarMensagemNovoPedidoFabrica`) e outra com foco no recibo do cliente (`_montarMensagemNovoPedidoCliente`).
- Enviava **dois disparos de WhatsApp em sequência**, primeiro para o número fixo da lanchonete (cozinha) e depois para o número do cliente (com normalização de DDI).
- Instanciava um `Pedido` em memória local e limpava o carrinho.

---

## 2. Matriz de Comparação e Decisões

| Capacidade | Lanchonete Pro | Quentinhas Pro | Status Atual | Decisão |
| ---------- | -------------- | -------------- | ------------ | ------- |
| **CEP e Endereço** | Chamada HTTP direta na UI, `_logradouro.text`. | Serviço próprio (`CepService`), Modelo `EnderecoEntrega`. | 🔵 Melhorado | Manter arquitetura limpa. |
| **Taxa e Tipos** | Strings "ENTREGA" e `taxaEntregaFixa`. | Enums Fortes, invariantes no `PedidoDraft`. | 🔵 Melhorado | Manter validação de domínio. |
| **Cliente / Telefone**| Normalização do telefone antes de enviar, DDI automático. | `ClienteContato`, mas **perdemos o DDI automático e a normalização robusta**. | 🔴 Perdida | **Recuperar** normalização. |
| **Formas Pagamento** | Permitia marcar se precisa de troco e calculava a diferença. | Tem Enum `FormaPagamentoDraft`, mas **perdemos a lógica de "Troco Para" e seu cálculo**. | 🔴 Perdida | **Recuperar** cálculo de troco. |
| **Mensagens** | Templates distintos (1 para Fábrica, 1 para Cliente). | Um único template de mensagem. **Perdemos a comunicação interna pra Cozinha.** | 🔴 Perdida | **Recuperar** o conceito de mensagem de operação (Fábrica) e recibo (Cliente). |
| **Disparo (WhatsApp)**| 2 envios em cadeia: `whatsappLanchonete` e `pedido.telefoneCliente`. | 1 único envio no `finalizarDraft()`. | 🔴 Perdida | **Recuperar** suporte para múltiplos despachos (Operação e Cliente). |
| **Estoque** | Abatia do estoque em memória imediatamente. | Removido do Mock UI temporário, passará para a *Transition Engine* / Banco. | 🟡 Adaptado | Transferido para backend futuramente. |

---

## 3. Análise Detalhada

### 🔴 O que perdemos e precisamos recuperar:
1. **Lógica de Troco em Dinheiro:** O sistema antigo possuía um input `_trocoPara`, validava se o valor entregue era maior que o total, e computava `valorTrocoCalculado` colocando isso na mensagem do WhatsApp para facilitar o motoboy.
2. **Envio Duplo (Comunicação de Cozinha e Recibo de Cliente):** O aplicativo operava como um centralizador que disparava o pedido para a *própria Lanchonete/Fábrica* e depois enviava um comprovante para o *Cliente*. Atualmente, o Quentinhas Pro só constrói uma mensagem e dispara uma vez.
3. **Normalização de Telefone:** A função `_normalizarTelefoneWhatsApp` forçava o código do país (`55`) caso o número estivesse incompleto, o que é crítico para o funcionamento confiável da URL Scheme `https://api.whatsapp.com/send`.

### 🔵 O que melhoramos:
1. A transição de um formulário solto na UI para o `PedidoDraft` garantiu que pedidos que não façam sentido (Retirada cobrando Taxa de Entrega) jamais cheguem aos canais de envio.
2. A separação em `CepService` e o construtor isolado de mensagens (`WhatsAppMessageBuilder`) limparam a visão da UI (TelaCheckoutMock), tornando o app sustentável.

## 4. Conclusão Final

**"O Quentinhas Pro preservou, melhorou ou perdeu alguma capacidade importante do motor de pedidos do Lanchonete Pro?"**

*Melhorou significativamente* a segurança dos dados e a arquitetura visual, **mas PERDEU** capacidades funcionais cruciais de negócio:
- Cálculo do troco.
- Normalização internacional de celular.
- O roteamento do pedido para a Cozinha (*Envio Duplo*).

**Recomendação Técnica Imediata:** Não devemos avançar para o Supabase (EOS-005) ainda. Devemos executar uma missão de reparo arquitetural (`EOS-004.7.2`) para:
1. Inserir a variável de `trocoPara` no `PedidoDraft` (e a UI correspondente).
2. Criar `normalizarTelefone` no domínio do Cliente.
3. Expandir o `WhatsAppMessageBuilder` para `montarTicketCozinha` e `montarReciboCliente`.
4. Atualizar o Checkout para disparar ambas as mensagens em sequência, restabelecendo a operação completa legada.
