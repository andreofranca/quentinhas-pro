# Benchmark UX: Auditoria do Legado de WhatsApp e Localização (EOS-004.2.1)

Esta auditoria mapeia o que a base de código herdada do *Lanchonete Pro* (presente no `lib/main.dart` legado) possui em relação aos requisitos do novo fluxo do *Quentinhas Pro*, evitando reconstruir rodas e preservando créditos/tempo.

## 1. Matriz de Capacidades: Lanchonete Pro vs Quentinhas Pro

| Capacidade | Lanchonete Pro | Quentinhas Pro | Ação | Justificativa Baseada em Evidências |
| :--- | :--- | :--- | :--- | :--- |
| **WhatsApp (Core)** | Existente | Parcial | 🟢 REUTILIZAR | O legado usa `url_launcher` e `https://api.whatsapp.com/send` muito bem estruturado (`_abrirConversaWhatsApp` no `main.dart`). A infra local está pronta para uso. |
| **Templates** | Existente | Parcial | 🟡 ADAPTAR | O legado tem strings hardcoded (`_gerarMensagemNovoPedidoCliente`, etc.). A mecânica será reutilizada, mas os textos e marcações precisam ser adaptados para o domínio de Quentinhas e linkados aos status da Transition Engine. |
| **CEP / ViaCEP** | Existente | Futuro | 🟢 REUTILIZAR | Encontrado `CepInputFormatter` e a função `_buscarCEP()`. O legado já faz preenchimento automático. |
| **Endereço (Forms)** | Existente | Mock | 🟡 ADAPTAR | Campos `logradouro`, `numero`, `complemento`, `bairro` estão espalhados na UI legada. Extrairemos para um componente dedicado de *Delivery*. |
| **Geolocalização (GPS)** | Ausente | Futuro | 🔵 NOVO | **Nenhuma evidência** de pacotes de Geolocator ou GPS no código fonte. Endereço é 100% textual. |
| **Mapas (Google Maps)** | Ausente | Futuro | 🔵 NOVO | **Nenhuma evidência** de Google Maps SDK implementado. A arquitetura de mapas terá que ser construída do zero caso a regra de negócio exija no futuro. |
| **Entrega (Delivery)** | Existente | Domínio Novo | 🟡 ADAPTAR | O modelo atual de `Pedido` tem os campos `tipoEntrega` e `taxaEntrega`. Serão adaptados para o novo padrão de faturamento. |
| **Pedido Draft** | Conceitual | Existente | 🟠 REFAZER | O modelo antigo mistura o estado do Carrinho com a Notificação do Zap de forma insegura. Consolidaremos via *Domain Engine*: a UI gera o Draft e ele vaza para todos os canais (WhatsApp, Balcão) por igual. |

## 2. Decisão Arquitetural sobre Mapas
Foi constatado que o Lanchonete Pro não possuía **nenhuma integração de mapas ou geolocalização**. Toda a entrega era baseada em "Ler o texto do Endereço". 
* **Recomendação para o Quentinhas Pro:** Manteremos o padrão textual usando o motor de CEP nativo herdado. Integrar Google Maps/GPS agora adicionaria custos pesados de API e complexidade sem agregar valor imediato para o MVP de balcão de quentinhas. O motoboy pode clicar no texto do endereço no próprio WhatsApp para abrir o Waze/Maps dele.

## 3. O Checkout Ideal (Benchmark LOVABLE vs Legado)
Baseando-nos na orientação do PO, o fluxo consolidado no novo Quentinhas Pro funcionará da seguinte forma:

1. **Carrinho (`TelaCheckoutMock`) -> Botão Avançar**
2. **Resumo do Pedido:** Visão limpa dos itens (P/M/G).
3. **Logística:** Seleção Condicional:
   - Se *Retirada no Balcão*: Pede apenas Nome e Telefone.
   - Se *Entrega*: Pede CEP -> Autopreenchimento -> Complemento e Número.
4. **Pagamento:** (PIX, DINHEIRO com troco, CARTÃO, PENDENTE).
5. **Ação Final -> WhatsApp:** O botão "CONFIRMAR" gera o Draft do pedido no banco de dados e imediatamente abre o aplicativo nativo do WhatsApp do atendente/loja, com a mensagem formatada para disparo, sem precisar de APIs pagas (WhatsApp Cloud API) neste momento.

## Conclusão: "Quanto do sistema antigo aproveitamos?"
**Aproveitamos praticamente toda a infraestrutura "difícil" sem custo de reescrita.** 
Não precisaremos reinventar (1) a máscara de campos, (2) a consulta de CEP e (3) o motor de injeção de links do WhatsApp. Eles estão maduros no legado. Nosso trabalho real agora é apenas envelopar isso dentro do **novo Design System** (EOS-004.1) em um fluxo de *wizard* de checkout linear e agradável.
