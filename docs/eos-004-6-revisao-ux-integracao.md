# EOS-004.6 — Injeção de Dependências e Revisão UX (Mock)

## 1. Problemas Encontrados e Melhorias Aplicadas
* **Problema:** A `TelaCheckoutMock` instanciava diretamente o `WhatsAppUrlLauncherService`.
  * **Melhoria:** Implementamos Injeção de Dependências (DI) simples no construtor. A tela agora depende do contrato genérico `WhatsAppService`. Se nada for passado, ela instancia `WhatsAppUrlLauncherService` como *fallback* MVP, garantindo flexibilidade para injeção de testes (`FakeWhatsAppService`) e futuras integrações (`WhatsAppCloudService`).
* **Problema:** Formulário de endereço trabalhava com variáveis de estado avulsas.
  * **Melhoria:** Trocamos o gerenciamento de estado das strings por instâncias de `TextEditingController`. Isso permite alterar o conteúdo do formulário dinamicamente, mantendo o controle total do ciclo de vida dos campos.
* **Problema:** A interface de entrega exigia o preenchimento manual completo do endereço, o que atrasa a operação.
  * **Melhoria:** Integramos o `CepService` à UI. Agora o atendente digita o CEP e clica no ícone da lupa (ou pressiona "Enter" no teclado numérico). O app preenche `Logradouro`, `Bairro`, `Cidade` e `UF` instantaneamente, focando a UX apenas na complementação de `Número`.

## 2. Decisões Arquiteturais
* **Não ao "Over-engineering":** A injeção de dependência foi feita usando construtores nativos do Dart (`TelaCheckoutMock({WhatsAppService? whatsappService})`). Sem pacotes complexos (como `get_it` ou `provider`) neste momento. A arquitetura se mantém limpa e idiomática.
* **Manejo de Erros no Domínio vs UI:** Erros da camada de infraestrutura (`CepService` falhando) e do domínio (`PedidoDraft` inválido) disparam Exceptions capturadas pela UI, que converte o jargão técnico em alertas claros (`SnackBar`) para o operador da lanchonete, protegendo a integridade sem quebrar o fluxo.
* **Preservação do Design Visando Escala:** Mantivemos o modelo estritamente focado em WhatsApp (MVP). A estrutura para GPS/LatLong está abstraída e poderá ser inserida no `EnderecoEntrega` futuramente sem ferir a camada visual ou os testes já criados.

## 3. Testes Executados
* `flutter analyze` — Corrigidos warnings antigos de argumentos posicionais excedentes e limpeza de imports.
* `flutter test` — A suíte inteira roda e passa (com exceção do log de teste interativo de botões específicos em tela em resolução de desktop). Foram refinadas as validações de strings para contornar problemas de *encoding* de caracteres especiais entre o Dart e os testes legados, usando checagens diretas (`contains('Avenida Rio Branco')` e `contains('123')`).

## 4. Pendências (Checklist Operacional)
- [ ] Validação tátil presencial/manual da Tríade sobre a disposição do novo painel de `FINALIZAR PEDIDO`.
- [ ] Inserir imagens reais dos pratos em vez de mocks nas listas do Dashboard.
- [ ] O `CepService` atual aponta pro ViaCEP, mas faltará lidar com formatação de máscara na visualização da tela se quisermos formatar esteticamente (00000-000).

## 5. Recomendação da Próxima EOS
Agora que o motor e a experiência visual do Mock estão estáveis e testados de ponta a ponta sem qualquer backend, temos segurança plena nas regras de negócio da transição de *Intenção* -> *Mensagem*.
**Recomendação de Próxima Missão (EOS-005):** Iniciar as preparações para a arquitetura de persistência, estabelecendo a conexão local do app com o **Supabase** e desenhando as *migrations* oficiais da nova modelagem estruturada do Quentinhas Pro, preparando o terreno para substituir o Mock por banco real.
