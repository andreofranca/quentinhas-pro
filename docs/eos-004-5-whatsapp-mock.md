# Documentação: Fluxo WhatsApp Mock (EOS-004.5)

## Visão Geral do Fluxo Operacional
O fluxo principal do aplicativo foi conectado end-to-end em ambiente mock (sem Supabase). O ciclo de vida do pedido agora respeita rigidamente as fronteiras da nova arquitetura:

1. **Cardápio & Carrinho**: O usuário seleciona o prato e o tamanho. O carrinho atualiza quantidades.
2. **Checkout Mock**: A interface capta as informações de logística (Entrega/Retirada), identificação do cliente e endereço.
3. **Instanciação do PedidoDraft**: No clique de "FINALIZAR PEDIDO", a tela **não navega imediatamente**. Ela instancia o `PedidoDraft` em um bloco `try/catch`.
4. **Validação**: O `PedidoDraft.validar()` atua como barreira. Se houver falha, a UI exibe um `SnackBar` vermelho e não prossegue.
5. **Geração de Mensagem**: O modelo aprovado é repassado ao `WhatsAppMessageBuilder` para formatar o texto oficial.
6. **Despacho via Canal**: O texto e o telefone são enviados ao `WhatsAppService`.
7. **Sucesso**: O aplicativo emite um alerta de "WhatsApp acionado com sucesso!" e retorna `true` para a dashboard, limpando o carrinho.

## Tratamento de Erros e UX
A experiência do usuário foi polida para evitar incertezas e frustrações:
- O botão adquire o estado "ENVIANDO..." e se desabilita.
- Qualquer exceção de domínio interceptada tem o prefixo genérico removido e apresenta a regra clara ao atendente (ex: *"Não foi possível finalizar. Verifique os dados: Cliente e telefone são obrigatórios."*).
- Nenhuma falha limpa o carrinho ou redireciona a tela abruptamente. O atendente tem a chance de corrigir o erro e tentar novamente.

## Contratos
O Checkout não tem dependência com o `url_launcher`. A injeção de `WhatsAppUrlLauncherService` acontece via o contrato limpo da interface `WhatsAppService`. Para conectar ao WhatsApp Cloud futuramente, a única alteração ocorrerá dentro de uma `Dependency Injection`, mudando a subclasse concreta do serviço; o Checkout permanecerá intocado.

## Testes Realizados (`checkout_whatsapp_mock_test.dart`)
Criou-se o `FakeWhatsAppService` para interceptar as requisições do builder de string durante o teste, de modo a provar que os fluxos produzem as mensagens esperadas:
*   ✅ **Draft válido (Retirada):** Atestado que envia mensagem sem endereço, sem taxa e informa corretamente "Retirada no Balcão".
*   ✅ **Draft válido (Entrega):** Atestado que exige e formata o endereço corretamente, somando a taxa dinâmica no recibo.
*   ✅ **Draft inválido:** Atestado que a exceção é disparada no construtor do `PedidoDraft`, impedindo *qualquer* acionamento do serviço de comunicação mockado.

## Limitações do MVP e Próximas Evoluções
*   **Abertura vs. Confirmação:** O sistema considera o fluxo bem-sucedido na abertura do intent/URL do WhatsApp. Como não há webhook nem Cloud API neste momento, não existe rastreio se o cliente realmente apertou "Enviar" dentro do App de mensagens. Isso atende perfeitamente ao escopo da Lanchonete, mas a evolução preverá o Supabase como ponte de registro.
*   **Persistência:** Atualmente o `PedidoDraft` morre em memória após ser enviado para a formatação de WhatsApp. O próximo passo será interligá-lo à Transition Engine, que persistirá esse estado no PostgreSQL e tracionará a evolução dele para um Pedido Real em faturamento.
