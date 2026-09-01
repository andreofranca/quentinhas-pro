import 'package:lanchonete_controle/services/api_client.dart';
import 'package:lanchonete_controle/models/models_quentinha.dart';

class CatalogoService {
  final ApiClient _api = ApiClient.instance;

  Future<List<OfertaQuentinha>> buscarCatalogo() async {
    final response = await _api.get('/api/catalogo');
    
    if (response == null || !response.containsKey('produtos')) return [];
    
    List<dynamic> data = response['produtos'] ?? [];
    
    return data.map((json) {
      List<dynamic> tamanhosJson = json['tamanhos'] ?? [];
      
      List<TamanhoOpcao> tamanhos = tamanhosJson.map((t) {
        TamanhoQuentinha tq = TamanhoQuentinha.values.firstWhere(
            (e) => e.sigla == t['sigla'],
            orElse: () => TamanhoQuentinha.P);
            
        return TamanhoOpcao(
          tamanho: tq,
          preco: (t['preco'] as num).toDouble(),
          // O backend retorna um boolean 'disponivel', entao mapaeamos 
          quantidadeDisponivel: t['disponivel'] == true ? null : 0, 
          ofertaId: t['oferta_id'],
        );
      }).toList();
      
      return OfertaQuentinha(
        id: json['id'],
        nome: json['nome'],
        descricao: json['descricao'] ?? '',
        tamanhos: tamanhos,
      );
    }).toList();
  }
}
