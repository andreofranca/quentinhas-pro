# CHECKPOINT OFICIAL — QUENTINHAS PRO
**MISSÃO:** `QP-CHECKPOINT-001`  
**DATA:** 15/10/2026  
**STATUS:** ⏸️ **PROJETO PAUSADO PARA TRANSIÇÃO DE WORKSPACE**  
**WORKSPACE:** `C:\Users\andre\desenv\desenvolvimento\quentinhas-pro`  
**BRANCH:** `main`  
**REPOSITÓRIO:** `https://github.com/andreofranca/quentinhas-pro.git`  

---

## 1. OBJETIVO DO CHECKPOINT

Salvar o estado consolidado, íntegro e testado do **Quentinhas Pro** no Git e GitHub, registrar as entregas e homologações realizadas e pausar com segurança os serviços locais para permitir a alternância de contexto para o projeto **Obra Fácil**, com isolamento absoluto e sem risco de contaminação cruzada.

---

## 2. STATUS DAS ENTREGAS RECENTES

| Missão | Escopo Principal | Status | Evidência / Validação |
|---|---|---|---|
| **QP-AUTH-001 / 002** | Autenticação, sanitização de e-mail e botões rápidos | 🟢 **HOMOLOGADA** | Login real com `admin@quentinhas.com.br` no Chrome e geração de JWT |
| **QP-COMERCIAL-003** | Catálogo, variação P/M/G, adicionais, carrinho e checkout | 🟢 **HOMOLOGADA** | Pedido `#QP-1018` persistido no PostgreSQL com adicional e pagamento em dinheiro com troco |
| **QP-COMERCIAL-004** | Ciclo operacional de pedidos e integridade de caixa e estoque | 🟢 **HOMOLOGADA** | Máquina de estados validada (`CONFIRMADO` → `EM_PRODUCAO` → `PRONTO` → `ENTREGUE`), rejeição de transições inválidas (400/422) e estoque inalterado em 35 |
| **QP-EVOLUCAO-001** | Plano estrutural de evolução (Financeiro, Estoque, UI e Dupla) | 🟢 **PLANEJADA** | Documento executivo formalizado em `docs/eos-007-plano-evolucao-estrutural.md` |

---

## 3. INTEGRIDADE TÉCNICA E SUÍTE DE TESTES

O projeto foi congelado em estado 100% verde:

- **Análise Estática (Flutter):** `flutter analyze` → 0 issues found.
- **Testes Automatizados Frontend:** `flutter test` → 59 de 59 testes aprovados.
- **Testes Automatizados Backend:** `.\mvnw test` → 54 de 54 testes aprovados (0 falhas, 0 erros).
- **Compilação Web:** `flutter build web` gerado com sucesso em `build/web`.
- **Banco de Dados Real:** 8 migrations Flyway aplicadas com sucesso no PostgreSQL `quentinhas_pro_pg` (porta 5440).

---

## 4. ALTERAÇÕES INCLUÍDAS NESTE CHECKPOINT

1. `lib/services/pedido_service.dart`: inclusão do mapeamento de `adicionaisIds` no envio do payload para `POST /api/pedidos`.
2. `backend/src/main/java/com/quentinhas/backend/service/PedidoService.java`: validação robusta da máquina de transições operacionais com switch expression, idempotência e bloqueio de alterações em pedidos finalizados.
3. `backend/src/test/java/com/quentinhas/backend/controller/PedidoIntegrationTest.java`: teste automatizado `testCicloOperacionalCompletoERejeicoes` cobrindo transições válidas, transições inválidas e não regressão de estoque.
4. `docs/eos-007-plano-evolucao-estrutural.md`: plano de evolução dos 10 itens prioritários para Financeiro, Estoque e Governança de equipe.
5. `docs/checkpoint-qp-001-pausa.md`: este registro formal de checkpoint e guia de retomada.

---

## 5. GUIA DE RETOMADA DO QUENTINHAS PRO

Para retomar o desenvolvimento do Quentinhas Pro no futuro:

### Passo 1 — Acessar o Workspace
```powershell
cd C:\Users\andre\desenv\desenvolvimento\quentinhas-pro
git status
```

### Passo 2 — Subir o Banco de Dados
```powershell
docker start quentinhas_pro_pg
```

### Passo 3 — Iniciar o Backend
```powershell
cd backend
.\mvnw spring-boot:run "-Dspring-boot.run.profiles=local"
```

### Passo 4 — Iniciar o Frontend Web
```powershell
node server_web.js
# Ou via flutter:
# flutter run -d web-server --web-port 3000
```

### Passo 5 — Primeira Missão a Executar
Iniciar pela missão **`QP-FINANCEIRO-001`** (conciliação matemática do caixa no backend + nova tela de frente de caixa com sangrias e suprimentos).

---

## 6. DECLARAÇÃO DE ISOLAMENTO

Nenhum arquivo ou dependência do projeto **Obra Fácil** foi lido, alterado ou afetado durante esta missão. O ambiente está 100% isolado e pronto para a troca de contexto.
