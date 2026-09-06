import re

files = [
    'lib/screens/dashboard/tela_dashboard_real.dart',
    'lib/screens/gestao/tela_kds.dart',
    'lib/screens/gestao/tela_lista_pedidos.dart',
]

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace("import '../../main.dart';", "import '../../models/dominio.dart';")
    
    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)
