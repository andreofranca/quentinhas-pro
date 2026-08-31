with open("lib/main.dart", "r", encoding="utf-8") as f:
    content = f.read()

import re

new_beginning = """class _TelaGestaoProdutosState extends State<TelaGestaoProdutos> {
  final TextEditingController _buscaController = TextEditingController();
  String _categoriaFiltro = 'Todas';
  bool _isLoading = true;
  String? _erro;
  List<Produto> _produtos = [];
  final GestaoProdutosService _service = GestaoProdutosService();

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    setState(() { _isLoading = true; _erro = null; });
    try {
      final res = await _service.listarProdutos();
      if (mounted) {
        setState(() { _produtos = res; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _erro = e.toString(); _isLoading = false; });
      }
    }
  }

  Future<void> _excluirProduto(Produto p) async {
    try {
      await _service.deletarProduto(p.idProduto);
      _carregarProdutos();
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }"""

content = re.sub(
    r'class _TelaGestaoProdutosState extends State<TelaGestaoProdutos> \{\s*final TextEditingController _buscaController = TextEditingController\(\);\s*String _categoriaFiltro = \'Todas\';\s*List<Produto> _produtos = \[\];\s*bool _isLoading = false;\s*final _gestaoProdutosService = GestaoProdutosService\(\);\s*@override\s*void dispose\(\) \{',
    new_beginning + "\n\n  @override\n  void dispose() {",
    content,
    flags=re.MULTILINE
)

# Replace 'cardapio' with '_produtos' in _TelaGestaoProdutosState
content = content.replace("final categorias = cardapio.map((p) => p.categoria).toSet().toList()..sort();", "final categorias = _produtos.map((p) => p.categoria).toSet().toList()..sort();")
content = content.replace("final lista = cardapio.where(_atendeFiltros).toList();", "if (_isLoading) return const Center(child: CircularProgressIndicator());\n    if (_erro != null) return Center(child: Text(_erro!));\n    final lista = _produtos.where(_atendeFiltros).toList();")

# Replace item deletion
content = content.replace("onPressed: () => setState(() => cardapio.removeWhere((item) => item.idProduto == p.idProduto)),", "onPressed: () => _excluirProduto(p),")

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(content)
