# EOS-006.4 — Laboratório PostgreSQL Local e Conectividade Backend

Este documento formaliza a criação do laboratório limpo de banco de dados nativo e comprova o handshake seguro entre a camada Spring Boot e o PostgreSQL.

## 1. Auditoria e Isolamento de Ambiente

Antes da subida do container, realizamos varredura das portas e dos containers ativos (`docker ps` / `netstat`).
- Detectamos o laboratório Supabase legado ativo nas portas `5450X`.
- Detectamos a porta `5432` ocupada por um contêiner legado local de outro projeto (`sistema_pedidos_db`).
- **Resolução:** Como mandado pela diretriz de "não conflitar ou destruir bancos existentes", alocamos o PostgreSQL do Quentinhas Pro na porta host `5440`.
- O `lanchonete-controle` não foi tocado ou referenciado em nenhuma etapa desta configuração.

## 2. Preparação do Docker

Um `docker-compose.yml` simplificado e isolado foi criado no diretório `backend/`, subindo exclusivamente a imagem `postgres:16-alpine`.
Foram configurados os bancos:
- `quentinhas` (com usuário `quentinhas_app`) para aplicação.
- `quentinhas_test` (com usuário `test`) pré-criado no script de inicialização local para futura adoção por testes nativos.

## 3. Validação de Conectividade (`mvn test`)

Com o container online, a execução do `mvnw test` procedeu de forma limpa.

### Diagnóstico de Conexão (Sucesso Absoluto):
1. **Spring Context Loads:** O bootstrapper do Spring subiu o contexto de dependências sem erros.
2. **Bootstrapping JPA:** A varredura por entidades JPA iniciou de forma contida (`ddl-auto: none`).
3. **HikariCP Start:** O pool de conexões alocou com sucesso: `HikariPool-1 - Added connection org.postgresql.jdbc.PgConnection`.
4. **Resolução de Dialeto:** A aplicação obteve corretamente os metadados do `PostgreSQLDialect` e versão `16.13`.

Resultado: **BUILD SUCCESS** (1 teste, 0 falhas).

## 4. Estado da Auditoria
Todos os artefatos de código produzidos residem na pasta `backend/`. O diretório raiz do Flutter e as antigas pastas de migrations permanecem estritamente intactas. O `git status` comprova isso.

**Missão Finalizada:** O duto Java ↔ Postgres está criado, aberto e seguro. Pronto para receber injeções do modelo transacional.
