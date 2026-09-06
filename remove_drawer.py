import re

with open('lib/screens/dashboard/tela_dashboard_quentinhas.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# carefully remove the drawer block
match = re.search(r'drawer:\s*Drawer\(.*?\),\s*body:', content, re.DOTALL)
if match:
    content = content.replace(match.group(0), 'body:')
    with open('lib/screens/dashboard/tela_dashboard_quentinhas.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Drawer removed successfully")
else:
    print("Drawer block not found")
