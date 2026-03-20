enum UnidadeMedida {
  un('UN'),
  kg('KG'),
  g('G'),
  l('L'),
  ml('ML');

  const UnidadeMedida(this.sigla);
  final String sigla;

  static UnidadeMedida fromSigla(String value) {
    final normalizado = value.trim().toUpperCase();
    return UnidadeMedida.values.firstWhere(
      (item) => item.sigla == normalizado,
      orElse: () => throw ArgumentError('Unidade de medida invalida: $value'),
    );
  }
}

class Ingrediente {
  final String id;
  final String nome;
  final UnidadeMedida unidadeMedida;
  final double estoqueAtual;
  final double estoqueMinimo;
  final double custoUnitario;

  const Ingrediente({
    required this.id,
    required this.nome,
    required this.unidadeMedida,
    required this.estoqueAtual,
    required this.estoqueMinimo,
    required this.custoUnitario,
  })  : assert(nome != ''),
        assert(estoqueAtual >= 0),
        assert(estoqueMinimo >= 0),
        assert(custoUnitario >= 0);

  bool get estoqueAbaixoDoMinimo => estoqueAtual <= estoqueMinimo;

  bool get semEstoque => estoqueAtual <= 0;

  double get valorTotalEmEstoque => estoqueAtual * custoUnitario;

  Ingrediente copyWith({
    String? id,
    String? nome,
    UnidadeMedida? unidadeMedida,
    double? estoqueAtual,
    double? estoqueMinimo,
    double? custoUnitario,
  }) {
    return Ingrediente(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      estoqueAtual: estoqueAtual ?? this.estoqueAtual,
      estoqueMinimo: estoqueMinimo ?? this.estoqueMinimo,
      custoUnitario: custoUnitario ?? this.custoUnitario,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'unidadeMedida': unidadeMedida.sigla,
      'estoqueAtual': estoqueAtual,
      'estoqueMinimo': estoqueMinimo,
      'custoUnitario': custoUnitario,
    };
  }

  factory Ingrediente.fromMap(Map<String, dynamic> map) {
    return Ingrediente(
      id: map['id'] as String,
      nome: map['nome'] as String,
      unidadeMedida: UnidadeMedida.fromSigla(map['unidadeMedida'] as String),
      estoqueAtual: (map['estoqueAtual'] as num).toDouble(),
      estoqueMinimo: (map['estoqueMinimo'] as num).toDouble(),
      custoUnitario: (map['custoUnitario'] as num).toDouble(),
    );
  }
}
