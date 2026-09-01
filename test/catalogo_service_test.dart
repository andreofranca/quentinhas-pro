import 'package:flutter_test/flutter_test.dart';
import 'package:lanchonete_controle/services/api_client.dart';
import 'package:lanchonete_controle/services/catalogo_service.dart';
import 'package:lanchonete_controle/models/models_quentinha.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('Deve retornar lista de OfertaQuentinha mapeando os tamanhos corretamente', () async {
    ApiClient.instance.httpClient = MockClient((request) async {
      expect(request.url.path, '/api/catalogo');
      return http.Response(
        '''
        {
          "produtos": [
          {
            "id": "e44d3159-...",
            "nome": "Feijoada Completa",
            "descricao": "Acompanha arroz e couve",
            "categoria": "PRATO_FEITO",
            "tamanhos": [
              {
                "oferta_id": "8f8b9195-...",
                "sigla": "P",
                "preco": 18.00,
                "disponivel": true
              },
              {
                "oferta_id": "aaaa9195-...",
                "sigla": "G",
                "preco": 25.00,
                "disponivel": false
              }
            ]
          }
        ]}
        ''',
        200,
        headers: {'content-type': 'application/json; charset=utf-8'}
      );
    });

    final service = CatalogoService();
    final ofertas = await service.buscarCatalogo();

    expect(ofertas.length, 1);
    expect(ofertas.first.nome, "Feijoada Completa");
    expect(ofertas.first.descricao, "Acompanha arroz e couve");
    
    final tamanhos = ofertas.first.tamanhos;
    expect(tamanhos.length, 2);
    
    // Tamanho P
    expect(tamanhos[0].tamanho, TamanhoQuentinha.P);
    expect(tamanhos[0].preco, 18.00);
    expect(tamanhos[0].quantidadeDisponivel, null);
    expect(tamanhos[0].ofertaId, "8f8b9195-...");
    
    // Tamanho G
    expect(tamanhos[1].tamanho, TamanhoQuentinha.G);
    expect(tamanhos[1].preco, 25.00);
    expect(tamanhos[1].quantidadeDisponivel, 0);
    expect(tamanhos[1].ofertaId, "aaaa9195-...");
  });
}
