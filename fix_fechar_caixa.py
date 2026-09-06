import re

with open('lib/screens/gestao/tela_caixa.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("await _service.fecharCaixa(_caixaAbertoId!);", "await _service.fecharCaixa(0.0);")

with open('lib/screens/gestao/tela_caixa.dart', 'w', encoding='utf-8') as f:
    f.write(content)
