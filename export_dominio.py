import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import 'models/dominio.dart';", "export 'models/dominio.dart';")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
