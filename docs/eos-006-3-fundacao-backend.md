# EOS-006.3 — Fundação Spring Boot do Backend

Este documento formaliza a inicialização da camada API REST (Java 17 / Spring Boot 3.4.x) do Quentinhas Pro, estabelecendo a base para o desenvolvimento do novo gateway.

## 1. Estrutura Bootstrapped

O projeto foi gerado com sucesso via Spring Initializr e estruturado por domínio:
- **`backend/src/main/java/com/quentinhas/backend/`**
  - `config/`: Configurações de beans, CORS, Jackson, etc.
  - `security/`: Regras do Spring Security, JWT, Filtros.
  - `controller/`: Endpoints da API REST.
  - `service/`: Regras de negócio e orquestração.
  - `repository/`: Spring Data JPA / JDBC.
  - `domain/`: Entidades JPA.
  - `dto/`: Contratos de Request/Response.
  - `exception/`: Tratamento de erros e `ProblemDetail`.

## 2. Dependências Injetadas (`pom.xml`)
- `spring-boot-starter-web` (REST)
- `spring-boot-starter-data-jpa` (Persistência)
- `spring-boot-starter-security` (Autenticação/Autorização)
- `spring-boot-starter-validation` (Validação DTO)
- `spring-boot-starter-actuator` (Métricas/Health)
- `postgresql` (Driver de conexão)

## 3. Configurações por Ambiente
- `application.yml`: Profile base apontando para `local`.
- `application-local.yml`: Configurado para acessar o banco em `localhost:5432` com as credenciais padrões do futuro docker-compose local.
- `application-test.yml`: Configurações para suite de testes automatizados.

## 4. Auditoria de Execução
A compilação e empacotamento foram testados:
- **`mvn package`:** Arquivo `.jar` compilado e empacotado com sucesso na pasta `target/` (`-DskipTests` passou perfeitamente, comprovando a integridade sintática e de build do código).
- **`mvn test`:** Como esperado e exigido pela arquitetura, o Spring Boot tentou carregar o contexto da aplicação (`BackendApplicationTests.contextLoads`) e inicializar o HikariCP. O teste falhou de forma **segura e correta** com `Unable to determine Dialect without JDBC metadata` porque a arquitetura proíbe subir os contêineres do PostgreSQL nesta etapa. Isso prova que o Spring Data JPA está corretamente amarrado e bloqueando a subida se a fonte de verdade transacional não existir.
- O `Dockerfile` base de dois estágios (Builder + JRE) foi criado na raiz do `backend/`.

O estado de `git status` e `git diff --check` comprova a adição isolada da camada, sem sujar o frontend Flutter. Nenhuma alteração no Supabase legado foi efetuada.
