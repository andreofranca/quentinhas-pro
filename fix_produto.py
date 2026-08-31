import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

produto_old = """class Produto {
  final String idProduto;
  String nome, descricao, categoria, imagemUrl;
  double preco;
  int estoqueAtual;
  int estoqueMinimo; // Nível mínimo de alerta: abaixo disso = Crítico

  Produto({
    required this.idProduto,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.categoria,
    required this.imagemUrl,
    this.estoqueAtual = estoqueDefault,
    this.estoqueMinimo = 8,
  });
}"""

produto_new = """class Produto {
  final String idProduto;
  String nome, descricao, categoria, imagemUrl;
  double preco;
  int estoqueAtual;
  int estoqueMinimo; // Nível mínimo de alerta: abaixo disso = Crítico
  bool ativo;

  Produto({
    required this.idProduto,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.categoria,
    required this.imagemUrl,
    this.estoqueAtual = estoqueDefault,
    this.estoqueMinimo = 8,
    this.ativo = true,
  });

  factory Produto.fromJsonFull(Map<String, dynamic> json) {
    return Produto(
      idProduto: json['id'] ?? '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      categoria: json['categoria'] ?? '',
      imagemUrl: '',
      preco: (json['precoBase'] ?? 0).toDouble(),
      ativo: json['ativo'] ?? true,
    );
  }
}"""

content = content.replace(produto_old, produto_new)

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)
