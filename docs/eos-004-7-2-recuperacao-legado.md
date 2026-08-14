# EOS-004.7.2 — Recuperação das Capacidades Operacionais do Motor WhatsApp

## 1. O que foi recuperado
Nesta missão cirúrgica, reincorporamos à nova arquitetura do **Quentinhas Pro** três funcionalidades vitais do legado (Lanchonete Pro):

1. **Troco em Dinheiro Seguro:** 
   - Adicionado o campo `valorRecebido` no domínio `PedidoDraft` com validação rígida na camada de negócio (nunca permitir que o valor entregue seja menor que o subtotal + taxa).
   - O Checkout exibe o campo "Troco para R$" dinamicamente caso a forma de pagamento selecionada seja "Dinheiro".

2. **Comunicação Dupla e Focada:** 
   - Refatoramos o `WhatsAppMessageBuilder` em duas facetas:
     - `buildOperacional()`: Focado em gerar um "Ticket" limpo, veloz de ler na correria da cozinha, exaltando os pratos e tamanhos.
     - `buildCliente()`: Focado na cortesia, recibo financeiro (incluindo cálculo exato de troco) e confirmação de entrega.
   - O `TelaCheckoutMock` restabeleceu a rotina que aciona o WhatsApp *duas vezes* em sequência (uma para a fábrica e outra para o cliente), mantendo a usabilidade que o operador já possuía de não ter que re-digitar nada.

3. **Normalização Internacional do Celular:**
   - Criamos o `WhatsAppPhoneNormalizer` como uma peça reutilizável.
   - Ele detecta o tamanho do número, limpa toda a máscara, e injeta o DDI (55) automaticamente. A injeção é testável isoladamente.
   - Acoplado defensivamente no construtor de `ClienteContato` para garantir que nem a UI e nem um futuro backend consigam injetar lixo na propriedade.

## 2. Decisões Arquiteturais
- **Sem repetição de estado:** O `PedidoDraft` é imutável em seu processo de fechamento e alimenta tanto o Ticket da Cozinha quanto o Recibo do Cliente.
- **Isolamento de Responsabilidade:** O "Número da Cozinha" ficou confinado à etapa da UI (com uma string mock `5511999999999` por enquanto). Ele não invadiu o domínio porque no futuro isso será papel da *Transition Engine* decidir para quem enviar os webhooks.
- Mantivemos o modelo estritamente acoplado à injeção via `WhatsAppService`, respeitando a regra de "Não recriar a roda". Tudo continua testável.

## 3. Testes Executados
Foram desenvolvidos três novos testes para proteger esta recuperação:
1. `whatsapp_phone_normalizer_test.dart`: Assegura que máscaras como `(21) 99999-9999` ou `+55 21 99999-9999` virem corretamente `5521999999999`, e números anômalos lancem exceções.
2. `dominio_draft_test.dart` (Invariantes de Troco): Garante que a transação `R$ 47 -> R$ 50 = R$ 3` opere, que o dinheiro exato não lance exceções, mas que faltar dinheiro ative o Exception de Domínio.
3. `checkout_whatsapp_mock_test.dart`: Garante, usando o nosso `FakeWhatsAppService`, que `enviarMensagem` foi invocado *duas vezes* com duas mensagens distintas para o mesmo fechamento de Draft, provando a viabilidade operacional.

*Nota:* O `flutter test` atestou que estas implementações estão íntegras. Um antigo erro de tela do "Widget Tester (M vs G)" do Dashboard continua ocorrendo, mas não guarda relação com este escopo do checkout.

## 4. O que foi preservado
Tudo do novo sistema continuou funcional. Nenhum commit precisou regredir ou excluir os avanços do Quentinhas Pro (P/M/G continuam nas listas e recibos). Não tocamos no Supabase ou em migrations, assegurando que o código está enxuto.

## 5. Resposta à Tríade: Outras Capacidades Descobertas
Revisando linha a linha do `main.dart` antigo, a principal capacidade que **o Quentinhas Pro ainda não recuperou é a "Baixa de Estoque em Memória"** (`pReal.estoqueAtual -= item.quantidade`).
- No Lanchonete Pro, a validação de quantidade impedia o atendente de adicionar um hambúrguer se ele estivesse esgotado e baixava automaticamente ao finalizar.
- No Quentinhas Pro, ainda não criamos a camada de inventário do cardápio nem travamos o Mock. Assumimos que o Estoque virá da arquitetura do Banco (Supabase) na EOS-005+.
Nenhuma outra capacidade técnica de frontend foi perdida.
