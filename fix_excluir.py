with open("lib/main.dart", "r", encoding="utf-8") as f:
    content = f.read()

import re
content = re.sub(r'  Future<void> _excluirProduto\(Produto p\) async \{.*?\}\n  \}', "", content, flags=re.DOTALL)

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(content)
