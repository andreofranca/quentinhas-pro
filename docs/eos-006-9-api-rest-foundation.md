# EOS-006.9 — Fundação da API REST

**Timestamp da Fundação:** 2026-08-17T16:15:00-03:00

Este documento apresenta os resultados da criação inicial do pilar REST do Quentinhas Pro, garantindo a configuração segura dos endpoints com Spring Security, infraestrutura de tratamento de erros, e a verificação arquitetural do ecossistema HTTP isolado.

## 1. Estrutura Criada

A árvore de diretórios oficial do backend de domínio em Java foi materializada seguindo as melhores práticas de isolamento de responsabilidades:

```text
backend/src/main/java/com/quentinhas/backend/
├── config/
├── controller/
│   └── HealthController.java
├── dto/
│   ├── request/
│   └── response/
├── exception/
│   └── GlobalExceptionHandler.java
├── security/
│   └── SecurityConfig.java
└── service/
```

## 2. Configuração de Segurança (Spring Security)
O Spring Security foi incorporado sem ainda ativar autenticação JWT. As diretrizes configuradas estabelecem que a API nasça inerentemente fechada:
- A injeção de estado local via sessão (Cookie/JSESSIONID) foi permanentemente desabilitada (`STATELESS`).
- A proteção CSRF foi desativada, uma vez que a API será consumida programaticamente e validada por tokens locais do Frontend.
- Todos os endpoints são bloqueados por padrão (retornando `403 Forbidden` ou `401 Unauthorized`), com exceção explícita de `GET /api/health` e o testador transitório `GET /api/health/error` (que serve para atestar nossa modelagem de `ProblemDetail`).

## 3. Endpoints Disponibilizados

### 3.1. `GET /api/health`
Endpoint de batimento cardíaco da aplicação para verificações de Liveness/Readiness e de infraestrutura. 

**Exemplo de Resposta (200 OK):**
```json
{
  "status": "UP",
  "service": "quentinhas-pro-api"
}
```

### 3.2. `GET /api/health/error`
Endpoint de uso exclusivo de testes (Mocking lab). Dispara intencionalmente uma exceção para atestar que as RFCs de erro estão acopladas globalmente.

**Exemplo de Resposta (500 Internal Server Error):**
```json
{
  "type": "https://api.quentinhas.com/errors/internal-server-error",
  "title": "Internal Server Error",
  "status": 500,
  "detail": "Test exception for problem detail",
  "instance": "/api/health/error"
}
```

## 4. Testes Executados e Aprovados
O arquivo `HealthControllerTest.java` foi integrado na suíte garantindo que a malha Security + WebMVC esteja configurada perfeitamente na raiz do Spring.

1. **`healthEndpointShouldReturnUp`**: Assegura mapeamento, acesso não-autenticado e Payload JSON exato.
2. **`errorEndpointShouldReturnProblemDetail`**: Assegura a ativação do `@RestControllerAdvice` (`GlobalExceptionHandler`) transcrevendo a anomalia em Payload RFC-7807 (`ProblemDetail`).
3. **`anyOtherEndpointShouldReturnForbiddenOrUnauthorized`**: Verifica que endpoints não declarados bloqueiam acesso de imediato sem vazar dados ou *stack trace*.

**Todos os testes (`mvnw test` e `flutter test`) foram aprovados com sucesso.**

## 5. Estado Atual do Sistema
- **PostgreSQL Local:** Intocado. Os dados de teste do laboratório (10 pedidos) permanecem na base.
- **Flutter:** Intocado. 
- **Lanchonete-Controle:** Intocado.

## 6. Riscos e Pontos para a EOS-006.10
O próximo degrau estrutural exige a conversão autêntica da comunicação Supabase para API. A fundação está cimentada, o próximo passo imediato deve ser:

1. **Domínio de Segurança:** Construir os filtros JWT (`JwtAuthenticationFilter`) utilizando o ecossistema `spring-boot-starter-security`.
2. **Autorização:** Validar e extrair o `usuarios.id` do JWT antes que qualquer requisição desça para o domínio de serviço (Spring `@Service`).
3. **Persistência de Usuários:** Mapear o entity de `usuarios` usando o Spring Data JPA para checar se o token corresponde a uma identidade real, ativa e autorizada a operar a Lanchonete.
