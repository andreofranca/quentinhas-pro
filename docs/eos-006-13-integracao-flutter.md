# EOS-006.13 - Integração Flutter ↔ API REST

## 1. Objetivo
Substituir gradualmente os dados em memória (mocks) pelos dados e fluxos reais da nossa recém-criada API REST Spring Boot, sem quebrar os comportamentos validados de UX, Checkout e Integração via WhatsApp.

## 2. Auditoria e Divergências
Após análise da pasta `lib/` (especificamente `models_quentinha.dart`, `tela_dashboard_quentinhas.dart`, `tela_checkout_mock.dart` e `main.dart`), identificamos o seguinte cenário atual:

1. **Cardápio**: É alimentado por variáveis globais (`mockCardapioHoje` e `cardapio`). A UX da Tela de Dashboard acessa esses mocks de forma síncrona.
2. **Autenticação**: A `TelaLogin` (em `main.dart`) checa credenciais contra uma lista estática de usuários (`listaUsuarios`).
3. **Pedidos/Checkout**: O `TelaCheckoutMock` converte itens do carrinho em um `PedidoDraft`. Ao aprovar, ele abate o estoque no próprio mock em memória e depois dispara os deep links do WhatsApp. Não há comunicação com a nuvem.
4. **Dependências HTTP**: O pacote `http` já existe (usado no CepService). Contudo, não há gestão de Tokens (JWT).

## 3. Plano de Implementação

A substituição será feita preservando a UX e os fluxos, introduzindo comunicação assíncrona.

### Fase 1: Fundação do Cliente API - [x] CONCLUÍDA
1. Adicionado o pacote `flutter_secure_storage` ao `pubspec.yaml` para armazenar de forma verdadeiramente segura o JWT.
2. Criado `lib/services/api_client.dart` contendo a abstração do `http` com configuração da `baseUrl` local e injeção automática do Header `Authorization: Bearer <token>`.

### Fase 2: Autenticação (Login) - [x] CONCLUÍDA
1. Modificar a `TelaLogin` para efetuar POST em `/api/auth/login`.
2. Em caso de sucesso, salvar o Token retornado via `ApiClient` (que gerencia o `flutter_secure_storage`).
3. Prover um mecanismo simples para limpar o token no Logout.

### Fase 3: Catálogo (Leitura) - [x] CONCLUÍDA
1. Criar o serviço que consome `GET /api/catalogo` (lista de `ProdutoCatalogoResponse`).
2. Adaptar os modelos `OfertaQuentinha` e `TamanhoOpcao` para parsearem a nova estrutura, guardando o `oferta_id` (necessário para o carrinho).
3. Na Dashboard, substituir a variável estática `mockCardapioHoje` por um `FutureBuilder` consumindo o serviço.
4. Manter o visual, adicionando loading spinner no carregamento inicial.

### Fase 4: Pedidos (Escrita Transacional)
1. Criar `lib/services/pedido_service.dart`.
2. Alterar o fluxo de `_finalizarDraft` na `TelaCheckoutMock`:
   - Mapear o objeto `PedidoDraft` para o Payload JSON aceito pelo Spring Boot (`PedidoRequest`).
   - Fazer o POST `/api/pedidos`.
   - Se retornar **201 Created**: A API já reservou o estoque no PostgreSQL. Podemos prosseguir com os disparos do `WhatsAppService` intactos e zerar o carrinho.
   - Se retornar **409 / 422** (Exceções capturadas via backend como Estoque Esgotado ou Idempotência): Lançar o erro capturado e exibi-lo no Snackbar (como já fazemos na UX atual).
3. **Remover a dedução de estoque mockada localmente** (`item.tamanhoEscolhido.consumir(item.quantidade);`), garantindo que o PostgreSQL continue como a **Única Autoridade de Estoque**.

## 4. Próximos Passos
Esta etapa de planejamento encontra-se no estado **REVIEW ONLY**.
Nenhuma linha de código fonte Flutter foi alterada ainda. Após autorização da Tríade (GO), iniciaremos a modificação controlada (Fase 1 a 4).



## Checkpoints
- **Fase 1 a 3**: `cc12bb1` - feat(flutter): integrar catalogo com API REST
- **Fase 4**: `b5298b4` - feat(flutter): integrar checkout com pedidos REST
