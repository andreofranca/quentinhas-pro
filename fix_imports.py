import re

def add_import(file, imp):
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    if imp not in content:
        content = content.replace("import 'package:flutter/material.dart';", f"import 'package:flutter/material.dart';\n{imp}")
        with open(file, 'w', encoding='utf-8') as f:
            f.write(content)

add_import('lib/screens/dashboard/tela_dashboard_real.dart', "import '../../main.dart';")
add_import('lib/screens/gestao/tela_kds.dart', "import '../../main.dart';")
add_import('lib/screens/gestao/tela_lista_pedidos.dart', "import '../../main.dart';")

# Fix CaixaService import in tela_caixa.dart
with open('lib/screens/gestao/tela_caixa.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace("import '../../services/caixa_service.dart';", "import '../../services/pedido_service.dart';")
with open('lib/screens/gestao/tela_caixa.dart', 'w', encoding='utf-8') as f:
    f.write(content)

