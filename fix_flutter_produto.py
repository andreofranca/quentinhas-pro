with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("preco: (json['precoBase'] ?? 0).toDouble(),\n      ativo: json['ativo'] ?? true,", "preco: (json['precoBase'] ?? 0).toDouble(),\n      estoqueAtual: json['estoqueAtual'] ?? estoqueDefault,\n      estoqueMinimo: json['estoqueMinimo'] ?? 8,\n      ativo: json['ativo'] ?? true,")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
