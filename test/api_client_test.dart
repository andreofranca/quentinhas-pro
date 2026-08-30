import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lanchonete_controle/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient apiClient;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    apiClient = ApiClient.instance;
    await apiClient.clearToken();
  });

  test('Deve inicializar baseUrl corretamente', () {
    expect(ApiClient.baseUrl, 'http://localhost:8080');
  });

  test('Deve salvar, verificar autenticacao e limpar JWT', () async {
    expect(apiClient.isAuthenticated, isFalse);
    
    await apiClient.saveToken('fake_jwt_token');
    expect(apiClient.isAuthenticated, isTrue);

    await apiClient.init();
    expect(apiClient.isAuthenticated, isTrue);

    await apiClient.clearToken();
    expect(apiClient.isAuthenticated, isFalse);
  });

  test('Deve fazer GET adicionando Authorization header se autenticado', () async {
    await apiClient.saveToken('token_123');
    
    apiClient.httpClient = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer token_123');
      expect(request.url.toString(), 'http://localhost:8080/api/teste');
      return http.Response('{"ok":true}', 200);
    });

    final response = await apiClient.get('/api/teste');
    expect(response['ok'], isTrue);
  });

  test('Deve fazer POST serializando JSON', () async {
    apiClient.httpClient = MockClient((request) async {
      expect(request.headers['Content-Type'], 'application/json');
      expect(request.body, '{"nome":"Teste"}');
      return http.Response('{"id":1}', 201);
    });

    final response = await apiClient.post('/api/teste', body: {'nome': 'Teste'});
    expect(response['id'], 1);
  });

  test('Deve capturar ProblemDetail do Spring Boot e lançar ApiException', () async {
    apiClient.httpClient = MockClient((request) async {
      return http.Response('{"detail":"Estoque esgotado","status":409}', 409);
    });

    try {
      await apiClient.get('/api/erro');
      fail('Deveria ter lançado ApiException');
    } catch (e) {
      expect(e, isA<ApiException>());
      final apiEx = e as ApiException;
      expect(apiEx.statusCode, 409);
      expect(apiEx.message, 'Estoque esgotado');
      expect(apiEx.data?['status'], 409);
    }
  });

  test('Deve capturar resposta vazia no GET (204 No Content)', () async {
    apiClient.httpClient = MockClient((request) async {
      return http.Response('', 204);
    });

    final response = await apiClient.get('/api/vazio');
    expect(response, isNull);
  });
}
