/// Utilitário de formatação e normalização de números para integração com o WhatsApp.
class WhatsAppPhoneNormalizer {
  /// Remove máscara, ajusta DDI e garante que o número seja válido para URLs do WhatsApp.
  /// Lança exceção caso o número seja flagrantemente inválido.
  static String normalizar(String telefoneBruto) {
    // Remove tudo que não for dígito
    String apenasNumeros = telefoneBruto.replaceAll(RegExp(r'[^0-9]'), '');

    if (apenasNumeros.isEmpty) {
      throw Exception('Domínio: Telefone inválido (vazio).');
    }

    // Se possui 10 ou 11 dígitos, tratamos como número brasileiro sem DDI
    // Ex: 21999999999 -> 5521999999999
    if (apenasNumeros.length == 10 || apenasNumeros.length == 11) {
      return '55$apenasNumeros';
    }

    // Se possui 12 ou 13 dígitos e começa com 55, é um número BR com DDI válido
    if ((apenasNumeros.length == 12 || apenasNumeros.length == 13) && apenasNumeros.startsWith('55')) {
      return apenasNumeros;
    }

    // Qualquer outro cenário é rejeitado
    throw Exception('Domínio: Telefone com formato inválido. Use (DDD) 9XXXX-XXXX');
  }
}
