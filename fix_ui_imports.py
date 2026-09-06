with open('lib/screens/dashboard/tela_dashboard_quentinhas.dart', 'r', encoding='utf-8') as f:
    content = f.read()

if "import '../../models/dominio.dart';" not in content:
    content = content.replace("import '../../models/models_quentinha.dart';", "import '../../models/models_quentinha.dart';\nimport '../../models/dominio.dart';")
    with open('lib/screens/dashboard/tela_dashboard_quentinhas.dart', 'w', encoding='utf-8') as f:
        f.write(content)

with open('lib/screens/shell_principal.dart', 'r', encoding='utf-8') as f:
    content = f.read()

if "import '../models/dominio.dart';" not in content:
    content = content.replace("import '../main.dart';", "import '../main.dart';\nimport '../models/dominio.dart';")
    with open('lib/screens/shell_principal.dart', 'w', encoding='utf-8') as f:
        f.write(content)
