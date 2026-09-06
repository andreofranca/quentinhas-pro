import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Make the app start at TelaLogin
content = content.replace("home: TelaDashboardQuentinhas(whatsappService: whatsappService),", "home: const TelaLogin(),")

# Redirect to ShellPrincipal
content = content.replace("=> TelaDashboard(usuarioLogado: user)", "=> ShellPrincipal(usuarioLogado: user)")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
