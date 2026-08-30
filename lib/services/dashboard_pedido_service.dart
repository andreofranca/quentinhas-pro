import 'dart:convert';
import '../main.dart';
import 'api_client.dart';

class DashboardPedidoService {
  final ApiClient _apiClient = ApiClient.instance;

  Future<List<Pedido>> obterPedidos() async {
    final response = await _apiClient.get('/api/pedidos');
    List<dynamic> data = response;
    return data.map((json) => Pedido.fromJson(json)).toList();
  }

  Future<void> atualizarStatus(String pedidoId, String novoStatus) async {
    await _apiClient.post('/api/pedidos/$pedidoId/transicao', body: {
      'status': novoStatus
    });
  }
}

