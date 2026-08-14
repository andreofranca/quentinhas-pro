import 'package:url_launcher/url_launcher.dart';

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
/// Herdado e adaptado do legado do Lanchonete Pro.
class WhatsAppUrlLauncherService implements WhatsAppService {
  final String defaultCountryCode;

  WhatsAppUrlLauncherService({this.defaultCountryCode = '+55'});

  String _normalizarTelefone(String telefoneRaw) {
    String limpo = telefoneRaw.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Se não começar com o DDI, injetamos (ex: 55)
    final cod = defaultCountryCode.replaceAll('+', '');
    if (!limpo.startsWith(cod) && limpo.length <= 11) {
      limpo = '$cod$limpo';
    }
    return limpo;
  }

  @override
  Future<void> enviarMensagem({
    required String telefone,
    required String mensagem,
  }) async {
    final foneNorm = _normalizarTelefone(telefone);
    final uri = Uri.parse(
      'https://api.whatsapp.com/send?phone=$foneNorm&text=${Uri.encodeComponent(mensagem)}',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw WhatsAppException('Não foi possível abrir o WhatsApp (canLaunchUrl retornou falso).');
      }
    } catch (e) {
      if (e is WhatsAppException) rethrow;
      throw WhatsAppException('Falha ao acionar a URL do WhatsApp: $e');
    }
  }
}
