# EOS-006 — Arquitetura Backend e PostgreSQL Nativo (Java / Spring Boot)

Este documento registra a decisão arquitetural definitiva da Tríade: a migração do ecossistema Supabase para uma arquitetura profissional 3-Tier composta por **Flutter ↔ API REST (Java/Spring Boot) ↔ PostgreSQL Nativo**. 

A Transition Engine já validada será o coração do sistema no banco, enquanto o Spring Boot proverá uma camada robusta de segurança, orquestração e APIs para o cliente.

---

## Diagrama da Arquitetura

```text
[  App Flutter  ]   <-- JSON/HTTP (DTOs) -->   [ API Gateway / Load Balancer ]
 (Mobile / Web)                                           |
       |                                                  v
       |                                  [ Spring Boot Backend (Java 17+) ]
       |                                  |-- Spring Security (JWT, RBAC)
       |                                  |-- Spring Web (Controllers REST)
       |                                  |-- Domínios (Pedidos, Produtos, etc)
       |                                  |-- Spring Data JPA / JDBC
       |                                                  |
       |--------------------------------------------------|
                                                          v
                                        [   PostgreSQL 16 (Transition Engine)   ]
                                        |-- public.usuarios (Substitui auth.users)
                                        |-- rpc_processar_pedido()
                                        |-- Locks Pessimistas (FOR UPDATE)
                                        |-- Transações ACID
```

---

## Decisões Arquiteturais Detalhadas

### 1. Estrutura do Backend
Utilizaremos a arquitetura de camadas clássica do Spring (Hexagonal / Clean Architecture simplificada):
- **Controllers (Adapters):** Recebem requisições HTTP e devolvem JSON.
- **Services (Core):** Regras de negócio, autorização fina e orquestração de chamadas.
- **Repositories (Data):** Comunicação com o PostgreSQL via Spring Data JPA (entidades simples) e Spring JDBC (para invocar as RPCs e comandos transacionais complexos).

### 2. Módulos e Domínios
A aplicação será dividida em pacotes por domínio (Package by Feature):
- `com.quentinhas.auth` (Login, Token, Sessão).
- `com.quentinhas.pedidos` (Transition Engine, Carrinho, Status).
- `com.quentinhas.cardapio` (Produtos, Tamanhos, Ofertas).
- `com.quentinhas.pagamentos` (Caixa, Troco, Formas de pagamento).

### 3. Autenticação JWT
- **Spring Security** atuará como interceptador de requisições.
- A rota `/api/auth/login` validará as credenciais contra a tabela `public.usuarios` e retornará um JWT assinado pelo backend com um secret forte (HS256 ou RS256).
- O Flutter enviará o JWT no header `Authorization: Bearer <token>` em todas as rotas protegidas.

### 4. Autorização e RBAC (Role-Based Access Control)
- Substituiremos o RLS do Supabase por anotações de método do Spring: `@PreAuthorize("hasRole('GERENTE')")`.
- O papel (`role`) de cada usuário estará embutido no payload do JWT.

### 5. Acesso Transacional ao PostgreSQL
- As consultas de leitura e cadastros simples (CRUD de usuários, produtos) serão via `JpaRepository` com `@Transactional(readOnly = true)`.
- As operações complexas usarão o motor interno do banco, mantendo os `SELECT ... FOR UPDATE` já construídos e validados no laboratório.

### 6. Chamada Segura da Transition Engine
- O `rpc_processar_pedido` será chamado pelo Spring Boot através de `JdbcTemplate` ou `CallableStatement`.
- O payload JSON será validado e montado no Service do Java, repassando os dados com segurança. O Java gerencia a transação HTTP, mas delega o salvamento atômico ACID à RPC do PostgreSQL.

### 7. Estratégia para Substituir `auth.users`
- Uma nova migration DDL criará a tabela `public.usuarios` (id UUID, email, password_hash, role).
- O Spring Security gerenciará as senhas usando `BCryptPasswordEncoder`.

### 8. Estratégia para Substituir o RLS
- O Row-Level Security (RLS) será desativado no banco de dados.
- O Spring Boot garantirá a segurança no nível de aplicação (Tenant/Usuário). O ID do usuário autenticado será extraído do `SecurityContextHolder` e repassado implicitamente para as queries (ex: injetando `caixa.usuario_id == currentUserId` nas buscas JPA).

### 9. DTOs entre Flutter e API
- Contratos rigorosos de JSON via classes de Request/Response DTO no Java (records no Java 14+).
- No Flutter, usaremos `json_serializable` e `freezed` para garantir que a serialização bata perfeitamente com os endpoints REST do backend.

### 10. Tratamento de Erros (Exception Handling)
- `@RestControllerAdvice` no Spring para capturar exceptions globais (e.g. `InsufficientStockException`, `ObjectNotFoundException`).
- A API sempre devolverá um `ProblemDetail` (RFC 7807) padronizado para o Flutter exibir no UI (ex: HTTP 409 Conflict se estoque faltar).

### 11. Idempotência
- A chave de idempotência (`external_event_id`) continua operante na tabela de pedidos.
- O Spring Boot tratará e delegará para a constraint `UNIQUE` no banco. Caso haja colisão (duplicidade), retornará sucesso imediato ou `409 Conflict` dependendo da origem (ex: webhook de WhatsApp).

### 12. Logs e Auditoria
- LogBack/SLF4J no backend para rastrear fluxo das requisições (MDC para ID de requisição e ID do usuário).
- Tabelas de auditoria (Migration `004`) no banco continuam operantes para trilha de ações críticas.

### 13. Docker Compose (Ambiente Local)
O ambiente de desenvolvimento unificado subirá com:
```yaml
version: '3.8'
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: quentinhas
      POSTGRES_USER: quentinhas_app
      POSTGRES_PASSWORD: app_password
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
  
  backend:
    build: ./backend-java
    ports:
      - "8080:8080"
    environment:
      - SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/quentinhas
      - JWT_SECRET=chave_super_segura_local_development
    depends_on:
      - db

volumes:
  pgdata:
```

### 14. Configuração por Ambiente (Profiles)
- `application-dev.yml`: Acesso ao banco local do Docker, CORS liberado para testes, logging de queries ativo.
- `application-prod.yml`: Variáveis de ambiente injetadas no deploy, senhas em cofre (Secrets), CORS estrito, logs em níveis superiores.

### 15. Estratégia de Testes
- **Backend:** Testes Unitários com JUnit 5 + Mockito. Testes de Integração usando `Testcontainers` (levantando um Postgres isolado) para validar se o Spring consegue executar as RPCs corretamente.
- **Frontend:** O Flutter usará Mocktail / bloc_test para emular as chamadas da nova API REST.

### 16. Caminho Futuro para Deploy
- **Database:** Supabase ou AWS RDS/DigitalOcean (Apenas como Database-as-a-Service, sem features de Auth/PaaS).
- **Backend Java:** Empacotado via Dockerfile e publicado em PaaS modernas (Railway, Render) ou ECS.
- **Frontend:** Lojas nativas ou Web com chamadas apontando para a URL HTTPS do novo Gateway Java.
