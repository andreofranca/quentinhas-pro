import 'package:flutter_test/flutter_test.dart';
import 'package:lanchonete_controle/formatters.dart';
import 'package:lanchonete_controle/constants.dart';

void main() {
  group('CurrencyHelper Tests', () {
    test('formatCurrency deve formatar com símbolo e vírgula', () {
      expect(CurrencyHelper.formatCurrency(25.90), equals('R\$ 25,90'));
      expect(CurrencyHelper.formatCurrency(100.00), equals('R\$ 100,00'));
      expect(CurrencyHelper.formatCurrency(1234.56), equals('R\$ 1234,56'));
    });

    test('formatCurrencyNoSymbol deve formatar sem símbolo', () {
      expect(CurrencyHelper.formatCurrencyNoSymbol(25.90), equals('25,90'));
      expect(CurrencyHelper.formatCurrencyNoSymbol(0.00), equals('0,00'));
    });

    test('parseCurrency deve converter string para double', () {
      expect(CurrencyHelper.parseCurrency('25,90'), equals(25.90));
      expect(CurrencyHelper.parseCurrency('100,00'), equals(100.00));
      expect(CurrencyHelper.parseCurrency('0,00'), equals(0.0));
    });

    test('getValueOnly deve retornar apenas valor formatado', () {
      expect(CurrencyHelper.getValueOnly(25.90), equals('25,90'));
      expect(CurrencyHelper.getValueOnly(1234.56), equals('1234,56'));
    });

    test('parseCurrency com valor inválido deve retornar 0.0', () {
      expect(CurrencyHelper.parseCurrency('abc'), equals(0.0));
      expect(CurrencyHelper.parseCurrency(''), equals(0.0));
    });
  });

  group('PrimeiraLetraMaiusculaFormatter Tests', () {
    final formatter = PrimeiraLetraMaiusculaFormatter();

    test('deve capitalizar primeira letra de cada palavra', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: 'joão silva'),
      );
      expect(result.text, equals('João Silva'));
    });

    test('deve manter maiúsculas corretas', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: 'andré sousa santos'),
      );
      expect(result.text, equals('André Sousa Santos'));
    });

    test('deve lidar com strings vazias', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: ''),
      );
      expect(result.text, equals(''));
    });
  });

  group('TelefoneInputFormatter Tests', () {
    final formatter = TelefoneInputFormatter();

    test('deve formatar telefone como (00) 00000-0000', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '21999999999'),
      );
      expect(result.text, equals('(21) 99999-9999'));
    });

    test('deve truncar se exceder 11 dígitos', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '219999999991234'),
      );
      expect(result.text, equals('(21) 99999-9999'));
    });

    test('deve lidar com entrada vazia', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: ''),
      );
      expect(result.text, equals(''));
    });
  });

  group('CepInputFormatter Tests', () {
    final formatter = CepInputFormatter();

    test('deve formatar CEP como 00000-000', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '21310230'),
      );
      expect(result.text, equals('21310-230'));
    });

    test('deve truncar se exceder 8 dígitos', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '213102301234'),
      );
      expect(result.text, equals('21310-230'));
    });
  });

  group('InputValidator Tests', () {
    test('validateRequired deve retornar erro se vazio', () {
      expect(InputValidator.validateRequired(null), equals(msgCampoObrigatorio));
      expect(InputValidator.validateRequired(''), equals(msgCampoObrigatorio));
      expect(InputValidator.validateRequired('valor'), isNull);
    });

    test('validatePhone deve validar telefone', () {
      expect(
        InputValidator.validatePhone('(21) 99999-9999'),
        isNull,
      );
      expect(
        InputValidator.validatePhone('123'),
        equals(msgTelefoneInvalido),
      );
    });

    test('validateCep deve validar CEP com 8 dígitos', () {
      expect(InputValidator.validateCep('21310-230'), isNull);
      expect(InputValidator.validateCep('12345'), isNotNull);
    });

    test('validatePassword deve validar senha mínima', () {
      expect(InputValidator.validatePassword('12'), isNotNull);
      expect(InputValidator.validatePassword('123'), isNull);
      expect(InputValidator.validatePassword('senha123'), isNull);
    });

    test('validateEmail deve aceitar emails válidos', () {
      expect(InputValidator.validateEmail('andre@example.com'), isNull);
      expect(InputValidator.validateEmail('invalid-email'), isNotNull);
      expect(InputValidator.validateEmail(''), isNull); // Email é opcional
    });
  });

  group('UpperCaseTextFormatter Tests', () {
    final formatter = UpperCaseTextFormatter();

    test('deve converter tudo para maiúsculas', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: 'andre'),
      );
      expect(result.text, equals('ANDRE'));
    });

    test('deve lidar com entradas mistas', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: 'AnDrE123'),
      );
      expect(result.text, equals('ANDRE123'));
    });
  });
}
