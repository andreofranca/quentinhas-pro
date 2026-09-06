import re

with open('lib/screens/shell_principal.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import 'gestao/tela_kds.dart';", "import 'gestao/tela_kds.dart';\nimport 'gestao/tela_lista_pedidos.dart';")
content = content.replace("const Center(child: Text('Pedidos - Em Breve')),", "const TelaListaPedidos(),")

with open('lib/screens/shell_principal.dart', 'w', encoding='utf-8') as f:
    f.write(content)
