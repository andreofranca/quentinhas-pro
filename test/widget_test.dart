import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lanchonete_controle/main.dart';

void main() {
  testWidgets('Exibe erro quando configuracao do Supabase esta ausente', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AppConfiguracaoInvalida());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
    expect(find.textContaining('SUPABASE_ANON_KEY'), findsOneWidget);
  });
}
