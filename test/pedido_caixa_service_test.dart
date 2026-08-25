import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:lanchonete_controle/services/api_client.dart';
import 'package:lanchonete_controle/services/pedido_service.dart';
import 'package:lanchonete_controle/models/models_quentinha.dart';

void main() {
  group('CaixaService e PedidoService Tests', () {
    late ApiClient apiClient;
    late CaixaService caixaService;
    late PedidoService pedidoService;

    setUp(() {
      apiClient = ApiClient.instance;
      caixaService = CaixaService();
      pedidoService = PedidoService();
    });

    test('getCaixaAtivoId deve retornar ID se caixa ativo', () async {
      apiClient.httpClient = MockClient((request) async {
        if (request.url.path == '/api/caixas/ativo') {
          return http.Response(jsonEncode({
            'id': 'caixa-123',
            'status': 'ABERTO'
          }), 200);
        }
        return http.Response('Not Found', 404);
      });

      final caixaId = await caixaService.getCaixaAtivoId();
      expect(caixaId, 'caixa-123');
    });

    test('getCaixaAtivoId deve lanar exceo se no houver caixa', () async {
      apiClient.httpClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Nenhum caixa aberto'}), 404);
      });

      expect(() => caixaService.getCaixaAtivoId(), throwsException);
    });

    test('criarPedido deve retornar ID em caso de sucesso', () async {
      apiClient.httpClient = MockClient((request) async {
        if (request.url.path == '/api/pedidos') {
          return http.Response(jsonEncode({
            'pedidoId': 'pedido-999',
            'status': 'SUCCESS'
          }), 201);
        }
        return http.Response('Not Found', 404);
      });

      final draft = PedidoDraft(
        itens: [
          ItemCarrinhoQuentinha(
            idItem: '1',
            oferta: OfertaQuentinha(id: 'off1', nome: 'Frango', descricao: 'Frango', tamanhos: []),
            tamanhoEscolhido: TamanhoOpcao(tamanho: TamanhoQuentinha.G, preco: 20.0, ofertaId: 'off1'),
            quantidade: 2,
          )
        ],
        subtotalItens: 40.0,
        cliente: ClienteContato(nome: 'Joao', telefoneWhatsApp: '11999999999'),
        tipoEntrega: TipoEntrega.retirada,
      );

      final pedidoId = await pedidoService.criarPedido(draft, 'caixa-123');
      expect(pedidoId, 'pedido-999');
    });
    
    test('criarPedido deve lanar exceo em caso de erro', () async {
      apiClient.httpClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Estoque esgotado'}), 409);
      });

      final draft = PedidoDraft(
        itens: [
          ItemCarrinhoQuentinha(
            idItem: '1',
            oferta: OfertaQuentinha(id: 'off1', nome: 'Frango', descricao: 'Frango assado', tamanhos: []),
            tamanhoEscolhido: TamanhoOpcao(tamanho: TamanhoQuentinha.G, preco: 20.0, ofertaId: 'off1'),
            quantidade: 2,
          )
        ],
        subtotalItens: 40.0,
        cliente: ClienteContato(nome: 'Joao', telefoneWhatsApp: '11999999999'),
        tipoEntrega: TipoEntrega.retirada,
      );

      expect(() => pedidoService.criarPedido(draft, 'caixa-123'), throwsException);
    });
  });
}

