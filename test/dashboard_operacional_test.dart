import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanchonete_controle/main.dart';

import 'package:lanchonete_controle/services/whatsapp_service.dart';

class FakeWhatsAppService implements WhatsAppService {
  @override
  Future<void> enviarMensagem({required String telefone, required String mensagem}) async {
    // Não faz nada, evita Exception do url_launcher
  }
}

void main() {
  testWidgets('Fluxo Operacional de Quentinhas (EOS-004.8 - Estoque)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    final fakeService = FakeWhatsAppService();

    await tester.pumpWidget(AppLanchonete(whatsappService: fakeService));
    await tester.pumpAndSettle();

    // 1. Feijoada P já começa esgotada no mock inicial
    final feijoadaFinder = find.ancestor(
      of: find.text('Feijoada Completa'),
      matching: find.byType(Card),
    );
    final feijoadaP = find.descendant(of: feijoadaFinder, matching: find.text('P'));
    await tester.ensureVisible(feijoadaP);
    final esgotadoP = find.descendant(
      of: find.ancestor(of: feijoadaP, matching: find.byType(ElevatedButton)),
      matching: find.text('ESGOTADO')
    );
    expect(esgotadoP, findsOneWidget);

    // 2. Comprar 1 Feijoada G (que tem mock quantidadeDisponivel = 1)
    final feijoadaG = find.descendant(of: feijoadaFinder, matching: find.text('G'));
    await tester.ensureVisible(feijoadaG);
    await tester.tap(feijoadaG);
    await tester.pumpAndSettle();

    // Avançar para pagamento (Checkout Mock)
    await tester.tap(find.text('AVANÇAR PARA PAGAMENTO'));
    await tester.pumpAndSettle();

    // Preencher forms mock para passar na validação e finalizar draft
    await tester.enterText(find.widgetWithText(TextFormField, 'Nome do Cliente'), 'Teste');
    await tester.enterText(find.widgetWithText(TextFormField, 'WhatsApp'), '21999999999');
    
    // Finalizar pedido (aciona a baixa de estoque)
    await tester.tap(find.text('FINALIZAR PEDIDO'));
    await tester.pumpAndSettle(const Duration(seconds: 1)); // Aguardar asyncs de WhatsApp Service

    // Retorna ao Dashboard. Verificar se Feijoada G esgotou
    await tester.pumpAndSettle(const Duration(seconds: 5));
    
    final feijoadaG_PosVenda = find.descendant(of: feijoadaFinder, matching: find.text('G'));
    try {
      await tester.ensureVisible(feijoadaG_PosVenda);
    } catch (e) {
      debugDumpApp();
      rethrow;
    }
    final esgotadoG = find.descendant(
      of: find.ancestor(of: feijoadaG_PosVenda, matching: find.byType(ElevatedButton)),
      matching: find.text('ESGOTADO')
    );
    expect(esgotadoG, findsOneWidget); // Feijoada G deve estar esgotada!
    
    // Verificar que Feijoada M NÃO está esgotada
    final feijoadaM = find.descendant(of: feijoadaFinder, matching: find.text('M'));
    await tester.ensureVisible(feijoadaM);
    final esgotadoM = find.descendant(
      of: find.ancestor(of: feijoadaM, matching: find.byType(ElevatedButton)),
      matching: find.text('ESGOTADO')
    );
    expect(esgotadoM, findsNothing); // M deve continuar disponível

    // Tentar adicionar um produto já esgotado clicando nele (o botão deve estar inativo, então o clique não faz nada)
    await tester.tap(feijoadaP); // Esgotado desde o início
    await tester.pumpAndSettle();
    expect(find.text('1x Feijoada Completa (P)'), findsNothing); // Não deve ter adicionado ao carrinho

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
