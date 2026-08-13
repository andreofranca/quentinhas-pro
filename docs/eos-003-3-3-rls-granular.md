# Revisão RLS Granular e Proteção de Engine (EOS-003.3.3)

## 1. Vulnerabilidade e Causa
**Vulnerabilidade:** As políticas de Segurança (RLS) da *Migration 005* concediam escopos `FOR ALL` genéricos a papéis operacionais. Isso permitia na prática que Atendentes excluíssem `pedidos` ou alterassem colunas transacionais críticas como o `total` ou `status_operacional` burlando completamente o encapsulamento do domínio.
**Causa:** Utilização indiscriminada de `FOR ALL` ao invés da separação explícita das intenções por operação (`SELECT`, `INSERT`, `UPDATE`, `DELETE`).

## 2. Correção Adotada
A *Migration 005* foi completamente rescrita. A diretiva `FOR ALL` foi banida para operações de *front-end* e substituída por *Policies* granulares. 

### Princípios da Refatoração:
1. **Transition Engine Inquebrável:** A tabela `pedidos` **NÃO** possui mais a diretiva `FOR UPDATE` ou `FOR DELETE` habilitada para clientes do banco. Todo o fluxo do Flutter agora é obrigado a inserir (`INSERT`) o Rascunho, mas as transições de Status (Ex: RASCUNHO -> RESERVA -> PRODUCAO) serão orquestradas obrigatoriamente pelas RPCs do Backend (Transition Engine), que operam com a *Service Role* ou *Security Definer*, furando o RLS legitimamente.
2. **Imutabilidade Histórica e Financeira:** Tabelas como `itens_pedido`, `pagamentos`, `auditoria_operacoes` e `movimentacoes_estoque` tornaram-se formalmente **APPEND-ONLY** para a operação padrão. Não há policy de `UPDATE` e `DELETE` criada. O PostgreSQL (Default Deny) protegerá fisicamente qualquer mutação nestes artefatos.
3. **Segurança do RPC (Security Definer):** Adicionada a instrução `SET search_path = public` ao RPC para impedir ataques de Injeção de Path, seguindo o manual de melhores práticas do Supabase.

## 3. Matriz de Permissões Consolidada

| TABELA | SELECT | INSERT | UPDATE | DELETE | RPC Autorizada |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **perfis** | Authenticated | Admin | Admin | Admin | N/A |
| **cardapios** | Authenticated | Admin, Gerente | Admin, Gerente | Admin, Gerente | N/A |
| **ofertas** | Authenticated | Admin, Gerente | Admin, Gerente | Admin, Gerente | `rpc_reservar_oferta_atomica` |
| **clientes** | Operacional | Operacional | Operacional | Admin | N/A |
| **pedidos** | Operacional | Operacional | 🚫 DENY | 🚫 DENY | `confirmar_pedido`, etc |
| **itens_pedido** | Operacional | Operacional | 🚫 DENY | 🚫 DENY | N/A |
| **pagamentos** | Operacional | Operacional | 🚫 DENY | 🚫 DENY | N/A |
| **caixas** | Operacional | Operacional | Operacional | 🚫 DENY | `fechar_caixa`, etc |
| **estoque/fichas** | Operacional | Operacional | Cozinha, Admin | Admin | N/A |
| **auditoria_operacoes** | Admin, Gerente | Auth (Dono) | 🚫 DENY | 🚫 DENY | N/A |

*(Operacional engloba: Admin, Gerente, Atendente, Caixa, conforme necessidade setorial)*

## 4. Riscos Residuais
Com o RLS devidamente engessado, o Flutter se tornará **inoperante para avançar pedidos** enquanto a API/Backend de *Transition Engine* não for desenvolvida. As *RPCs* (ou Edge Functions) precisarão encampar o roteamento seguro de troca de estado (`status_operacional`), garantindo que o usuário tenha autorização na camada lógica. Isso é um ônus natural de sistemas resilientes e orientados a banco.

## 5. Validação
Foi realizada inspeção via regex local para banimento de sentenças `FOR ALL` ou `USING (true)` sem justificativa clara. Nenhuma tabela operacional expõe *GRANTs* ou *Policies* irrestritas de modificação. A cadeia de dependência das Migrations segue inalterada.
