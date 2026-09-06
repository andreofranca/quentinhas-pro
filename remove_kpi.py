import re

with open('lib/screens/dashboard/tela_dashboard_quentinhas.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the call to _buildHeaderKPIs() in the build method
content = re.sub(r'_buildHeaderKPIs\(\),?', '', content)

with open('lib/screens/dashboard/tela_dashboard_quentinhas.dart', 'w', encoding='utf-8') as f:
    f.write(content)
