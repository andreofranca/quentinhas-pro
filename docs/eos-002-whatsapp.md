# Engenharia Reversa do WhatsApp (EOS-002.1)

Em cumprimento à missão, investiguei todo o código relacionado a WhatsApp no repositório `prj_lanchonete`.

## 1. Fluxo Atual Encontrado
A solução atual no `main.dart` **não é um bot de atendimento (Inbound)**, mas sim um **Mecanismo de Notificação (Outbound)**. 
- Quando o caixa (atendente no Flutter) fecha um pedido, o sistema aciona a função `_enviarMensagensNovoPedido`.
- A função gera textos formatados usando templates como `_montarMensagemNovoPedidoCliente` e `_montarMensagemNovoPedidoFabrica`.
- O Flutter usa o pacote `url_launcher` para abrir a URL `https://api.whatsapp.com/send?phone=...` com a mensagem pré-preenchida no aplicativo oficial do WhatsApp no celular/computador do atendente.
- A classe `ResultadoNotificacaoWhatsApp` salva booleanos `enviadoFabrica` e `enviadoCliente`, baseados apenas no sucesso de abrir a URL, e não na confirmação de entrega do Meta.

## 2. Classificação de Componentes para o Novo Fluxo

| Componente | Classificação | Justificativa |
| :--- | :---: | :--- |
| **`url_launcher` (Abrir App Local)** | **SUBSTITUIR** | O modelo novo exige interação programática (Cloud API) para receber mensagens (Inbound), não apenas abrir o app no celular do dono. |
| **Templates de Mensagem (`_montarMensagem...`)** | **REUTILIZAR** | Os geradores de texto de confirmação, resumo de itens, cálculo de troco e formatação são excelentes e podem ser reusados para o Bot responder ao cliente. |
| **`ResultadoNotificacaoWhatsApp`** | **ADAPTAR** | Será evoluído para rastrear os `message_ids` dos Webhooks da Cloud API e monitorar status reais (Entregue/Lido). |
| **Fluxo Conversacional (Bot)** | **NOVO** | Precisamos construir a árvore: `Identificar Cliente -> Cardápio -> Tamanho -> Quantidade -> Carrinho`. |
| **Parser de Carrinho -> Draft** | **NOVO** | Lógica para converter mensagens/botoes do WhatsApp em um objeto `Draft`. |

## 3. Integração com a Nova Transition Engine
A arquitetura aprovada prevê o WhatsApp operando **fora** da engine de persistência direta.

1. **Atendimento:** O cliente interage com os menus do WhatsApp.
2. **Carrinho:** O estado local do canal WhatsApp acumula: `1x Frango Assado (MÉDIA), 1x Carne (PEQUENA)`.
3. **Checkout Bot:** O cliente envia "Confirmar e Pagar".
4. **Draft:** O canal injeta um `Draft` na Domain Engine.
5. **Validação e Transition:** A Domain Engine verifica se ainda há Frango Assado `MÉDIA` no `Cardápio do Dia`. Se sim, cria o `Pedido` e entra em `RASCUNHO -> RECEBIDO`. Se não, devolve erro para o Bot avisar o cliente.
