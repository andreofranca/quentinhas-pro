import re

with open('lib/models/dominio.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("const int estoqueDefault = 50;", "import '../constants.dart';")

with open('lib/models/dominio.dart', 'w', encoding='utf-8') as f:
    f.write(content)
