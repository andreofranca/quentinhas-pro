# Auditoria Completa e Matriz de Transformação

## Matriz de Transformação
Com base na análise do repositório original para o novo escopo "ERP Comida Caseira":

```text
MATRIZ DE TRANSFORMAÇÃO

Ingredientes                → REUTILIZAR
Ficha Técnica               → REUTILIZAR
Auditoria (Estoque)         → REUTILIZAR
Produtos                    → ADAPTAR (Categoria precisa suportar "Cardápio Diário")
Usuários                    → SUBSTITUIR (Mock -> Supabase Auth)
Autorização                 → SUBSTITUIR (Mock -> RLS no Supabase)
UI de Caixa                 → ADAPTAR (Dividir tela e conectar com backend)
Fluxo de Pedido             → NOVO (Criar Transition Engine real)
WhatsApp Integration        → NOVO (Cloud API)
```

## Considerações do Agente
A base de estoque está bastante sólida e deve ser isolada e preservada. A base de interface pode ser parcialmente salva extraindo os Widgets para arquivos separados, mas a lógica de estado interna deve ser deletada a favor de um padrão definitivo (ex: Bloc ou Provider).
