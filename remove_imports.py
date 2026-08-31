import re
with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import 'dart:convert';\n", "")
content = content.replace("import 'package:http/http.dart' as http;\n", "")
content = content.replace("import 'screens/teste_estoque_screen.dart';\n", "")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
