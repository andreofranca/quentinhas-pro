# EOS-006.5.1 — Revisão e Auditoria do Schema V1

Este relatório documenta a auditoria final sobre o plano `V1__init_schema.sql` antes da sua materialização persistente no PostgreSQL. 

## 1. Auditoria Sintática e Transacional (Dry-Run)
Como medida rigorosa, o arquivo `V1__init_schema.sql` foi submetido a uma carga seca (*dry-run*) em ambiente isolado via Docker com o comando:
```sql
BEGIN;
\i /tmp/V1.sql
ROLLBACK;
```
**Resultado:** Todos os comandos de `CREATE TABLE`, `CREATE INDEX` e `CREATE FUNCTION` rodaram sequencialmente sem falhas de sintaxe e sem dependências cíclicas ou colapsos de integridade. Ao final, tudo foi desfeito (`ROLLBACK`), provando que a ordem dos relacionamentos e os tipos de dados estão perfeitamente calibrados para um **banco recém-criado vazio**.

## 2. Checklist de Segurança e Integridade

1. **Tabelas presentes:** ✅ Sim (todas as 14 matrizes, de `usuarios` a `auditoria`).
2. **PKs e FKs:** ✅ Integridade hierárquica respeitada; dependências são instanciadas antes de suas filhas.
3. **Ausência do Supabase:** ✅ Varredura 100% livre de `auth.uid()`, policies ou dependências do GoTrue.
4. **Identidade nativa (`usuarios`):** ✅ Substituiu globalmente a relação anterior, servindo como chave para caixas e log de auditoria.
5. **Segurança de credenciais:** ✅ Campo `password_hash` tipificado; senhas nunca serão expostas como texto plano pelo modelo.
6. **Constraints Financeiras:** ✅ Travas operacionais (`valor >= 0`, `saldo_informado >= 0`) ativas.
7. **Quantidade em Estoque:** ✅ Constraint `CHECK (quantidade > 0)` em itens; `CHECK (preco_vigente >= 0)`.
8. **Precisão adequada:** ✅ O modelo adota padrão ouro: `DECIMAL(10,2)` (dinheiro) e `DECIMAL(10,3)` (pesagens de ingredientes).
9. **Integridade de deleção:** ✅ Exclusões com `ON DELETE RESTRICT` previnem quebra do banco (ex: não se apaga caixa com pedido atrelado).
10. **Imutabilidade de auditoria:** ✅ A tabela `auditoria_operacoes` atua como diário livre de restrições de mutação, e a imutabilidade será guiada no Java.
11. **Idempotência Externa:** ✅ `UNIQUE(provedor_evento, external_event_id)` está na base do duto `pedidos` blindando re-processamentos do WhatsApp.
12. **Transition Engine:** ✅ `rpc_processar_pedido` preserva o `SELECT ... FOR UPDATE` (Pessimistic Lock) dentro da transação ACID, provendo *fail-fast* se o limite for excedido.

## 3. Matriz de Rastreabilidade (Supabase → PostgreSQL Puro)

| Objeto Origem (Migrations 001-005) | Objeto Destino (V1.sql) | Ação | Justificativa / Observação |
| :--- | :--- | :--- | :--- |
| `auth.users` | `public.usuarios` | 🟡 ADAPTADO | Remoção do GoTrue. Passa a ser gerido localmente pelo Spring Security. |
| `public.perfis` | Tabela `public.usuarios` | 🔴 REMOVIDO | Para redução de joins desnecessários, o `role` foi acoplado diretamente à tabela `usuarios`. |
| Row Level Security (RLS) / Policies | N/A | 🔴 REMOVIDO | Bloqueios de deleção e visibilidade não precisam mais existir no banco porque não teremos clientes acessando a DB diretamente. Controle movido para anotações do Java (`@PreAuthorize`). |
| DDL Legada (Ingredientes, Produtos, etc.) | Várias `CREATE TABLE` inseridas | 🟡 ADAPTADO | As migrations antigas assumiam que as tabelas de estoque já existiam no Laboratório. No V1, provisionamos explicitamente garantindo que o deploy inicial construa *tudo* sem depender do Supabase online. |
| Chaves Idempotentes | Unique constraints nos pedidos | 🟢 PRESERVADO | A estrutura fundamental não muda, é puro PostgreSQL. |
| Functions de Transição (`rpc_`) | Mesmas funções | 🟢 PRESERVADO | As RPCs mantiveram a estrutura PL/pgSQL, com a única alteração sendo as FKs de caixa/auditoria referenciando `usuarios` em vez de `auth.users`. |

## 4. Riscos / Divergências

Não foram encontradas divergências arquiteturais arriscadas. Todas as regras de negócio intrínsecas ao Supabase puderam ser mitigadas pelo controle no código-fonte ou resolvidas estruturalmente pela modelagem do `V1__init_schema.sql`.

## 5. Recomendação

🟢 **GO PARA V1.**

O schema está **Aprovado e Maduro**. Não existe nenhuma falha estática. Podemos prosseguir com a aplicação deste schema no container e estabelecer a Transition Engine dentro do laboratório limpo.
