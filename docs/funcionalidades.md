# Funcionalidades (Baseline)

## 1. Cadastro e Gestão de Produtos e Ingredientes
- **Telas:** Interface de visualização, criação e edição de ingredientes e produtos.
- **Funcionamento:** Salva diretamente no banco Supabase.

## 2. Controle de Estoque
- **Telas:** Telão geral de `teste_estoque_screen.dart`.
- **Funcionamento:** Exibe o estoque atual e custo unitário.
- **Auditoria:** Grava histórico automático.

## 3. Ponto de Venda / Operação (Protótipo)
- **Telas:** Tabs 1. COZINHA, 2. CAIXA, 3. CONCLUÍDOS, 4. CANCELADOS.
- **Funcionamento:** Fluxos existem visualmente, mas operam sem backend, apenas em memória.

## 4. Controle de Funcionários (Protótipo)
- **Telas:** `TelaCadastroUsuario`.
- **Funcionamento:** Cadastro local na sessão atual (mock). Permite criar e ativar/desativar funcionários. Validação de senha para admin.
