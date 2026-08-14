import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:lanchonete_controle/models/models_quentinha.dart';
import 'package:lanchonete_controle/utils/whatsapp_message_builder.dart';
import 'package:lanchonete_controle/services/cep_service.dart';

void main() {


  group('CepInputFormatter', () {
    test('Formata CEP corretamente ao digitar', () {
      final formatter = CepInputFormatter();
      final textValue = const TextEditingValue(text: '01001000');
      
      final result = formatter.formatEditUpdate(const TextEditingValue(text: ''), textValue);
      expect(result.text, '01001-000');
    });
  });

  group('CepService (com Fake Client)', () {
    test('CEP Válido sem máscara retorna EnderecoEntrega', () async {
      final service = CepService(httpClient: FakeViaCepClient());
      final endereco = await service.buscarCep('01001000');
      expect(endereco.logradouro, 'Praça da Sé');
      expect(endereco.bairro, 'Sé');
      expect(endereco.cidade, 'São Paulo');
    });

    test('CEP Válido com máscara retorna EnderecoEntrega', () async {
      final service = CepService(httpClient: FakeViaCepClient());
      final endereco = await service.buscarCep('01001-000');
      expect(endereco.logradouro, 'Praça da Sé');
    });

    test('CEP Inválido (tamanho incorreto) lança exceção imediata sem chamar API', () async {
      final service = CepService(httpClient: FakeViaCepClient());
      expect(() => service.buscarCep('123'), throwsA(isA<CepException>()));
      expect(() => service.buscarCep('01001-0000'), throwsA(isA<CepException>()));
    });

    test('CEP Inexistente lança exceção controlada', () async {
      final service = CepService(httpClient: FakeViaCepClient());
      expect(() => service.buscarCep('99999999'), throwsA(isA<CepException>()));
    });
  });
}

/// Fake Client para não bater na rede de verdade nos testes
class FakeViaCepClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final url = request.url.toString();
    if (url.contains('01001000')) {
      final body = '{"cep": "01001-000", "logradouro": "Praça da Sé", "bairro": "Sé", "localidade": "São Paulo", "uf": "SP"}';
      return http.StreamedResponse(Stream.value(body.codeUnits), 200);
    } else if (url.contains('99999999')) {
      final body = '{"erro": true}';
      return http.StreamedResponse(Stream.value(body.codeUnits), 200);
    }
    return http.StreamedResponse(Stream.value('{}'.codeUnits), 404);
  }
}

