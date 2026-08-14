# Auditoria Visual e de UX (EOS-004.0)
**Produto:** Quentinhas Pro (Evolução do Lanchonete Pro)

## 1. Estado Visual Atual
O aplicativo atual de interface (Flutter) encontra-se em um estágio de **monólito técnico e conceitual**. 
* **Monólito Técnico:** Quase todas as telas e lógicas de UI (`TelaDashboard`, `TelaCardapioCliente`, `TelaLogin`, etc.) estão comprimidas em um único e massivo arquivo `lib/main.dart` (mais de 166 KB e 3000 linhas).
* **Herança Conceitual:** As telas carregam o viés do "Lanchonete Pro", cujo modelo mental é a venda de "Produtos de Catálogo" (ex: Hamburguer, Coca-Cola) e não "Refeições Variáveis/Pratos do Dia" por tamanho (Pequena, Média, Grande).
* **Navegação:** A navegação ocorre por empilhamento padrão ou substituição simples no `main.dart`, sem roteamento avançado separado (GoRouter ou equivalentes).

## 2. Inventário das Telas (Localizadas no `main.dart` e `screens/`)
* `PainelTesteCompleto` (Acesso Admin/Dev)
* `TelaLogin` (Autenticação)
* `TelaDashboard` (Home Operacional)
* `TelaCardapioCliente` (Catálogo/Balcão)
* `TelaCheckoutExpresso` (Pagamento Rápido/Carrinho)
* `TelaGestaoPedidos` (Acompanhamento/Cozinha)
* `TelaRelatoriosFinanceiros` (Caixa e Performance)
* `TelaControleEstoqueRapido` e `teste_estoque_screen.dart` (Gestão de Cozinha)
* `TelaGestaoProdutos` / `TelaCadastroProduto` (Gestão de Catálogo)
* `TelaGestaoEquipe` / `TelaCadastroUsuario` (Gestão de Perfis)

## 3. Matriz de Componentização (Quentinhas Pro)

| Tela / Fluxo | Classificação | Justificativa |
| :--- | :--- | :--- |
| **DASHBOARD** | 🟠 REFAZER | O `TelaDashboard` atual é genérico. O novo precisa ter como centro nervoso o *Cardápio do Dia* e as vendas/estoque do almoço de hoje. |
| **CARDÁPIO DO DIA** | 🔵 NOVO | Não existia. O fluxo agora é montar o que tem pra hoje (Prato + Tamanho + Limite) e não apenas listar o menu fixo. |
| **PRATO + TAMANHO** | 🔵 NOVO | A mecânica de seleção do tamanho da quentinha (P, M, G) afeta diretamente estoque e precificação, diferindo da lógica antiga de produtos simples. |
| **PEDIDO / WHATSAPP** | 🟠 REFAZER | O antigo `TelaCheckoutExpresso` lidava com balcão. Precisamos refazer para abraçar os status da *Transition Engine* e os links amigáveis com integração ao WhatsApp. |
| **PRODUÇÃO (Cozinha)** | 🟡 ADAPTAR | A `TelaGestaoPedidos` pode ser adaptada para um "Kanban de Quentinhas", mostrando agrupamentos rápidos (ex: "Faltam 5 Frangos G"). |
| **CAIXA / FINANCEIRO** | 🟡 ADAPTAR | A base financeira de `TelaRelatoriosFinanceiros` é boa. Precisa apenas absorver o conceito de status financeiro (Pendente/Pago) e múltiplos caixas (`terminal_id`). |
| **ESTOQUE** | 🟢 REUTILIZAR | A fundação legada foi mantida no DB. As telas de Controle de Estoque (`TelaControleEstoqueRapido`) servem de excelente alicerce e só requerem pequenos ajustes nas fichas técnicas. |
| **EQUIPE / LOGIN** | 🟢 REUTILIZAR | A autenticação e CRUD de usuários atende perfeitamente ao RLS de Perfis criado nas migrations de DB. |

## 4. Principais Problemas de UX e Gargalos
1. **Falta de Foco em "Venda Rápida" (Rush Hour):** Uma loja de quentinhas tem fluxo agressivo entre 11h30 e 13h30. O App não pode exigir muitos "cliques" para registrar uma Quentinha Média de Frango Assado. O checkout atual é lento.
2. **Separação de Ofertas:** O cliente não vê o catálogo inteiro, ele vê "O que tem pra hoje". A UI atual expõe o estoque, não as "Ofertas do Dia".
3. **Código Espaguete:** Manter a UX no arquivo `main.dart` torna iterações de design (A/B, microinterações) extremamente arriscadas.
4. **WhatsApp:** O fluxo de WhatsApp parece restrito a "Notificações" (enviar mensagem no despacho), em vez de "Gestão de Conversa/Funil" onde o cliente pede e o sistema gera o Draft rápido no balcão.

## 5. Proposta de Arquitetura Visual
* **Quebrar o Monólito:** Mover cada classe de Tela para arquivos dedicados (`lib/screens/`).
* **Design System Minimalista e Apetitoso:** Uso de Vanilla Flutter limpo, substituindo interfaces densas de ERP por *Cards* responsivos e *Touch-Friendly* para Tablets no balcão.
* **Layout Fluido:**
  - *Tablet / Balcão:* Visão Split (Cardápio à esquerda, Carrinho Fixo à direita).
  - *Mobile / Cozinha:* Visão Vertical (Cards de pedidos em fila).
* **Tipografia e Cores:** Adotar fontes modernas (ex: Poppins, Roboto) com contraste claro, substituindo cinzas pálidos por *Ações Primárias* de alto contraste para não errar o clique na correria.

## 6. Próxima Missão Recomendada
A próxima missão estratégica deve ser dupla:
**Desmonte do Monólito Visual + Criação da Primeira Tela Nativa:**
Propomos refatorar o `main.dart`, fatiando-o nos subdiretórios padrão, para em seguida criarmos do zero o **Dashboard / Cardápio do Dia** com a linguagem visual moderna. Assim, começamos a visualizar de fato o *Quentinhas Pro* antes de tocarmos na conexão real com o Supabase.
