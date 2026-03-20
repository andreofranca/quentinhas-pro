import 'item_ficha_tecnica.dart';

class Produto {
  final String id;
  final String nome;
  final double precoVenda;
  final String categoria;
  final List<ItemFichaTecnica> fichaTecnica;

  const Produto({
    required this.id,
    required this.nome,
    required this.precoVenda,
    required this.categoria,
    this.fichaTecnica = const [],
  })  : assert(id != ''),
        assert(nome != ''),
        assert(precoVenda >= 0),
        assert(categoria != '');

  double calcularCustoProducao(Map<String, double> custoIngredientesMap) {
    var custoTotal = 0.0;
    for (final item in fichaTecnica) {
      final custoUnitario = custoIngredientesMap[item.ingredienteId] ?? 0.0;
      custoTotal += item.quantidadeUtilizada * custoUnitario;
    }
    return custoTotal;
  }

  Produto copyWith({
    String? id,
    String? nome,
    double? precoVenda,
    String? categoria,
    List<ItemFichaTecnica>? fichaTecnica,
  }) {
    return Produto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      precoVenda: precoVenda ?? this.precoVenda,
      categoria: categoria ?? this.categoria,
      fichaTecnica: fichaTecnica ?? this.fichaTecnica,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'precoVenda': precoVenda,
      'categoria': categoria,
      'fichaTecnica': fichaTecnica.map((item) => item.toMap()).toList(),
    };
  }

  factory Produto.fromMap(Map<String, dynamic> map) {
    final ficha = (map['fichaTecnica'] as List<dynamic>? ?? [])
        .map((item) => ItemFichaTecnica.fromMap(item as Map<String, dynamic>))
        .toList();

    return Produto(
      id: map['id'] as String,
      nome: map['nome'] as String,
      precoVenda: (map['precoVenda'] as num).toDouble(),
      categoria: map['categoria'] as String,
      fichaTecnica: ficha,
    );
  }
}
