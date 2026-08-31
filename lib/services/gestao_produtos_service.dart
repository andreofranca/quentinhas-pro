import 'package:lanchonete_controle/main.dart';
import 'api_client.dart';

class GestaoProdutosService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Produto>> listarProdutos() async {
    final response = await _api.get('/api/gestao/produtos');
    return (response as List).map((json) => Produto.fromJsonFull(json)).toList();
  }

  Future<Produto> criarProduto(Map<String, dynamic> data) async {
    final response = await _api.post('/api/gestao/produtos', body: data);
    return Produto.fromJsonFull(response);
  }

  Future<Produto> atualizarProduto(String id, Map<String, dynamic> data) async {
    final response = await _api.put('/api/gestao/produtos/$id', body: data);
    return Produto.fromJsonFull(response);
  }

  Future<void> desativarProduto(String id) async {
    await _api.delete('/api/gestao/produtos/$id');
  }
}
