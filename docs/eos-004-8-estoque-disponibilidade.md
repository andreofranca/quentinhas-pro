# EOS-004.8 — Modelo Operacional de Disponibilidade e Estoque

Este documento atesta a consolidação da etapa **EOS-004.8**, responsável por implementar a visualização e controle de disponibilidade mockado (estoque comercial), garantindo que as lógicas legadas do Lanchonete Pro sejam recuperadas com a modelagem do Quentinhas Pro, preparando terreno para a integração do banco de dados e da Transition Engine.

## 1. Classificação de Capacidades

### 🟢 Reutilizado do Lanchonete Pro
- **Bloqueio visual de produto esgotado:** Botões desativados para evitar inserção equivocada de itens sem estoque.
- **Prevenção de Carrinho:** O domínio continua exigindo validação de disponibilidade no fechamento.
- **Baixa de Estoque:** Ao confirmar um pedido, os itens consumidos abatem imediatamente o limite operacional de sua visualização no Cardápio (neste MVP, implementado como `consumir()`).

### 🟡 Adaptado
- **Controle granular por Tamanho:** No legado, a baixa ocorria no "Produto Principal" inteiro. Agora, o Quentinhas Pro gerencia cada embalagem (P/M/G) de forma isolada. Se P acaba, M e G continuam livres.
- **Visualização da Indisponibilidade:** O preço continua visível na tela mesmo quando esgotado (agora com opacidade `0.4`), além da tag vermelha "[ESGOTADO]". O operador sabe exatamente quanto custaria e por que o cliente não pode pedir.
- **Disponibilidade Ilimitada (Null):** Diferente do legado que podia ter estoques como `9999`, nosso `TamanhoOpcao` admite a propriedade `int? quantidadeDisponivel`. O uso de `null` denota controle comercial livre (infinito operacional), não interferindo em produtos sob demanda contínua.

### 🔵 Novo
- **Invariante de Domínio Estrito (`quantidadeDisponivel < quantidade`):** O `PedidoDraft` passou a verificar matematicamente a profundidade do estoque na hora de aprovar a intenção de pedido. Tentar inserir mais itens do que o disponível mockado aborta a operação pela raiz.

### 🔴 Ainda dependente do Supabase (Transition Engine)
- **Ficha Técnica e Fatores Reais:** Não criamos lógicas de consumo do tipo "G consome 1,33 do panelão de Arroz". No Flutter, um prato G apenas abate `1` do seu próprio estoque comercial `G`. O cálculo logístico dos ingredientes de bastidor será governado pelo banco/RPC futuramente.
- **Garantia Transacional (Concorrência):** O Flutter não é confiável para "última unidade vendida junta". A UI exibirá o bloqueio, mas o backend (Supabase RPC) será o juiz definitivo.

## 2. Implementação Técnica Mockada
As seguintes modificações viabilizaram a etapa:
1. `TamanhoOpcao`: Geração das propriedades base `quantidadeDisponivel` e método `consumir(int)`.
2. `PedidoDraft`: Adição da regra de limite na função `validar()`.
3. `TelaCheckoutMock`: Após a construção da validação do Mock, a UI itera e consome o array.
4. `CardOfertaQuentinha`: UI responsiva desenhada de acordo com as especificações exigidas.

## 3. Conclusão da Missão
O sistema passou a simular, provar e interagir visualmente com as variáveis limitadoras e estoques locais através de mocks injetáveis na UI. Toda suíte de testes automáticos do Dashboard, Invariantes e Mock de WhatsApp foi adequadamente revisada, corrigindo warnings pontuais e acoplando injeção de dependência via fake services onde apropriado.

**Pergunta do PO:** *"O modelo de disponibilidade do Quentinhas Pro está pronto para receber a Transition Engine real?"*
**Resposta:** **Sim.** Não há lacunas ou dependências faltantes na modelagem do domínio. A intenção (`PedidoDraft`) está rigidamente protegida e validada na interface operacional de concorrência. Estamos plenamente preparados para ligar o banco (EOS-005).
