# Checkpoint: Fundação Visual e Domínio do Quentinhas Pro (EOS-004)

Este documento sumariza o estado do projeto após a conclusão das missões da série EOS-004 (Foco em Interface e UX Operacional), estabelecendo um ponto de restauração seguro antes da integração com o Backend (Supabase) e extração de serviços legados.

## 1. Estado Visual e UX

A interface principal foi inteiramente focada na velocidade do balcão:
*   **Cardápio como Protagonista:** Os pratos são cards com botões gigantes para cada tamanho `[ P ]`, `[ M ]`, `[ G ]`.
*   **Um Toque:** Adicionar um item ao carrinho leva apenas 1 toque na tela principal, sem modais ou seletores dropdown.
*   **Split-View Responsiva:** Em resoluções maiores que 800px (Tablets/Desktops de Caixa), o carrinho fica permanentemente visível à direita.
*   **Gestão de Estoque:** Tamanhos esgotados ficam desabilitados individualmente (esgotamento parcial). Se todos os tamanhos acabarem, o card inteiro bloqueia (esgotamento total).

## 2. Modelos de Domínio

O domínio local foi atualizado para isolar o "Quentinhas Pro" das regras complexas do Lanchonete Pro:
*   `TamanhoOpcao`: Define preço e disponibilidade (estoque) a nível de embalagem.
*   `ItemCarrinhoQuentinha`: Registra a intenção de compra.
*   `PedidoDraft`: Nova estrutura (EOS-004.2.2) desenhada para não instanciar um *Pedido* definitivo no frontend. O checkout preenche o *Draft*, que será enviado à *Transition Engine* (banco de dados/Supabase) para virar um pedido real.
*   `EnderecoEntrega`: Preparado textual, mas já contendo slots inativos para `latitudeFutura`, `longitudeFutura` e `precisaoGpsFutura`, deixando a porta aberta para Google Maps/Geolocator no futuro, sem inflar custos agora.

## 3. Fluxo de Checkout (Mock)

A `TelaCheckoutMock` linearizou o processo de conclusão da venda:
*   **Painel Esquerdo (Input):** Coleta Dados do Cliente, WhatsApp e Tipo de Logística.
*   **Painel Direito (Recibo):** Mostra Subtotal, Taxa de Entrega Dinâmica e seletor de Pagamento (PIX, Dinheiro, Cartão).
*   **Condicional de Entrega:** O formulário de Endereço (CEP, Logradouro, Número, etc.) só aparece na tela se o `TipoEntrega` for selecionado como "Entrega". Para "Retirada no Balcão", a tela limpa o fluxo exigindo apenas Nome e WhatsApp.

## 4. Auditoria do Legado (WhatsApp e CEP)

Foi decidido que **o legado será reutilizado** e não jogado fora.
O que já temos e extrairemos na próxima fase (EOS-004.3):
*   **WhatsApp:** O `_abrirConversaWhatsApp` usa nativamente `url_launcher` e já suporta envio formatado.
*   **CEP:** A classe `CepInputFormatter` e a API local já fazem o autocomplete do ViaCEP.
*   **Endereço:** Manteremos o padrão textual atual, sem Google Maps.
*   **Templates de Mensagem:** As strings de status do Lanchonete Pro serão adaptadas para os novos status da *Transition Engine*.

## 5. Pendências e Próximos Passos (Bloqueado por enquanto)

As seguintes tarefas estão mapeadas, mas aguardam ordens:
1.  **EOS-004.3 (Extração):** Criar `WhatsAppService` e `CepService` independentes do `main.dart`.
2.  **EOS-005 (Conexão Supabase):** Ligar os modelos locais (`PedidoDraft`) às *migrations* construídas na série EOS-003.

## 6. Decisões Consolidadas (Tríade)
*   **WhatsApp é um CANAL**, não um domínio.
*   **CEP é um SERVIÇO**, independente de Mapas.
*   **GPS e Mapas** não serão implementados nesta versão inicial.
*   O App nunca salva o Pedido direto. Ele empurra a intenção (`PedidoDraft`) para a base.
