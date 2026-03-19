import 'package:flutter/services.dart';
import 'constants.dart';

// ============================================================================
// CLASSE HELPER PARA FORMATAÇÃO DE MOEDA
// ============================================================================
class CurrencyHelper {
  /// Formata um número double para moeda brasileira (R$ 25,90)
  static String formatCurrency(double value) {
    String formatted = value.toStringAsFixed(2).replaceAll('.', ',');
    return '$simboloMoeda $formatted';
  }

  /// Formata um número double para moeda sem símbolo (25,90)
  static String formatCurrencyNoSymbol(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  /// Converte string "25,90" para double 25.90
  static double parseCurrency(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
  }

  /// Retorna apenas o valor sem formatação
  static String getValueOnly(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }
}

// ============================================================================
// FORMATADOR: PRIMEIRA LETRA MAIÚSCULA
// ============================================================================
class PrimeiraLetraMaiusculaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    
    String formatado = newValue.text
        .split(' ')
        .map((palavra) => 
            palavra.isEmpty 
                ? '' 
                : palavra[0].toUpperCase() + palavra.substring(1).toLowerCase())
        .join(' ');
    
    return TextEditingValue(
      text: formatado,
      selection: newValue.selection,
    );
  }
}

// ============================================================================
// FORMATADOR: TELEFONE (00) 00000-0000
// ============================================================================
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var texto = newValue.text;
    
    if (texto.length > 11) {
      texto = texto.substring(0, 11);
    }

    var formatado = '';
    for (int i = 0; i < texto.length; i++) {
      if (i == 0) formatado += '(';
      if (i == 2) formatado += ') ';
      if (i == 7) formatado += '-';
      formatado += texto[i];
    }

    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }
}

// ============================================================================
// FORMATADOR: CEP (00000-000)
// ============================================================================
class CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var texto = newValue.text;
    
    if (texto.length > 8) {
      texto = texto.substring(0, 8);
    }

    var formatado = '';
    for (int i = 0; i < texto.length; i++) {
      if (i == 5) formatado += '-';
      formatado += texto[i];
    }

    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }
}

// ============================================================================
// FORMATADOR: NÚMERO DE ENDEREÇO
// ============================================================================
class NumeroEnderecoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    
    // Aceita números e "SN" (sem número)
    String texto = newValue.text.toUpperCase();
    
    if (texto.length > 1 && texto != 'SN') {
      texto = texto.replaceAll(RegExp(r'[^0-9]'), '');
    }
    
    return TextEditingValue(
      text: texto,
      selection: newValue.selection,
    );
  }
}

// ============================================================================
// FORMATADOR: UPPER CASE SIMPLES
// ============================================================================
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// ============================================================================
// VALIDADORES REUTILIZÁVEIS
// ============================================================================
class InputValidator {
  /// Valida se o campo não está vazio
  static String? validateRequired(String? value, {String msg = msgCampoObrigatorio}) {
    return value?.isEmpty ?? true ? msg : null;
  }

  /// Valida se o telefone é válido
  static String? validatePhone(String? value) {
    if (value?.isEmpty ?? true) return msgCampoObrigatorio;
    return (value?.length ?? 0) < tamanhoMinimoTelefone ? msgTelefoneInvalido : null;
  }

  /// Valida se o CEP é válido
  static String? validateCep(String? value) {
    if (value?.isEmpty ?? true) return msgCampoObrigatorio;
    String cepLimpo = value!.replaceAll(RegExp(r'[^0-9]'), '');
    return cepLimpo.length != tamanhoMinimoCep ? "CEP inválido (deve ter 8 dígitos)" : null;
  }

  /// Valida se a senha atende requisitos mínimos
  static String? validatePassword(String? value) {
    if (value?.isEmpty ?? true) return msgCampoObrigatorio;
    return (value?.length ?? 0) < tamanhoMinimoSenha ? "Senha deve ter no mínimo $tamanhoMinimoSenha caracteres" : null;
  }

  /// Valida se email é válido
  static String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) return null; // Email é opcional
    const emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    final regex = RegExp(emailPattern);
    return regex.hasMatch(value!) ? null : "Email inválido";
  }
}
