import re

with open('test/tela_login_test.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import 'package:lanchonete_controle/main.dart';", "import 'package:lanchonete_controle/main.dart';\nimport 'package:lanchonete_controle/screens/shell_principal.dart';")
content = content.replace("find.byType(TelaDashboard)", "find.byType(ShellPrincipal)")

with open('test/tela_login_test.dart', 'w', encoding='utf-8') as f:
    f.write(content)
