# EOS-005.3 — Identificação e Validação do Supabase Cloud

## 1. Objetivo
Identificar e auditar com precisão o projeto oficial "Quentinhas Pro" na nuvem do Supabase, certificando seu estado estrutural (project_ref, organização, banco existente) antes de qualquer etapa destrutiva (link, push ou migrations).

## 2. Auditoria de Autenticação (CLI Supabase)
A CLI do Supabase foi autenticada com sucesso utilizando o Personal Access Token fornecido pelo PO.
```text
{"message":"You are now logged in."}
```

## 3. Varredura de Projetos na Conta
O comando `npx supabase projects list` foi executado para listar os ambientes disponíveis na organização.

**Resultado Observado:**
```json
{
  "projects": [
    {
      "id": "tlpfusvvypkmggyxjbrw",
      "ref": "tlpfusvvypkmggyxjbrw",
      "organization_slug": "cpprvmiuxkmqbuuuxhsr",
      "name": "lanchonete-controle",
      "region": "sa-east-1",
      "status": "INACTIVE"
    }
  ]
}
```

## 4. Diagnóstico Estrutural
- **Projeto Quentinhas Pro:** NÃO ENCONTRADO.
- **Projetos Existentes:** O único projeto acessível à conta neste momento é o `lanchonete-controle` (o sistema legado original).
- **Risco Crítico Identificado:** Se usarmos esse projeto, iremos rodar migrations destrutivas (ou colisões) sobre a base do sistema anterior, ferindo a regra de isolamento da Transition Engine.

## 5. Conformidade com as Diretrizes
Em estrita obediência à regra de parada da EOS-005.3 ("*Não criar projeto, não vincular e não improvisar*" e "*Não tocar no prj_lanchonete*"), **nenhuma ação estrutural foi tomada**. O laboratório local não foi vinculado a lugar nenhum e as migrations Cloud estão travadas.

## 6. Veredito e Próximos Passos
**🔴 NO-GO**

A infraestrutura Cloud destino ainda **não existe** na conta do Supabase autenticada.

**Ações Requeridas do PO:**
1. Acessar o Dashboard web do Supabase (https://supabase.com/dashboard).
2. Criar um novo projeto limpo (ex: `quentinhas-pro`) sob a organização `cpprvmiuxkmqbuuuxhsr` (ou outra de sua escolha).
3. Aguardar o provisionamento do banco terminar.
4. Sinalizar para retomarmos a identificação.
