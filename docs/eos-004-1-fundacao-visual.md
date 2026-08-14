# Fundação Visual e Dashboard do Dia (EOS-004.1)

Esta etapa estruturou a fundação visual orientada a **Quentinhas** (ofertas diárias em tamanhos) abstraindo os elementos necessários do monolítico `main.dart` legado sem destruí-lo.

## 1. Arquitetura Criada
A nova "casca" do Quentinhas Pro no Flutter foi estabelecida em subdiretórios corretos:
- `lib/theme/app_theme.dart`: Design System.
- `lib/models/models_quentinha.dart`: Domínio local mockado.
- `lib/widgets/card_oferta_quentinha.dart`: Componente central de oferta.
- `lib/widgets/carrinho_lateral_widget.dart`: Componente do fluxo de caixa.
- `lib/screens/dashboard/tela_dashboard_quentinhas.dart`: Nova Home do App.

O `main.dart` legado foi preservado (rotas e classes antigas não foram apagadas), mas o `AppLanchonete` passou a se chamar `Quentinhas Pro` com o novo *Theme* e a tela inicial foi injetada.

## 2. Decisões de UX Implementadas
* **Split-View Adaptativo:** O layout central prioriza telas largas (Tablet/Desktop no Balcão). O "Cardápio do Hoje" ocupa 2/3 da tela (Esquerda) e o Carrinho ocupa 1/3 (Direita), eliminando a necessidade de navegação em abas para fechar um pedido.
* **Touch Targets (Pílulas):** O selecionador de tamanho deixou de ser um *dropdown* invisível e virou um botão gigante `[ P ]`, `[ M ]`, `[ G ]` fixado no Card de cada prato. O atendente visualiza imediatamente o preço e a disponibilidade.
* **Zero Fricção (2 Clicks to Cart):** Para adicionar uma quentinha basta clicar na Pílula correspondente do prato. Ele entra no carrinho instantaneamente. Se clicar duas vezes na pílula, a quantidade no carrinho aumenta magicamente.

## 3. Modelos e Mock Data
A estrutura `models_quentinha.dart` não sujou os modelos antigos (`Produto`, `Pedido`). Criamos:
* `OfertaQuentinha` com uma lista interna de `TamanhoOpcao`.
* Dados Mockados de **Frango Assado, Bife Acebolado, Feijoada e Frango à Parmegiana**. 
* **Teste de Esgotamento:** A Feijoada `P` e o Frango à Parmegiana inteiro estão artificialmente `disponivel: false` no Mock. Na UI, eles perdem a cor, o botão do tamanho vira cinza "Esgotado", bloqueando o clique para simular proteção de estoque visual.

## 4. Evidências de Teste
O comando `flutter analyze` atestou ausência de erros de sintaxe nos novos arquivos.
O layout responsivo garante que se o App rodar no celular de um Atendente Móvel, o Carrinho (área direita) desaparece da Root e se converte em um botão Flutuante/Badge na AppBar que abre uma *Bottom Sheet*.

## 5. Próximos Passos
Após a consolidação e aprovação visual, as próximas missões lógicas seriam:
1. Começar a plugar a Autenticação Real do Supabase para entrarmos no app.
2. Preparar a Migration 001 do Supabase para fornecer os Cardápios / Ofertas diretamente do BD ao invés de dados Mocados.
