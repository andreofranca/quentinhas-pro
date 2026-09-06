import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Extract from "class Produto {" to "} // end Usuario" (approximately)
# I will use a regex to capture everything from "class Produto {" up to the line right before "// --- 2. BANCOS DE DADOS TEMPORÁRIOS ---"
match = re.search(r'class Produto \{.*?(?=\n// --- 2\. BANCOS DE DADOS TEMPORÁRIOS ---)', content, re.DOTALL)
if match:
    models_code = match.group(0)
    with open('lib/models/dominio.dart', 'w', encoding='utf-8') as f:
        f.write("import 'package:flutter/material.dart';\n\nconst int estoqueDefault = 50;\n\n")
        f.write(models_code)
    
    # Remove from main.dart
    content = content.replace(models_code, "")
    
    # Add import to main.dart
    content = content.replace("import 'formatters.dart';", "import 'formatters.dart';\nimport 'models/dominio.dart';")
    
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Models extracted successfully.")
else:
    print("Could not find models in main.dart")

