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
      
      final p = Produto(
        idProduto: widget.produtoOriginal?.idProduto ?? '',
        nome: _nome.text,
        descricao: _descricao.text,
        preco: precoLimpo,
        categoria: _categoria,
        imagemUrl: imagemFinal,
        estoqueAtual: estoqueLimpo,
      );

      final service = GestaoProdutosService();
      if (widget.produtoOriginal != null) {
        await service.atualizarProduto(p);
      } else {
        await service.criarProduto(p);
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }"""

content = re.sub(r'void _salvarProduto\(\) \{.*?if \(mounted\) Navigator\.pop\(context, true\);\n  \}', new_salvar, content, flags=re.DOTALL)

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(content)
