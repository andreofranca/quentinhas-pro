with open("backend/src/test/java/com/quentinhas/backend/controller/ProdutoIntegrationTest.java", "r", encoding="utf-8") as f:
    content = f.read()

import re
content = re.sub(r'new ProdutoRequest\(\s*"([^"]+)",\s*"([^"]+)",\s*"([^"]+)",\s*new BigDecimal\("([^"]+)"\),\s*10,\s*5\s*\)', r'new ProdutoRequest("\1", "\2", "\3", new BigDecimal("\4"), 10, 5, true)', content)

with open("backend/src/test/java/com/quentinhas/backend/controller/ProdutoIntegrationTest.java", "w", encoding="utf-8") as f:
    f.write(content)
