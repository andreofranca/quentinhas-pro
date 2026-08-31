import 'package:lanchonete_controle/main.dart';
import 'api_client.dart';

class GestaoEstoqueService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Produto>> listarEstoque() async {
    final response = await _api.get('/api/gestao/estoque');
    return (response as List).map((json) {
      return Produto(
        idProduto: json['produtoId'] ?? '',
        nome: json['nome'] ?? '',
        descricao: '',
        categoria: json['categoria'] ?? '',
        imagemUrl: '',
        preco: 0,
        estoqueAtual: json['estoqueAtual'] ?? 0,
        estoqueMinimo: json['estoqueMinimo'] ?? 8,
      );
    }).toList();
  }

  Future<void> atualizarEstoque(String produtoId, int estoqueAtual, int estoqueMinimo) async {
    await _api.put('/api/gestao/estoque/$produtoId', body: {
      'estoqueAtual': estoqueAtual,
      'estoqueMinimo': estoqueMinimo,
    });
  }
}
