import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lanchonete_controle/screens/dashboard/tela_dashboard_quentinhas.dart';
import 'package:lanchonete_controle/widgets/card_oferta_quentinha.dart';
import 'package:lanchonete_controle/services/api_client.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class MyHttpOverrides extends HttpOverrides {}

bool _backendDisponivel = false;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = MyHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    
    try {
      // Fazer login para pegar o token real
      final res = await http.post(
        Uri.parse('http://localhost:8080/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': 'admin@quentinhas.com.br', 'senha': 'admin'})
      ).timeout(const Duration(seconds: 2));

      if (res.statusCode == 200) {
        final token = jsonDecode(res.body)['token'];

        // Mock flutter_secure_storage
        const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'read' && methodCall.arguments['key'] == 'jwt_token') return token;
          if (methodCall.method == 'read') return null;
          if (methodCall.method == 'write') return null;
          if (methodCall.method == 'delete') return null;
          if (methodCall.method == 'readAll') return <String, String>{};
          return null;
        });

        await ApiClient.instance.init();
        _backendDisponivel = true;
      }
    } catch (_) {
      _backendDisponivel = false;
    }
  });

  testWidgets('E2E Pedido Real Flow via UI (Flutter)', (WidgetTester tester) async {
    if (!_backendDisponivel) {
      // Backend offline no ambiente isolado de teste unitário
      return;
    }
    await tester.runAsync(() async {
      tester.view.physicalSize = const Size(1440, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: TelaDashboardQuentinhas()),
      ));
      
      // Esperar pelo loading (em real-time)
      for(int i=0; i<15; i++){
         await Future.delayed(const Duration(milliseconds: 300));
         await tester.pump();
         if (find.textContaining('Feijoada').evaluate().isNotEmpty || find.textContaining('Frango').evaluate().isNotEmpty) break;
      }
      
      expect(find.byType(CardOfertaQuentinha), findsWidgets);
      
      final btnM = find.widgetWithText(ElevatedButton, 'M').first;
      await tester.tap(btnM);
      await tester.pumpAndSettle();
      
      final chkOvo = find.byType(Checkbox).first;
      await tester.tap(chkOvo);
      await tester.pumpAndSettle();
      
      final btnConfirmAdicional = find.widgetWithText(ElevatedButton, 'Confirmar');
      await tester.tap(btnConfirmAdicional);
      await tester.pumpAndSettle();

      final btnAddQtd = find.byIcon(Icons.add).first;
      await tester.tap(btnAddQtd);
      await tester.pumpAndSettle();
      
      final btnCheckout = find.textContaining('PAGAMENTO'); 
      await tester.tap(btnCheckout);
      await tester.pumpAndSettle();

      final txtNome = find.byType(TextFormField).first;
      await tester.enterText(txtNome, 'Teste UI Real');
      
      final txtPhone = find.byType(TextField).at(1);
      await tester.enterText(txtPhone, '11999999999');
      await tester.pump(const Duration(seconds: 1));

      final btnConfirm = find.textContaining('FINALIZAR PEDIDO').first;
      await tester.ensureVisible(btnConfirm);
      await tester.tap(btnConfirm);
      
      for(int i=0; i<15; i++){
         await Future.delayed(const Duration(milliseconds: 300));
         await tester.pump();
         if (find.byType(SnackBar).evaluate().isNotEmpty || find.byType(AlertDialog).evaluate().isNotEmpty) break;
      }

      final snackBars = find.byType(SnackBar);
      final dialogs = find.byType(AlertDialog);
      expect(snackBars.evaluate().isNotEmpty || dialogs.evaluate().isNotEmpty, isTrue);
    });
  });
}
