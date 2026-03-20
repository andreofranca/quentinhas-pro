class ItemFichaTecnica {
  final String ingredienteId;
  final double quantidadeUtilizada;

  const ItemFichaTecnica({
    required this.ingredienteId,
    required this.quantidadeUtilizada,
  })  : assert(ingredienteId != ''),
        assert(quantidadeUtilizada > 0);

  ItemFichaTecnica copyWith({
    String? ingredienteId,
    double? quantidadeUtilizada,
  }) {
    return ItemFichaTecnica(
      ingredienteId: ingredienteId ?? this.ingredienteId,
      quantidadeUtilizada: quantidadeUtilizada ?? this.quantidadeUtilizada,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ingredienteId': ingredienteId,
      'quantidadeUtilizada': quantidadeUtilizada,
    };
  }

  factory ItemFichaTecnica.fromMap(Map<String, dynamic> map) {
    return ItemFichaTecnica(
      ingredienteId: map['ingredienteId'] as String,
      quantidadeUtilizada: (map['quantidadeUtilizada'] as num).toDouble(),
    );
  }
}
