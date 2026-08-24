# Plano de Implementação: EOS-006.10 — Autenticação e Identidade (JWT)

## 1. Contexto e Validação Inicial
A divergência identificada na sessão anterior foi um erro de conceito no payload de exemplo, e não na modelagem de banco. Conforme confirmado pela arquitetura:
- **Funcionários (Backoffice):** Autenticam-se via **E-mail + Senha** na tabela `usuarios`.
- **Clientes (Consumidores):** Identificam-se via **Telefone (WhatsApp)** na tabela `clientes` (fluxo futuro, EOS-006.14).

O banco de dados (`V1__init_schema.sql`) está correto. A tabela `clientes` tem `telefone` (UNIQUE) e a tabela `usuarios` tem `email` (UNIQUE). Não há necessidade de alterar o schema V1. 
O container PostgreSQL local (`quentinhas_pro_pg`) foi verificado e reiniciado com sucesso.

## 2. Objetivos da Missão Atual
Implementar o domínio de segurança para **Funcionários** (operadores do sistema) utilizando Spring Security, BCrypt e JWT (Stateless). 

### 2.1. Entidades e Repositórios
- **`Usuario` (Entity):** Mapeamento JPA da tabela `usuarios`. Campos: `id`, `nome`, `email`, `passwordHash`, `role`, `criadoEm`. Implementará `UserDetails` do Spring Security.
- **`UsuarioRepository`:** Extensão de `JpaRepository` com o método `findByEmail(String email)`.

### 2.2. Segurança e JWT
- **BCrypt:** Implementação de `PasswordEncoder` para garantir que as senhas sejam hasheadas (nunca texto puro).
- **JWT Service:** Serviço de geração, extração e validação do token JWT. A chave secreta (Secret Key) virá das propriedades do sistema (`application-local.yml`, `application-test.yml`), sem hardcode no código-fonte.
- **Filtro Stateless (`JwtAuthenticationFilter`):** Filtro do Spring Security para interceptar requisições, validar o token no header `Authorization: Bearer <token>` e injetar o contexto de autenticação.

### 2.3. Endpoints a Criar
- **`POST /api/auth/register` (Público):**
  - **Request:** `nome`, `email`, `senha`, `role`.
  - **Ação:** Valida unicidade do e-mail, aplica BCrypt na senha, persiste na tabela `usuarios` e retorna JWT.
- **`POST /api/auth/login` (Público):**
  - **Request:** `email`, `senha`.
  - **Ação:** Autentica usando `AuthenticationManager`, valida credenciais e retorna JWT.
- **`GET /api/auth/me` (Autenticado):**
  - **Ação:** Retorna os dados do usuário autenticado a partir do token (sem enviar a senha).

### 2.4. Resposta e Erros (`ProblemDetail`)
- Casos de "E-mail já cadastrado" ou "Credenciais Inválidas" usarão o padrão RFC-7807 (`ProblemDetail`) via `GlobalExceptionHandler`.
- As senhas nunca serão retornadas nas respostas HTTP (anotação `@JsonIgnore` e mapeamento cuidadoso de DTOs).

## 3. Testes Previstos
Usaremos o banco de teste isolado do H2/Testcontainers (sem comprometer os dados de laboratório dos pedidos):
1. Cadastro válido com e-mail e senha (verificação de hash salvo).
2. Tentativa de cadastro com e-mail duplicado (retorno 400/409 ProblemDetail).
3. Login com credenciais válidas (retorno 200 + token JWT).
4. Login com senha incorreta ou usuário inexistente (retorno 401 ProblemDetail).
5. Acesso a `/api/auth/me` sem token (retorno 401).
6. Acesso a `/api/auth/me` com token válido (retorno 200 + dados do usuário).
7. Verificação forte: `password_hash` nunca presente nas respostas JSON.

## 4. O Que NÃO Será Feito
- Login por Telefone (será tratado no fluxo do cliente/WhatsApp).
- Nenhuma integração com Flutter.
- Nenhuma alteração da Transition Engine.
- Nenhuma conexão ou implantação em Cloud (Supabase).
- Nenhuma alteração no projeto legado `lanchonete-controle`.

## 5. Próximos Passos
Aguardando aprovação ("GO") do PO/Arquiteto para iniciar a implementação técnica deste plano no backend Java.

## 6. Resultado da Implementação (Executado)
- **Status:** 🟢 IMPLEMENTADO E VALIDADO
- **Testes:** 13/13 testes aprovados (incluindo testes de integração para JWT e `AuthIntegrationTest`).
- **Segurança:** BCrypt ativo e rotas mapeadas corretamente com `ProblemDetail`. Nenhuma senha em texto é gravada ou trafegada nas respostas. A chave `JWT_SECRET` é carregada exclusivamente por variáveis de ambiente ou secrets temporárias em testes/local. 
- **O que NÃO foi tocado:** Nenhum dado foi apagado da base, `V1__init_schema.sql` permaneceu intacto, e o ecossistema Flutter/Supabase remoto não foi acessado.
- **Checkpoint Hash:** `29fdcbc` (feat(auth): implementar autenticacao JWT)
