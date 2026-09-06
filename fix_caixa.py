import re

with open('lib/screens/gestao/tela_caixa.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("Card(\n          padding: const EdgeInsets.all(32),\n          child: Column(", "Card(\n          child: Padding(\n            padding: const EdgeInsets.all(32),\n            child: Column(")
content = content.replace("]\n          ),\n        )", "]\n          ),\n          ),\n        )")

with open('lib/screens/gestao/tela_caixa.dart', 'w', encoding='utf-8') as f:
    f.write(content)
