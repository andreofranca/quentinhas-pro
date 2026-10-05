import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanchonete_controle/services/api_client.dart';
import 'package:lanchonete_controle/services/catalogo_service.dart';
import 'package:flutter/widgets.dart';

class MyHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = MyHttpOverrides();
    await ApiClient.instance.init();
  });

  test('Check se api retorna Carne', () async {
    final cat = await CatalogoService().buscarCatalogo();
    print('Produtos retornados: ${cat.ofertas.length}');
    for (var p in cat.ofertas) {
      print(' - ${p.nome}');
    }
  });
}
