# EOS-006.13.1 - Caixa Ativo (Auditoria e Planejamento)

## 1. Auditoria da Tabela `caixas` e Relacionamentos

A tabela `caixas` define a gestao de turnos financeiros do sistema, criada no `V1__init_schema.sql`.

**Estrutura atual:**
- `id` (UUID, PK)
- `operador_id` (UUID, FK -> `usuarios(id)`)
- `terminal_id` (TEXT, default 'CAIXA_BALCAO')
- `aberto_em` (TIMESTAMPTZ)
- `fechado_em` (TIMESTAMPTZ, nullable)
- `status` (TEXT, check: 'ABERTO' ou 'FECHADO')
- `saldo_inicial` / `saldo_informado` (DECIMAL)

**Regras Inerentes Identificadas:**
1. A constraint `idx_caixa_unico_aberto_terminal` garante que um `terminal_id` so pode ter um caixa com `status = 'ABERTO'` por vez.
2. O `operador_id` assegura a trilha de auditoria: quem foi o usuario logado que abriu e responde pelo turno.

## 2. Desenho da Nova Rota `GET /api/caixas/ativo`

**Objetivo:** Obter o caixa aberto sob a responsabilidade do usuario logado (obtido pelo JWT), sem expor a seguranca ou permitir consultar caixas arbitrarios.

**Fluxo Backend (Spring Boot):**
1. O filtro JWT autentica a requisicao e preenche o `SecurityContext` com a entidade `Usuario`.
2. O `CaixaController` mapeia `GET /api/caixas/ativo`.
3. Assinatura: `public ResponseEntity<CaixaResponse> getAtivo(@AuthenticationPrincipal Usuario currentUser)`
4. A query (Spring Data JPA) busca na tabela: 
   `SELECT * FROM caixas WHERE operador_id = :userId AND status = 'ABERTO' LIMIT 1;`
5. Se nao encontrar nada, retorna **HTTP 404 Not Found**. O Flutter sabera que devera avisar o usuario para abrir um caixa (fluxo futuro) ou trataremos esse erro provisoriamente (já que a abertura ainda não está pronta).
6. Se encontrar, retorna **HTTP 200 OK** com o DTO:
```json
{
  "id": "uuid-do-caixa",
  "terminal_id": "CAIXA_BALCAO",
  "aberto_em": "2026-08-25T10:00:00Z",
  "status": "ABERTO"
}
```

## 3. Adesao as Regras da Trade
- **Identificar operador via JWT:** Satisfeito via `@AuthenticationPrincipal`.
- **Retornar apenas o caixa aberto do usuario:** Satisfeito pelo Repository filter `operador_id` + `status = 'ABERTO'`.
- **Nunca aceitar `caixaId` no request:** A rota e um simples `GET`, sem parametros (exceto o bearer token implcito).
- **404 se nao houver:** A logica preve a exception mapeada para `404 Not Found`.
- **Sem alteracao de estoque:** Satisfeito, endpoint estritamente de leitura (Idempotente / Safe).
- **Sem alteracao no Flutter:** O Flutter permanece intocado nesta fase.
- **Sem dummy data:** A implementacao consultara a tabela oficial. Testes injetarao via banco em memoria (`@Sql` ou transacional).

---
**STATUS DESTE CHECKPOINT:** REVIEW ONLY. O codigo nao foi gerado. Aguardando a aprovacao para disparar a implementacao destas entidades, repository e controller.

## Checkpoint de Implementacao
- Classes implementadas e package validado. Testes validados com sucesso com PostgreSQL online.

