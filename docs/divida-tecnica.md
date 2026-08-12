# Dívida Técnica (Baseline)

## 1. Monolito `main.dart`
O arquivo `main.dart` acumula muita responsabilidade. Ele contém a inicialização do app, classes de modelos Mock, lógica de UI, roteamento, estado efêmero e validação de regras de negócio.
- **Impacto:** Alta dificuldade de manutenção, quebra frequente se modificado, conflitos de merge.
- **Resolução Exigida:** Modularização (divisão em pastas `screens/`, `widgets/`, `controllers/`).

## 2. Mock vs Persistência
Boa parte das telas de Pedido/Caixa funcionam apenas visualmente com Listas em memória.
- **Impacto:** Falsa sensação de funcionalidade concluída. Perda de dados.
- **Resolução Exigida:** Implementação do módulo real no backend.

## 3. RLS Desprotegido
O Supabase está com RLS aberto para todas as operações (`USING (true)`).
- **Impacto:** Qualquer pessoa com a URL e Anon Key pode deletar ou modificar o banco inteiro.
- **Resolução Exigida:** Implementação de Auth no app e políticas de RLS amarradas ao usuário logado (`auth.uid()`).
