import re

with open('lib/screens/shell_principal.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import 'dashboard/tela_dashboard_quentinhas.dart';", "import 'dashboard/tela_dashboard_quentinhas.dart';\nimport 'dashboard/tela_dashboard_real.dart';")
content = content.replace("const Center(child: Text('Dashboard Análises - Em Breve')),", "const TelaDashboardReal(),")

with open('lib/screens/shell_principal.dart', 'w', encoding='utf-8') as f:
    f.write(content)
