import re

with open('lib/screens/shell_principal.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import 'gestao/tela_lista_pedidos.dart';", "import 'gestao/tela_lista_pedidos.dart';\nimport 'gestao/tela_caixa.dart';")
content = content.replace("const Center(child: Text('Caixa - Em Breve (Modal ou Tela)')),", "const TelaCaixa(),")

with open('lib/screens/shell_principal.dart', 'w', encoding='utf-8') as f:
    f.write(content)
