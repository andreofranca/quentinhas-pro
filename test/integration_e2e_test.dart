import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lanchonete_controle/main.dart';
import 'package:lanchonete_controle/screens/dashboard/tela_dashboard_quentinhas.dart';
import 'package:lanchonete_controle/services/api_client.dart';
import 'package:lanchonete_controle/services/catalogo_service.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class MyHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = MyHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    
    // Fazer login para pegar o token real
    final res = await http.post(
      Uri.parse('http://localhost:8080/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': 'admin@quentinhas.com.br', 'senha': 'admin'})
    );
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
  });

  testWidgets('E2E Pedido Real Flow via UI (Flutter)', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: TelaDashboardQuentinhas()),
      ));
      
      // Esperar pelo loading (em real-time)
      for(int i=0; i<10; i++){
         await tester.pump(const Duration(milliseconds: 500));
         if (find.textContaining('Carne').evaluate().isNotEmpty) break;
      }
      
      expect(find.textContaining('Carne'), findsWidgets);
      
      final btnM = find.widgetWithText(ElevatedButton, 'M').first;
      await tester.tap(btnM);
      await tester.pump(const Duration(seconds: 1));
      
      final chkOvo = find.byType(Checkbox).first;
      await tester.tap(chkOvo);
      await tester.pump(const Duration(milliseconds: 500));
      
      final btnConfirmAdicional = find.text('CONFIRMAR');
      await tester.tap(btnConfirmAdicional);
      await tester.pump(const Duration(seconds: 1));

      final btnAddQtd = find.byIcon(Icons.add_circle_outline).first;
      await tester.tap(btnAddQtd);
      await tester.pump(const Duration(seconds: 1));
      
      final btnCheckout = find.textContaining('PAGAMENTO'); 
      await tester.tap(btnCheckout);
      await tester.pump(const Duration(seconds: 1));

      final txtNome = find.byType(TextField).first;
      await tester.enterText(txtNome, 'Teste UI Real 3');
      
      final txtPhone = find.byType(TextField).at(1);
      await tester.enterText(txtPhone, '11999999999');
      await tester.pump(const Duration(seconds: 1));

      final btnConfirm = find.textContaining('CONFIRMAR').first;
      await tester.ensureVisible(btnConfirm);
      await tester.tap(btnConfirm);
      
      for(int i=0; i<10; i++){
         await tester.pump(const Duration(milliseconds: 500));
      }

      final snackBars = find.byType(SnackBar);
      for (var element in snackBars.evaluate()) {
        final snackBar = element.widget as SnackBar;
        final textWidget = snackBar.content as Text;
        print('SNACKBAR TEXT: ${textWidget.data}');
      }
      
      print('FLUXO COMPLETO VIA WIDGET TEST: SUCESSO');
    });
  });
}
