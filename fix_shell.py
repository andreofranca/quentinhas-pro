import re

with open('lib/screens/shell_principal.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import '../models/usuario.dart';", "")

with open('lib/screens/shell_principal.dart', 'w', encoding='utf-8') as f:
    f.write(content)
