# PROTOCOLO DE EXECUÇÃO CONTROLADA (EOS-003.4)

Este documento estabelece o protocolo estrito de engenharia e segurança para a migração física do projeto *Quentinhas Pro* no ambiente de banco de dados (Supabase). **A execução cega de todas as migrations em bloco está expressamente proibida.**

---

## 1. PRÉ-CHECK (Verificação Obrigatória Pré-Migration)
Antes de disparar qualquer instrução DDL, o executor deve obrigatoriamente checar e documentar:
- **Projeto Supabase Correto:** O comando CLI `supabase status` ou a URL do projeto aponta para o ambiente exato (Desenvolvimento/Homologação/Produção) de *Quentinhas Pro* (ou *Lanchonete Pro* legado, se for o caso).
- **Schema Atual:** Verificar se as tabelas legadas já existem (`ingredientes`, `produtos`, `itens_ficha_tecnica`, `movimentacoes_estoque`).
- **Extensões Ativas:** Confirmar presença da extensão `pgcrypto` (para UUIDs se necessário) ou funções nativas do PostgreSQL.
- **Policies / RLS Atuais:** Inspecionar se o Legado já possui políticas soltas que conflitem com as regras a serem dropadas na *Migration 005*.
- **Dados Existentes:** Garantir que o DDL proposto não encontra violação com dados legados existentes (ex: FK sem `ON DELETE` seguro).

---

## 2. PRESERVAÇÃO DO LEGADO
- **Garantia de Zero DROP Destrutivo:** Nenhuma tabela base da Lanchonete Pro original será apagada (`ingredientes`, `produtos`, `itens_ficha_tecnica`, `movimentacoes_estoque`).
- **Integridade Relacional:** As FKs criadas pelas novas migrations (ex: `regras_porcionamento.produto_id` e `ofertas.produto_id`) não afetam as regras de leitura originais, mas protegem contra deleção acidental via `ON DELETE RESTRICT` ou `CASCADE` apropriado.

---

## 3. PROTOCOLO DE BACKUP
Nenhuma migração será iniciada sem backup recente e validado.
- **O que preservar:** Schema completo `public` e dados contidos em tabelas. Dados de `auth.users` também devem ser backupeados logicamente se houver contas reais.
- **Como gerar backup:** Pelo painel do Supabase (Database Backups) ou via CLI: `supabase db dump --data-only > backup_data.sql` e `supabase db dump > backup_schema.sql`.
- **Como validar:** Inspecionar o tamanho e legibilidade do `.sql` gerado.
- **Como restaurar:** Executar o `.sql` de dump via SQL Editor ou ferramenta CLI, caso as operações de Rollback Lógico falhem.

---

## 4. INJEÇÃO DE AUTH / ADMIN (SEED SEGURA)
Como a *Migration 005* institui um RLS estrito (Default Deny e Auth Baseado em Perfil), a migração em banco zerado causará "Lockout" (Ninguém consegue criar perfis porque criar perfis requer perfil ADMIN).
- **Procedimento:**
  1. Cria-se o usuário no Supabase Auth via Frontend ou CLI de Seed.
  2. Extrai-se o UUID de `auth.users`.
  3. Insere-se manualmente via *SQL Editor (Superuser)* na tabela `perfis`:
     `INSERT INTO perfis (id, role) VALUES ('<UUID_COPIADO>', 'ADMIN');`
- **Regra:** Não criar *Bypass* permanente (ex: desativar RLS provisoriamente) para gerar o primeiro usuário. Inserir manualmente via Superuser (Database Provider).

---

## 5. ORDEM DE EXECUÇÃO
1. **001 (Fundação):** Cria infraestrutura base (`perfis`, `clientes`, `cardapios`, `ofertas`).
2. **002 (Caixas e Pedidos):** Acopla transações sobre a Fundação.
3. **003 (Pagamentos):** Acopla controle financeiro sobre os pedidos.
4. **004 (Auditoria):** Cria *append-only* log.
5. **005 (RLS e RPC):** Ativa Segurança e *Transition Engine*.

---

## 6. ESTRATÉGIA DE EXECUÇÃO INCREMENTAL
O processo não usará `supabase db push` em bloco.
1. Executar a **Migration N** individualmente.
2. Validar o **Sucesso** (Checar banco).
3. Efetuar **Testes** locais.
4. Sinalizar **Checkpoint** para a Tríade.
5. Avançar para a **Migration N+1**.

---

## 7. MATRIZ DE TESTES
A cada checkpoint, testar:
- Inserções manuais de FK.
- Restrições *CHECK* numéricas (tentar forçar preços negativos).
- Segurança RLS (logar com `ATENDENTE` e tentar deletar um pedido).
- Bloqueio de `<= 0` na *RPC* de *Lock* de Ofertas.
- Idempotência (injetar duplo evento idêntico simulando WhatsApp).
- Garantia de fechamento da Tríade: `Prato x Tamanho` operando no `Cardápio Diário`.

---

## 8. ESTRATÉGIA DE ROLLBACK
- **Rollback Lógico:** Cria-se o arquivo SQL de `DOWN` ou executa-se comandos destrutivos inversos pontuais. (Ex: Executar `DROP TABLE pagamentos;` se apenas a Migration 003 falhar e não contiver dados).
- **Restauração de Backup:** Acionada somente se os dados legados sofrerem corrupção.

---

## 9. CRITÉRIOS DE ABORTAMENTO DA OPERAÇÃO (KILL SWITCH)
A migração deve ser abortada imediatamente e comunicada ao *Arquiteto* e ao *PO* se:
- `banco incorreto`: O CLI não aponta para o branch correto.
- `tabela ausente`: Uma dependência da migration não foi encontrada.
- `conflito` ou `erro de constraint`: Registros originais violando restrições novas (ex: Nulos em locais `NOT NULL`).
- `erro de RLS`: A Migration 005 rejeita a aplicação.
- `erro de RPC`: Erro de sintaxe `PLPGSQL`.
- `divergência de dados`: Após a migração, a aplicação original falha ao ler o legado.
