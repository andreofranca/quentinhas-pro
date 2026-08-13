# Correções Controladas (EOS-003.3.1)

## 1. RLS — Resolução do Default Deny
**Problema:** A Migration 005 ativava o RLS nas 14 tabelas, mas não definia Políticas (`CREATE POLICY`), bloqueando totalmente o banco para os usuários via Flutter.
**Causa:** Estratégia de "Default Deny" inserida no script original, mas deixada vazia, assumindo que as políticas seriam criadas num escopo futuro.
**Correção:** Foram geradas políticas refinadas de RLS utilizando o mecanismo Role Based Access Control (RBAC) amarrado à tabela `perfis`.
**Arquivo Alterado:** `20260812000005_seguranca_rls.sql`
**Impacto:**
- `authenticated` recebe direito de leitura (SELECT) em tabelas públicas (Cardápio, Ofertas, Produtos).
- Regras separadas garantem que apenas ADMIN/GERENTE possam gerir o catálogo e o estoque.
- Atendentes e Caixas possuem direitos focados em Pedidos e Caixas, mas não podem alterar perfis e estoque livremente.
- O problema de recursão infinita no RLS de `perfis` foi sanado permitindo a leitura base por `auth.role() = 'authenticated'`.

## 2. Proteção de Quantidades
**Problema:** O RPC de reserva `rpc_reservar_oferta_atomica` permitia `p_quantidade` negativa.
**Causa:** Falta da "cláusula guardiã".
**Correção:** Inserção do bloco `IF p_quantidade <= 0 THEN RETURN FALSE; END IF;` no RPC. Além disso, foram adicionadas *Constraints* `CHECK (quantidade > 0)` em `itens_pedido` e `>= 0` nos estoques (`ofertas.reservado_atual`, `limite_producao`).
**Arquivo Alterado:** `20260812000002_caixas_pedidos.sql` e `20260812000005_seguranca_rls.sql`.
**Impacto:** Garantia absoluta no banco contra manipulação ilícita de cota por exploração de subtração numérica.

## 3. Valores Monetários (Monetary CHECKs)
**Problema:** Totais e subtotais podiam receber valor negativo.
**Causa:** Ausência do `CHECK` aritmético explícito.
**Correção:** Inserção de `CHECK (subtotal >= 0)`, `CHECK (total >= 0)`, `CHECK (preco_unitario >= 0)` e `CHECK (valor > 0)` na tabela de pagamentos (pois não há pagamento nulo). Tipos garantidos como `DECIMAL(10,2)`.
**Arquivo Alterado:** `20260812000002_caixas_pedidos.sql` e `20260812000003_pagamentos.sql`.
**Impacto:** O banco passa a rejeitar na raiz qualquer lançamento contábil destrutivo, sem sobrepor as regras de negócio da *Transition Engine*, atuando como última linha de defesa estrutural.

## 4. Máquina de Estados (Status Limits)
**Problema:** Status abertos como `TEXT` sem barreiras.
**Causa:** Omissão da constraint explícita.
**Correção:** Inclusão de `CHECK (status_operacional IN ('RASCUNHO', 'CONFIRMADO', 'EM_PRODUCAO', 'PRONTO', 'SAIU_ENTREGA', 'ENTREGUE', 'CANCELADO'))` na Transition Engine (tabela pedidos), alinhando aos termos do domínio definidos na pauta, entre outros CHECKs inseridos para Status Financeiro e Caixas.
**Arquivo Alterado:** `20260812000001_fundacao.sql`, `20260812000002_caixas_pedidos.sql`, `20260812000003_pagamentos.sql`.
**Impacto:** Restringe firmemente o leque de nomenclaturas no DB, permitindo ao código de frontend ter garantias contratuais de que não receberá enumerações anômalas vindas do backend. A Ordem (Rascunho -> Confirmado) segue a cargo da API Backend (Edge Function).

## 5. Validação Pós-Correção
As 5 migrations foram revisadas para garantir que não houvessem referências quebradas nem operações destrutivas como `DROP TABLE`.
Nenhuma Migration foi executada contra a base. Supabase permanece Intocado. O legado foi preservado conforme mandato da Tríade.
