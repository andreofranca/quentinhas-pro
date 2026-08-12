# Arquitetura Atual (Baseline)

## Visão Geral
- **Linguagem:** Dart
- **Framework:** Flutter (Múltiplas plataformas: Web, Android, iOS, Windows, Linux, macOS).
- **Backend (BaaS):** Supabase (PostgreSQL, Auth, Storage).

## Padrões Encontrados
- **Monolito de UI/Logic:** O arquivo `main.dart` (aprox. 166KB) centraliza roteamento, gerenciamento de estado local (setState/variáveis globais) e telas mockadas (Caixa, Pedidos, Vendas).
- **Gerência de Estado:** Ausência de padrões robustos como BLoC, Riverpod ou Provider. O estado do frontend no momento é predominantemente local e in-memory.
- **Injeção de Dependências:** Parâmetros de ambiente (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) injetados via `--dart-define` em tempo de compilação.
- **Estrutura de Pastas:**
  - `lib/models/`: Modelos de dados anêmicos (Ingrediente, Produto, ItemFichaTecnica).
  - `lib/repositories/`: Classes de acesso a dados diretas (`EstoqueRepository`).
  - `lib/screens/`: Separação incipiente (`teste_estoque_screen.dart`), mas não aplicada ao fluxo principal.
