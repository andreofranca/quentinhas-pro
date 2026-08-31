import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()
    
# Remove old class TelaGestaoProdutos and TelaCadastroProduto completely
match = re.search(r'class TelaGestaoProdutos extends StatefulWidget \{.*?class _TelaCadastroProdutoState extends State<TelaCadastroProduto> \{.*?\n\}\n\}', content, re.DOTALL)

new_code = """import 'services/gestao_produtos_service.dart';

class TelaGestaoProdutos extends StatefulWidget { const TelaGestaoProdutos({super.key}); @override State<TelaGestaoProdutos> createState() => _TelaGestaoProdutosState(); }
class _TelaGestaoProdutosState extends State<TelaGestaoProdutos> {
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

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarProdutos() async {
    setState(() { _isLoading = true; _erro = null; });
    try {
      final produtos = await _service.listarProdutos();
      if (!mounted) return;
      setState(() { _produtos = produtos; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _erro = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _desativarProduto(String id) async {
    try {
      await _service.desativarProduto(id);
      _carregarProdutos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao desativar: $e'), backgroundColor: Colors.red));
    }
  }

  bool _atendeFiltros(Produto p) {
    final busca = _buscaController.text.trim().toLowerCase();
    final categoriaOk = _categoriaFiltro == 'Todas' || p.categoria == _categoriaFiltro;
    final buscaOk = busca.isEmpty || p.nome.toLowerCase().contains(busca);
    return categoriaOk && buscaOk;
  }

  @override
  Widget build(BuildContext context) {
    final categorias = _produtos.map((p) => p.categoria).toSet().toList()..sort();
    final lista = _produtos.where(_atendeFiltros).toList();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cadastro de Produtos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarProdutos),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaCadastroProduto())).then((_) => _carregarProdutos()),
                    icon: const Icon(Icons.add),
                    label: const Text('NOVO PRODUTO'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: _buscaController, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Buscar produto', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _categoriaFiltro,
                    items: ['Todas', ...categorias].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _categoriaFiltro = v ?? 'Todas'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _erro != null 
                    ? Center(child: Text(_erro!, style: const TextStyle(color: Colors.red)))
                    : ListView.builder(
                        itemCount: lista.length,
                        itemBuilder: (context, index) {
                          final p = lista[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(width: 52, height: 52, child: Container(color: p.ativo ? Colors.green : Colors.grey, child: const Icon(Icons.fastfood, color: Colors.white))),
                              ),
                              title: Text(p.nome, style: TextStyle(fontWeight: FontWeight.bold, decoration: p.ativo ? null : TextDecoration.lineThrough)),
                              subtitle: Text('${p.categoria} | R\$ ${p.preco.toStringAsFixed(2).replaceAll('.', ',')} | Estoque: ${p.estoqueAtual}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TelaCadastroProduto(produtoOriginal: p))).then((_) => _carregarProdutos())),
                                  if (p.ativo)
                                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _desativarProduto(p.idProduto)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class TelaCadastroProduto extends StatefulWidget { final Produto? produtoOriginal; const TelaCadastroProduto({super.key, this.produtoOriginal}); @override State<TelaCadastroProduto> createState() => _TelaCadastroProdutoState(); }
class _TelaCadastroProdutoState extends State<TelaCadastroProduto> {
  final _chaveForm = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _descricao = TextEditingController();
  final _preco = TextEditingController();
  String _categoria = 'Lanches';
  bool _isLoading = false;
  final GestaoProdutosService _service = GestaoProdutosService();

  @override void initState() {
    super.initState();
    if (widget.produtoOriginal != null) {
      final p = widget.produtoOriginal!;
      _nome.text = p.nome;
      _descricao.text = p.descricao;
      _categoria = p.categoria;
      _preco.text = p.preco.toStringAsFixed(2);
    }
  }

  Future<void> _salvarProduto() async {
    if (_chaveForm.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final data = {
          'nome': _nome.text,
          'descricao': _descricao.text,
          'categoria': _categoria,
          'precoBase': double.parse(_preco.text.replaceAll(',', '.')),
          'ativo': true
        };
        
        if (widget.produtoOriginal != null) {
          await _service.atualizarProduto(widget.produtoOriginal!.idProduto, data);
        } else {
          await _service.criarProduto(data);
        }
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  @override Widget build(BuildContext context) {
    bool ehEdicao = widget.produtoOriginal != null;
    return Scaffold(
      appBar: AppBar(title: Text(ehEdicao ? 'Editar Produto' : 'Novo Produto')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _chaveForm,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ficha do Produto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 15),
                  TextFormField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome do Produto *'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _categoria,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: ['Lanches', 'Porções', 'Bebidas', 'Sobremesas'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _categoria = v!),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(controller: _descricao, maxLines: 3, decoration: const InputDecoration(labelText: 'Descrição *'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _preco, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Preço Base (R$) *'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.cancel), label: const Text('CANCELAR')),
                      const SizedBox(width: 15),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        onPressed: _isLoading ? null : _salvarProduto,
                        icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.save),
                        label: const Text('SALVAR PRODUTO'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}"""

content = re.sub(r'class TelaGestaoProdutos extends StatefulWidget \{.*?class _TelaCadastroProdutoState extends State<TelaCadastroProduto> \{.*?\n\}\n\}', new_code, content, flags=re.DOTALL)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
