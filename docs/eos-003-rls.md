# Estratégia de RLS e Segurança (EOS-003)

O problema fundamental reportado na EOS-001 (`USING (true)`) será sanado com a implementação real de Autenticação.

## 1. Mapeamento de Atores
- **Service Role (Supabase Edge Functions / Backend):** Terá privilégio de superusuário para contornar o RLS e injetar pedidos seguros (originados de Webhooks do WhatsApp).
- **Atendente / Admin (Flutter App):** Entrará via Supabase Auth. Terá a role local de controle da loja.
- **Cliente (WhatsApp):** Não toca o banco diretamente. Comunica-se com o Webhook.

## 2. Estratégia Base para RLS
Todas as políticas `USING (true)` atuais serão dropadas.
Uma nova política padrão será estabelecida para *todas* as tabelas operacionais:

```sql
-- Exemplo de restrição de leitura/escrita para funcionários
CREATE POLICY "Permitir acesso apenas a funcionários logados"
ON tabela_x
FOR ALL
USING (auth.uid() IN (SELECT user_id FROM perfis_funcionarios));
```
*(Nota: Para MVP Simplificado, pode-se usar apenas `auth.role() = 'authenticated'` exigindo login simples no app).*

## 3. Segurança Contra Exposição
- Como a *anon key* do Supabase ficará exposta no APK do Flutter, se um hacker tentar consultar o banco com ela, ele receberá uma resposta em branco (nenhuma permissão na RLS para usuários não logados). O banco estará protegido.
