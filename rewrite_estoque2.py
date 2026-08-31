import re

with open("lib/main.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Add import
if "import 'services/gestao_estoque_service.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'services/gestao_estoque_service.dart';")

new_beginning = """class _TelaControleEstoqueRapidoState extends State<TelaControleEstoqueRapido> {
  final TextEditingController _buscaController = TextEditingController();
  final _service = GestaoEstoqueService();
  String _filtroCategoria = 'Todas';
  bool _mostrarApenasAlertas = false;
  bool _simulacaoReajusteAtiva = false;
  double _reajustePercentual = 0;
  
  List<Produto> _estoque = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarEstoque();
  }

  Future<void> _carregarEstoque() async {
    setState(() => _loading = true);
    try {
      final res = await _service.listarEstoque();
      setState(() {
        _estoque = res;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar estoque: $e')));
      }
    }
  }

  Future<void> _atualizar(Produto p, int novoAtual) async {
    try {
      await _service.atualizarEstoque(p.idProduto, novoAtual, p.estoqueMinimo);
      setState(() {
        p.estoqueAtual = novoAtual;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar estoque: $e')));
      }
    }
  }"""

content = re.sub(
    r'class _TelaControleEstoqueRapidoState extends State<TelaControleEstoqueRapido> \{\s*final TextEditingController _buscaController = TextEditingController\(\);\s*String _filtroCategoria = \'Todas\';\s*bool _mostrarApenasAlertas = false;\s*bool _simulacaoReajusteAtiva = false;\s*double _reajustePercentual = 0;',
    new_beginning,
    content,
    flags=re.MULTILINE
)

content = content.replace("final categorias = cardapio.map((p) => p.categoria).toSet().toList()..sort();", "final categorias = _estoque.map((p) => p.categoria).toSet().toList()..sort();")

content = content.replace(
    "final listaOrdenada = [...cardapio]..sort((a, b) => a.estoqueAtual.compareTo(b.estoqueAtual));",
    "if (_loading) return const Center(child: CircularProgressIndicator());\n    final listaOrdenada = [..._estoque]..sort((a, b) => a.estoqueAtual.compareTo(b.estoqueAtual));"
)

content = content.replace(
    "onPressed: p.estoqueAtual <= 0 ? null : () => setState(() => p.estoqueAtual--),",
    "onPressed: p.estoqueAtual <= 0 ? null : () => _atualizar(p, p.estoqueAtual - 1),"
)
content = content.replace(
    "onPressed: () => setState(() => p.estoqueAtual++),",
    "onPressed: () => _atualizar(p, p.estoqueAtual + 1),"
)

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(content)
