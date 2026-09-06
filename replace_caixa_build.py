import re

with open('lib/screens/gestao/tela_caixa.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace build method
match = re.search(r'@override Widget build\(BuildContext context\) \{.*', content, re.DOTALL)
if match:
    with open('fix_caixa_build.txt', 'r', encoding='utf-8') as f_build:
        build_content = f_build.read()
    content = content.replace(match.group(0), build_content)
    with open('lib/screens/gestao/tela_caixa.dart', 'w', encoding='utf-8') as f:
        f.write(content)
        
