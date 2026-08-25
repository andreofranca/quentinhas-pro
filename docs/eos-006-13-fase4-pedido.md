# EOS-006.13 - Fase 4: Pedido REST (Auditoria e Mapeamento)

## 1. Mapeamento Exato do Flutter vs Contrato API

Foi realizada a auditoria da `TelaCheckoutMock` e `PedidoDraft` para comparar com o contrato homologado de `POST /api/pedidos`.

| Campo no Backend (Java DTO / JSONB) | Origem no Flutter (`PedidoDraft`) | Status de Alinhamento |
| --- | --- | --- |
| `caixaId` / `caixa_id` | Requer um `UUID`. Atualmente o app Flutter **nao gerencia** sessoes fisicas de caixa abertas. | :warning: **Divergencia / NO-GO** (Veja detalhes abaixo) |
| `cliente.nome` / `telefone` | `ClienteContato.nome`, `ClienteContato.telefoneWhatsApp` | :white_check_mark: Alinhado |
| `modalidade` | Traduzido de `TipoEntrega` ('ENTREGA' ou 'RETIRADA') | :white_check_mark: Alinhado |
| `taxaEntrega` | `taxaEntrega` | :white_check_mark: Alinhado |
| `enderecoEntrega` | Formatacao concatenada do objeto `EnderecoEntrega` | :white_check_mark: Alinhado |
| `observacoes` | `observacoes` | :white_check_mark: Alinhado |
| `total` | `subtotalItens + taxaEntrega` | :white_check_mark: Alinhado |
| `itens[].ofertaId` | Injetado na Fase 3: `TamanhoOpcao.ofertaId` | :white_check_mark: Alinhado |
| `itens[].quantidade` / `precoUnitario` / `subtotal`| Retirado diretamente de `ItemCarrinhoQuentinha` | :white_check_mark: Alinhado |
| `pagamento.formaPagamento` | `FormaPagamentoDraft.name.toUpperCase()` | :white_check_mark: Alinhado |
| `pagamento.valorRecebido` e `troco`| Lidos de `valorRecebido` e `valorTroco` (getter no Dart) | :white_check_mark: Alinhado |
| `provedorEvento` | String fixa `"APP_FLUTTER"` | :white_check_mark: Alinhado |
| `externalEventId` | Idempotencia nao existe na view original. Sera gerada na nova `PedidoService`. | :warning: Facil de resolver (Usar pacote `uuid`) |

## 2. Ponto de Alteracao de Estoque no Flutter
Atualmente na `TelaCheckoutMock._finalizarDraft`, existe o trecho:
```dart
// REGRA DE NEGOCIO: BAIXA DE ESTOQUE (Mockada na UI para o EOS-004.8)
for (var item in draft.itens) {
  item.tamanhoEscolhido.consumir(item.quantidade);
}
```
**Acao Necessaria**: Este codigo local devera ser integralmente deletado na implementacao. O estoque em memoria nao dita regras; a API e quem deve devolver `409 Conflict` (Estoque Esgotado).

## 3. Disparo do WhatsApp
Na atual `TelaCheckoutMock._finalizarDraft`:
```dart
await widget.whatsappService.enviarMensagem(telefone: whatsappCozinhaMock, mensagem: msgOperacional);
await widget.whatsappService.enviarMensagem(telefone: draft.cliente!.telefoneWhatsApp, mensagem: msgCliente);
```
**Acao Necessaria**: Este bloco ocorre incondicionalmente *antes* da transacao finalizar de verdade. Ele devera ser movido para **depois** do retorno `HTTP 200/201` do `PedidoService`. O WhatsApp nunca pode ser disparado se o Spring Boot recusar por estoque insuficiente ou falha na matematica do troco.

## 4. O Ponto de NO-GO (Divergencia de Caixa)
O contrato backend exige estritamente um `caixaId` (UUID valido atrelado a tabela `caixas`) associado ao `POST /api/pedidos`. 
O aplicativo Flutter hoje se autentica e sabe quem e o *Usuario*, mas a gestao transacional de abertura/fechamento de `Caixa` e um legado e nao temos conexao real com o backend para isso ainda. Se enviarmos sem `caixaId`, falhara (`400 Bad Request` na validacao `@NotNull` do Spring).

**Resolucao necessaria da Triade:**
Como devemos proceder para aprovar a passagem deste `caixaId` nesta fase de transicao?
1. Criamos um `Caixa` dummy/laboratorio fixo na inicializacao do backend?
2. Antecipamos um endpoint rapido de `GET /api/caixas/aberto-do-usuario`?
3. Injetamos o UUID de um caixa existente via variavel global no Flutter por enquanto?

Aguardando deliberacao para iniciar implementacao de codigo.
