import 'package:lanchonete_controle/services/api_client.dart';
import 'package:lanchonete_controle/models/models_quentinha.dart';

class CatalogoService {
  final ApiClient _api = ApiClient.instance;

  Future<CatalogoCompleto> buscarCatalogo() async {
    final response = await _api.get('/api/catalogo');
    
    if (response == null) {
        return CatalogoCompleto(ofertas: [], adicionais: []);
    }
    
    List<dynamic> data = response['produtos'] ?? [];
    List<dynamic> adicionaisData = response['adicionais'] ?? [];
    
    List<OfertaQuentinha> produtos = data.map((json) {
      List<dynamic> tamanhosJson = json['tamanhos'] ?? [];
      
      List<TamanhoOpcao> tamanhos = tamanhosJson.map((t) {
        TamanhoQuentinha tq = TamanhoQuentinha.values.firstWhere(
            (e) => e.sigla == t['sigla'],
            orElse: () => TamanhoQuentinha.P);
            
        return TamanhoOpcao(
          tamanho: tq,
          preco: (t['preco'] as num).toDouble(),
          quantidadeDisponivel: t['disponivel'] == true ? null : 0, 
          ofertaId: t['ofertaId'] ?? t['oferta_id'],
        );
      }).toList();
      
      return OfertaQuentinha(
        id: json['id'],
        nome: json['nome'],
        descricao: json['descricao'] ?? '',
categoria: json['categoria'] ?? 'MARMITA',
          estoqueAtual: json['estoqueAtual'] ?? 0,
        tamanhos: tamanhos,
      );
    }).toList();
    
    List<AdicionalQuentinha> adicionais = adicionaisData.map((json) {
      return AdicionalQuentinha(
        id: json['id'],
        nome: json['nome'],
        preco: (json['preco'] as num).toDouble(),
      );
    }).toList();
    
    return CatalogoCompleto(ofertas: produtos, adicionais: adicionais);
  }
}




