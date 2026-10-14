import 'package:url_launcher/url_launcher.dart';
import '../utils/whatsapp_phone_normalizer.dart';

/// Exceção customizada para erros do WhatsApp
class WhatsAppException implements Exception {
  final String mensagem;
  WhatsAppException(this.mensagem);
  @override
  String toString() => 'WhatsAppException: $mensagem';
}

/// Contrato abstrato para que a camada de Domínio não conheça a implementação real.
/// Futuramente pode ser implementado via WhatsApp Cloud API.
abstract class WhatsAppService {
  /// Envia a mensagem para o número informado.
  /// O número deve conter DDD. O código do país pode ser inferido na implementação.
  Future<void> enviarMensagem({
    required String telefone,
    required String mensagem,
  });
}

/// Implementação do serviço usando o aplicativo nativo via URL Launcher.
class WhatsAppUrlLauncherService implements WhatsAppService {
  final String defaultCountryCode;

  WhatsAppUrlLauncherService({this.defaultCountryCode = '+55'});

  @override
  Future<void> enviarMensagem({
    required String telefone,
    required String mensagem,
  }) async {
    final foneNorm = WhatsAppPhoneNormalizer.normalizar(telefone);
    final uri = Uri.parse(
      'https://wa.me/$foneNorm?text=${Uri.encodeComponent(mensagem)}',
    );

    try {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (!ok) {
        // Fallback para external application
        final okExt = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!okExt) {
          throw WhatsAppException('Não foi possível abrir o link do WhatsApp.');
        }
      }
    } catch (e) {
      if (e is WhatsAppException) rethrow;
      throw WhatsAppException('Falha ao acionar a URL do WhatsApp: $e');
    }
  }
}
