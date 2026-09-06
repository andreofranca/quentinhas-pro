import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanchonete_controle/main.dart';
import 'package:lanchonete_controle/screens/shell_principal.dart';
import 'package:lanchonete_controle/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await ApiClient.instance.clearToken();
  });

  Widget makeTestableWidget(Widget child) {
    return MaterialApp(home: child);
  }

  testWidgets('Fluxo Login Sucesso - Deve redirecionar para Dashboard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    ApiClient.instance.httpClient = MockClient((request) async {
      return http.Response(
        '{"token": "fake_jwt", "usuario": {"id": 1, "nome": "Mock", "email": "teste@teste.com", "role": "ATENDENTE"}}',
        200,
        headers: {'content-type': 'application/json; charset=utf-8'}
      );
    });

    await tester.pumpWidget(makeTestableWidget(const TelaLogin()));
    
    await tester.enterText(find.byType(TextField).first, 'teste@teste.com');
    await tester.enterText(find.byType(TextField).last, 'senha123');
    await tester.tap(find.text('ENTRAR NO ERP'));
    await tester.pumpAndSettle();

    expect(find.byType(ShellPrincipal), findsOneWidget);
  });

  testWidgets('Fluxo Login Erro (401) - Deve exibir SnackBar com erro', (WidgetTester tester) async {
    ApiClient.instance.httpClient = MockClient((request) async {
      return http.Response(
        '{"status":401, "detail":"Credenciais invalidas"}',
        401,
        headers: {'content-type': 'application/json; charset=utf-8'}
      );
    });

    await tester.pumpWidget(makeTestableWidget(const TelaLogin()));
    
    await tester.enterText(find.byType(TextField).first, 'errado@teste.com');
    await tester.enterText(find.byType(TextField).last, 'senha123');
    await tester.tap(find.text('ENTRAR NO ERP'));
    
    await tester.pump(const Duration(milliseconds: 100)); // Start request
    await tester.pump(const Duration(milliseconds: 100)); // Finish request
    await tester.pumpAndSettle(); // Settle animation

    expect(find.byType(ShellPrincipal), findsNothing);
    expect(find.text('Credenciais invalidas'), findsOneWidget);
    expect(ApiClient.instance.isAuthenticated, isFalse);
  });
}
