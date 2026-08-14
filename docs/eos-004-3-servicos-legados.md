# Documentação de Extração de Serviços Legados (EOS-004.3)

Este documento atesta a extração limpa das capacidades lógicas de WhatsApp e Endereçamento do Lanchonete Pro para serviços modernos no Quentinhas Pro.

## Origem no Legado e Desacoplamento

**1. WhatsApp**
*   **Código Legado (`main.dart`):** `_abrirConversaWhatsApp`, `_montarMensagemNovoPedidoCliente`, etc., que uniam UI, estado (`setState`) e geração de string num arquivo só.
*   **Código Descartado:** Toda a mecânica de misturar strings com UI e pop-ups de confirmação hardcoded.
*   **Código Reaproveitado e Adaptado:** A mecânica do `url_launcher` para invocar o App do WhatsApp e a sanitização de telefone foram encapsulados no novo `WhatsAppUrlLauncherService`.
*   **Novos Contratos:** A interface estrita `WhatsAppService.enviarMensagem(...)` isola o Domínio. No futuro, se passarmos a usar a API Cloud, criaremos um `WhatsAppCloudService` que obedece à mesma interface, sem alterar nenhuma linha do pedido.
*   **Message Builder:** As formatações de string foram ejetadas para um arquivo puramente utilitário `utils/whatsapp_message_builder.dart`, testável sem contexto de Flutter.

**2. CEP e Endereço**
*   **Código Legado (`main.dart`):** `_buscarCEP` misturava `http.get`, tratamento de JSON e updates de múltiplos `TextEditingControllers` simultâneos.
*   **Código Reaproveitado e Adaptado:** A lógica do ViaCEP e da chamada `http` foram isoladas em `CepService.buscarCep`. Essa classe retorna um objeto limpo `EnderecoEntrega` que a UI pode assinar onde quiser. O modelo `EnderecoEntrega` foi enriquecido para já contar com slots opcionais e inativos de `latitudeFutura` e `longitudeFutura`.
*   **Formatadores Reutilizados:** `CepInputFormatter` e `NumeroEnderecoFormatter` extraídos e postos à disposição sem alterações bruscas.

## Testes Realizados
Criamos e rodamos testes de unidade (`servicos_legados_test.dart`) provando que:
- O novo modelo de `PedidoDraft` consegue alimentar o gerador de mensagens do WhatsApp e produzir as strings finais de *Retirada* (sem endereços e sem taxa) e *Entrega* (com endereços estruturados e somatório de subtotal + taxa de entrega) de forma 100% determinística.
- Os masks de input (como `01001-000`) funcionam isoladamente.
- Não foi preciso utilizar nenhum Widget Test pesado.

## Riscos Mitigados
- **Economia de Créditos e Redução de Dívida:** Cumprimos a ordem em passe único. A extração poupou milhares de linhas de retrabalho na `main.dart` e impediu a propagação da dívida técnica para a nova arquitetura do Quentinhas Pro. Não reconstruímos os inputs de CEP na mão, aproveitamos do legado.
- A decisão firme da tríade de segurar a integração de mapas poupou um desvio drástico de arquitetura e verba de API do Google neste sprint.
