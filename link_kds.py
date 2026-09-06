import re

with open('lib/screens/shell_principal.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import '../main.dart';", "import '../main.dart';\nimport 'gestao/tela_kds.dart';")
content = content.replace("const TelaGestaoPedidos(),", "const TelaKDS(),")

with open('lib/screens/shell_principal.dart', 'w', encoding='utf-8') as f:
    f.write(content)
