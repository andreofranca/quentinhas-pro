# Estratégia de Migração Incremental (EOS-003)

O banco de dados não sofrerá `DROP SCHEMA`. A evolução deve ser feita anexando o novo modelo ao modelo existente.

## Fase 1: Preservação e Adequação do Passado
As seguintes tabelas serão mantidas e receberão apenas *ALTER TABLE*:
- **`ingredientes`:** Intacta.
- **`produtos`:** Mantida.
- **`itens_ficha_tecnica`:** Mantida.
- **`movimentacoes_estoque`:** Mantida.

## Fase 2: Instalação das Novas Dependências Base
- Criação de `regras_porcionamento` (Ligada à `produtos`).
- Criação de `clientes`.
- Criação de `cardapios`.
- Criação de `ofertas` (Ligada a `cardapios` e `produtos`).

## Fase 3: Instalação do Subdomínio Transacional (Pedidos e Pagamentos)
- Criação de `caixas`.
- Criação de `pedidos`.
- Criação de `itens_pedido`.
- Criação de `pagamentos`.

## Fase 4: Migração de Permissões e Segurança
- `DROP POLICY` de todas as regras `USING (true)`.
- Instalação das RPC Functions (para Atomic Locks de reserva de oferta e fechamento).
- `CREATE POLICY` vinculada ao Supabase Auth.

*Com essa estratégia, nenhum dado histórico (como o cadastro atual de ingredientes) será perdido.*
