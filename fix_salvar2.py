with open("lib/main.dart", "r", encoding="utf-8") as f:
    content = f.read()

import re

# Fix _salvarProduto in TelaCadastroProduto
new_salvar = """  bool _saving = false;
  
  Future<void> _salvarProduto() async {
    if (!_chaveForm.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final precoLimpo = double.tryParse(_preco.text.replaceAll(',', '.')) ?? 0.0;
      final estoqueLimpo = int.tryParse(_estoque.text) ?? 0;
      final imagemFinal = _imagemUrl.text.trim().isEmpty ? _imagemPadraoCategoria(_categoria) : _imagemUrl.text.trim();
      
      final data = {
        'nome': _nome.text,
        'descricao': _descricao.text,
        'precoBase': precoLimpo,
        'categoria': _categoria,
        'imagemUrl': imagemFinal,
        'estoqueAtual': estoqueLimpo,
        'estoqueMinimo': widget.produtoOriginal?.estoqueMinimo ?? 8
      };

      final service = GestaoProdutosService();
      if (widget.produtoOriginal != null) {
        await service.atualizarProduto(widget.produtoOriginal!.idProduto, data);
      } else {
        await service.criarProduto(data);
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }"""

content = re.sub(r'void _salvarProduto\(\) \{.*?if \(mounted\) Navigator\.pop\(context, true\);\n  \}', new_salvar, content, flags=re.DOTALL)

# Fix _excluirProduto
content = content.replace("await _service.deletarProduto(p.idProduto);", "await _service.desativarProduto(p.idProduto);")

# Fix onPressed
content = content.replace("onPressed: () => setState(() => cardapio.removeWhere((item) => item.idProduto == p.idProduto)),", "onPressed: () => _excluirProduto(p),")

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(content)
