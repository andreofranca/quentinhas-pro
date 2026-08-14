# PRE-FLIGHT E AMBIENTE DE TESTE (EOS-003.5)

## 1. Ambiente de Execução
* **Configuração Local:** O diretório `supabase/` armazena o *schema inicial* e as *migrations*, porém **NÃO contém um arquivo `config.toml`**. O projeto Supabase Local não está inicializado.
* **Projetos Remotos:** Não há mapeamento claro entre chaves locais e projetos remotos (`Produção` vs `Teste`).
* **Estado Atual:** Indefinido e cego.

## 2. Separação de Produção
🔴 **BLOQUEADOR CRÍTICO**
Não localizei configuração, variável de ambiente ou menção estrutural a um ambiente de homologação/teste (ex: um Supabase Project isolado). Sem uma barreira explícita (Testes X Produção), não improvisarei.

## 3. Checklist Pré-Flight (Pré-Migration)
No momento em que o ambiente for providenciado, é obrigatório validar:
- [ ] `supabase link --project-ref <ID_DO_TESTE>` configurado.
- [ ] Confirmação de conexão: `supabase status`.
- [ ] Confirmação visual das tabelas legadas no `public` (`ingredientes`, `produtos`, `itens_ficha_tecnica`, `movimentacoes_estoque`).
- [ ] Confirmação da extensão gen-random-uuid nativa no ambiente.

## 4. Backup e Rollback
- Gerar Snapshot: `supabase db dump --data-only > bkp_data.sql` e `supabase db dump > bkp_schema.sql` antes da Migration 001.
- Como o banco de teste estará livre de clientes reais, o rollback será feito via painel ou rodando scripts destrutivos inversos. (Não excluiremos dados do Legado).

## 5. Revisão da Migration 001
- **Objetos:** `perfis`, `clientes`, `regras_porcionamento`, `cardapios`, `ofertas`.
- **Relacionamentos:** `ON DELETE CASCADE` para objetos dependentes (Oferta morre com o Cardápio). `ON DELETE RESTRICT` preserva o legado (Oferta não deixa excluir Produto).
- **Checks:** Limites `IN` (Tamanhos: PEQUENA, MEDIA, GRANDE) e limites numéricos `>= 0` garantidos.
- É plenamente segura e idempotente se aplicada a um schema original.

## 6. Auth e Injeção de Admin (Seed)
A ativação do RLS bloqueará novas contas automáticas de admin via Flutter. O protocolo será:
1. Cadastrar usuário via `Authentication` no painel Supabase (Ambiente de Teste).
2. Capturar o UUID.
3. No SQL Editor do ambiente, rodar: `INSERT INTO perfis (id, role) VALUES ('<UUID>', 'ADMIN');`.

## 7. Testes Básicos de Fundação
Ao término da Migration 001:
- [ ] Criar um Cardápio via SQL (Sucesso).
- [ ] Ler tabela ofertas anonimamente via Flutter (Falha/401 esperada).
- [ ] Logar no Flutter com token de Admin, ler ofertas (Sucesso 200).
- [ ] Deletar um produto que está referenciado (Falha por FK Restrict).

## 8. Segurança e Segredos
⚠️ **VULNERABILIDADE DETECTADA NO GITIGNORE:**
O arquivo `.gitignore` ignora `dart_defines.local.json`, **mas não ignora explicitamente arquivos `.env` ou `supabase/.env`**. Precisaremos corrigir isso antes de configurarmos a CLI para evitar vazamento acidental de tokens e chaves de Service Role.

## 9. Critérios de Sucesso e Abortamento
- **Sucesso:** O banco de testes ecoa a fundação perfeitamente sem afetar Produção.
- **Abortamento Automático:** Erros de parser de SQL, falhas de RLS reverso ou falta de conexão isolada.

---

## Veredicto Final da Operação
🔴 **BLOQUEADO — AMBIENTE DE TESTE AUSENTE**

É imperativo que a Tríade ordene a criação ou o vínculo de um projeto Supabase específico para Testes. Não avançarei no gatilho de *Migrations* até que o laboratório seja fornecido.
