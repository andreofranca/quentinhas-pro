import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("export 'models/dominio.dart';", "import 'models/dominio.dart';\nexport 'models/dominio.dart';")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
