with open("lib/main.dart", "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("String _categoriaFiltro = 'Todas';", "String _categoriaFiltro = 'Todas';\n  List<Produto> _produtos = [];\n  bool _isLoading = false;\n  final _gestaoProdutosService = GestaoProdutosService();")

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(content)
