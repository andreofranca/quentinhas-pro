import 'package:flutter_test/flutter_test.dart';
import 'package:lanchonete_controle/utils/whatsapp_phone_normalizer.dart';

void main() {
  group('WhatsAppPhoneNormalizer', () {
    test('Deve adicionar DDI 55 para números de 10 e 11 dígitos', () {
      expect(WhatsAppPhoneNormalizer.normalizar('(21) 99999-9999'), '5521999999999');
      expect(WhatsAppPhoneNormalizer.normalizar('21 9999-9999'), '552199999999'); // 10 dígitos (fixo/antigo)
    });

    test('Deve manter números que já possuem o DDI 55 correto', () {
      expect(WhatsAppPhoneNormalizer.normalizar('+55 (21) 99999-9999'), '5521999999999');
      expect(WhatsAppPhoneNormalizer.normalizar('5521999999999'), '5521999999999');
    });

    test('Deve rejeitar números totalmente inválidos', () {
      expect(() => WhatsAppPhoneNormalizer.normalizar('123'), throwsException); // Curto demais
      expect(() => WhatsAppPhoneNormalizer.normalizar('+55 (21) 99999-9999999'), throwsException); // Longo demais
      expect(() => WhatsAppPhoneNormalizer.normalizar('ABC'), throwsException); // Apenas letras
    });
  });
}
