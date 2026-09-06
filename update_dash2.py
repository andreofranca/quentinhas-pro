import re

with open('lib/screens/dashboard/tela_dashboard_quentinhas.dart', 'r', encoding='utf-8') as f:
    content = f.read()

if "final Usuario? usuarioLogado;" not in content:
    content = content.replace("final WhatsAppService? whatsappService;", "final WhatsAppService? whatsappService;\n  final Usuario? usuarioLogado;")

# Also remove the Drawer
content = re.sub(r'drawer:\s*Drawer\([\s\S]*?body:', 'body:', content)

with open('lib/screens/dashboard/tela_dashboard_quentinhas.dart', 'w', encoding='utf-8') as f:
    f.write(content)
