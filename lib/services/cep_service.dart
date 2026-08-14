import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import '../models/models_quentinha.dart'; // Para EnderecoEntrega

/// Exceção customizada para erros de CEP
class CepException implements Exception {
  final String mensagem;
  CepException(this.mensagem);
  @override
  String toString() => 'CepException: $mensagem';
}

/// Serviço independente para consulta de CEP na API do ViaCEP
class CepService {
  final http.Client client;

  CepService({http.Client? httpClient}) : client = httpClient ?? http.Client();

  /// Busca o endereço a partir do CEP usando ViaCEP
  /// Retorna um [EnderecoEntrega] preenchido parcialmente ou lança [CepException]
  Future<EnderecoEntrega> buscarCep(String cepPuro) async {
    final cep = cepPuro.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) {
      throw CepException('CEP inválido. Deve conter 8 dígitos.');
    }

    try {
      final response = await client.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
      
      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        
        if (dados['erro'] == true) {
          throw CepException('CEP não encontrado na base de dados.');
        }

        return EnderecoEntrega(
          cep: dados['cep'] ?? cep,
          logradouro: dados['logradouro'] ?? '',
          numero: '', // Aguarda input do usuário
          bairro: dados['bairro'] ?? '',
          cidade: dados['localidade'] ?? '',
          uf: dados['uf'] ?? '',
        );
      } else {
        throw CepException('Falha no serviço ViaCEP (Status: ${response.statusCode})');
      }
    } catch (e) {
      if (e is CepException) rethrow;
      throw CepException('Erro de conexão ao buscar CEP: $e');
    }
  }
}

// ============================================================================
// FORMATADORES EXTRAÍDOS DO LEGADO
// ============================================================================

class CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    var t = n.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (t.length > 8) t = t.substring(0, 8);
    var f = '';
    for (int i = 0; i < t.length; i++) {
      if (i == 5) f += '-';
      f += t[i];
    }
    return TextEditingValue(
      text: f,
      selection: TextSelection.collapsed(offset: f.length),
    );
  }
}

class NumeroEnderecoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    String t = n.text.toUpperCase();
    if (t.isEmpty) return n;
    if (RegExp(r'^[0-9]+$').hasMatch(t) || t == 'S' || t == 'SN') {
      return TextEditingValue(text: t, selection: n.selection);
    }
    return o;
  }
}
