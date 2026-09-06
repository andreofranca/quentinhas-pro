import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add ShellPrincipal import
if "import 'screens/shell_principal.dart';" not in content:
    content = content.replace("import 'screens/dashboard/tela_dashboard_quentinhas.dart';", "import 'screens/dashboard/tela_dashboard_quentinhas.dart';\nimport 'screens/shell_principal.dart';")

# Change login redirect
content = content.replace(
    "TelaDashboardQuentinhas(whatsappService: widget.whatsappService)",
    "ShellPrincipal(usuarioLogado: usuario!)"
)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
