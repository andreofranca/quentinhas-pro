with open("lib/main.dart", "r", encoding="utf-8") as f:
    content = f.read()

import re

# Add imports
if "import 'services/gestao_produtos_service.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'services/gestao_produtos_service.dart';")

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(content)
