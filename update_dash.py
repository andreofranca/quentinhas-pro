import re

with open('lib/screens/dashboard/tela_dashboard_quentinhas.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove its own Scaffold Drawer/AppBar if we are wrapping it in a Shell
# Wait, NO. If TelaDashboardQuentinhas is a full screen (with its own AppBar and side cart), 
# embedding it inside another Scaffold might look weird if both have AppBars.
# Since it's a PDV, maybe it shouldn't have the drawer inside itself anymore.
content = re.sub(r'drawer:\s*Drawer\([^)]+\),?', '', content)

if "final Usuario usuarioLogado;" not in content:
    content = content.replace("final WhatsappService? whatsappService;", "final WhatsappService? whatsappService;\n  final Usuario? usuarioLogado;")
    content = content.replace("const TelaDashboardQuentinhas({super.key, this.whatsappService});", "const TelaDashboardQuentinhas({super.key, this.whatsappService, this.usuarioLogado});")

with open('lib/screens/dashboard/tela_dashboard_quentinhas.dart', 'w', encoding='utf-8') as f:
    f.write(content)
