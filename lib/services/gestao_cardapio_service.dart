import 'package:lanchonete_controle/services/api_client.dart';

class GestaoCardapioService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Map<String, dynamic>>> listarOfertas() async {
    final response = await _api.get('/api/gestao/ofertas');
    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> criarOferta(Map<String, dynamic> data) async {
    final response = await _api.post('/api/gestao/ofertas', body: data);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> editarOferta(String id, Map<String, dynamic> data) async {
    final response = await _api.put('/api/gestao/ofertas/$id', body: data);
    return response as Map<String, dynamic>;
  }
}
