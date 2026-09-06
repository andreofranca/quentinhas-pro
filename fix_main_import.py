import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import 'screens/dashboard/tela_dashboard_quentinhas.dart';", "")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
