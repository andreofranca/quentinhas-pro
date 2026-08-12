# Decision Log

Este documento rastreará as principais decisões arquiteturais tomadas durante o projeto para evitar perda de contexto.

---
```text
DEC-000
Título: Congelamento do baseline e adoção de EOS

Decisão:
O estado atual do `prj_lanchonete` é documentado e a mudança de escopo (Lanchonete -> Comida Caseira) segue regras estritas de transição (Transition Engine). O código não será deletado até ter o equivalente novo testado.

Motivo:
Evitar refatorações infinitas e garantir patrimônio tecnológico, utilizando papéis claros: Sponsor (Decisão), Arquiteto (Estratégia), Agente (Execução).

Status:
APROVADA

Decisores:
Sponsor (Usuário), ChatGPT (Estrategista), Antigravity (Agente)
```
