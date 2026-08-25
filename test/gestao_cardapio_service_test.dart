import 'package:flutter_test/flutter_test.dart';
import 'package:lanchonete_controle/services/gestao_cardapio_service.dart';
import 'package:lanchonete_controle/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late MockClient mockHttpClient;
  late GestaoCardapioService service;

  setUp(() {
    mockHttpClient = MockClient((request) async {
      if (request.url.toString() == 'http://localhost:8080/api/gestao/ofertas' && request.method == 'GET') {
        return http.Response('[]', 200, headers: {'content-type': 'application/json'});
      }
      return http.Response('Not Found', 404);
    });
    ApiClient.instance.httpClient = mockHttpClient;
    service = GestaoCardapioService();
  });

  test('Deve chamar a URL correta /api/gestao/ofertas no GET', () async {
    final ofertas = await service.listarOfertas();
    expect(ofertas, isEmpty);
  });
}
