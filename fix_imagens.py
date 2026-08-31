with open("lib/main.dart", "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("for (final produto in cardapio) {", "for (final produto in _produtos) {")

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(content)
