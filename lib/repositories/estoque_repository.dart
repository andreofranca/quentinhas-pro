import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ingrediente.dart';

class EstoqueRepository {
  final SupabaseClient _supabase;

  EstoqueRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  Future<void> adicionarIngrediente(Ingrediente ingrediente) async {
    final payload = <String, dynamic>{
      'nome': ingrediente.nome,
      'unidade_medida': ingrediente.unidadeMedida.sigla,
      'estoque_atual': ingrediente.estoqueAtual,
      'estoque_minimo': ingrediente.estoqueMinimo,
      'custo_unitario': ingrediente.custoUnitario,
    };

    if (ingrediente.id.isNotEmpty) {
      payload['id'] = ingrediente.id;
    }

    await _supabase.from('ingredientes').insert(payload);
  }

  Future<void> adicionarIngredientesEmLote(List<Ingrediente> ingredientes) async {
    if (ingredientes.isEmpty) return;

    final payload = ingredientes.map((ingrediente) {
      final item = <String, dynamic>{
        'nome': ingrediente.nome,
        'unidade_medida': ingrediente.unidadeMedida.sigla,
        'estoque_atual': ingrediente.estoqueAtual,
        'estoque_minimo': ingrediente.estoqueMinimo,
        'custo_unitario': ingrediente.custoUnitario,
      };

      if (ingrediente.id.isNotEmpty) {
        item['id'] = ingrediente.id;
      }

      return item;
    }).toList();

    await _supabase.from('ingredientes').insert(payload);
  }

  Future<List<Ingrediente>> buscarIngredientes() async {
    final response = await _supabase.from('ingredientes').select();

    return (response as List<dynamic>)
        .map((data) => Ingrediente(
              id: data['id'].toString(),
              nome: data['nome'] as String,
              unidadeMedida:
                  UnidadeMedida.fromSigla(data['unidade_medida'] as String),
              estoqueAtual: (data['estoque_atual'] as num? ?? 0).toDouble(),
              estoqueMinimo: (data['estoque_minimo'] as num? ?? 0).toDouble(),
              custoUnitario: (data['custo_unitario'] as num? ?? 0).toDouble(),
            ))
        .toList();
  }

  Stream<List<Ingrediente>> observarIngredientes() {
    return _supabase
        .from('ingredientes')
        .stream(primaryKey: ['id'])
        .map((rows) => rows
            .map((data) => Ingrediente(
                  id: data['id'].toString(),
                  nome: data['nome'] as String,
                  unidadeMedida:
                      UnidadeMedida.fromSigla(data['unidade_medida'] as String),
                  estoqueAtual:
                      (data['estoque_atual'] as num? ?? 0).toDouble(),
                  estoqueMinimo:
                      (data['estoque_minimo'] as num? ?? 0).toDouble(),
                  custoUnitario:
                      (data['custo_unitario'] as num? ?? 0).toDouble(),
                ))
            .toList());
  }

  Future<void> registrarEntradaEstoque({
    required Ingrediente ingrediente,
    required double quantidadeEntrada,
    String observacao = '',
    DateTime? dataRegistro,
  }) async {
    if (quantidadeEntrada <= 0) {
      throw ArgumentError('A quantidade de entrada deve ser maior que zero.');
    }

    final estoqueAnterior = ingrediente.estoqueAtual;
    final estoqueAtual = estoqueAnterior + quantidadeEntrada;

    await _supabase
        .from('ingredientes')
        .update({'estoque_atual': estoqueAtual}).eq('id', ingrediente.id);

    await _supabase.from('movimentacoes_estoque').insert({
      'ingrediente_id': ingrediente.id,
      'ingrediente_nome': ingrediente.nome,
      'tipo_movimentacao': 'ENTRADA',
      'quantidade_movimentada': quantidadeEntrada,
      'estoque_anterior': estoqueAnterior,
      'estoque_atual': estoqueAtual,
      'observacao': observacao.trim(),
      'registrado_em': (dataRegistro ?? DateTime.now()).toIso8601String(),
    });
  }

  Future<void> registrarSaidaEstoque({
    required Ingrediente ingrediente,
    required double quantidadeSaida,
    String observacao = '',
    DateTime? dataRegistro,
  }) async {
    if (quantidadeSaida <= 0) {
      throw ArgumentError('A quantidade de saida deve ser maior que zero.');
    }

    final estoqueAnterior = ingrediente.estoqueAtual;
    if (quantidadeSaida > estoqueAnterior) {
      throw StateError('Saida maior que o estoque disponivel.');
    }

    final estoqueAtual = estoqueAnterior - quantidadeSaida;

    await _supabase
        .from('ingredientes')
        .update({'estoque_atual': estoqueAtual}).eq('id', ingrediente.id);

    await _supabase.from('movimentacoes_estoque').insert({
      'ingrediente_id': ingrediente.id,
      'ingrediente_nome': ingrediente.nome,
      'tipo_movimentacao': 'SAIDA',
      'quantidade_movimentada': quantidadeSaida,
      'estoque_anterior': estoqueAnterior,
      'estoque_atual': estoqueAtual,
      'observacao': observacao.trim(),
      'registrado_em': (dataRegistro ?? DateTime.now()).toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>> observarUltimasMovimentacoes({
    String? tipoMovimentacao,
    int limite = 20,
  }) {
    return _supabase
        .from('movimentacoes_estoque')
        .stream(primaryKey: ['id'])
        .map((rows) {
      final entradas = rows
          .where((row) {
            if (tipoMovimentacao == null || tipoMovimentacao.isEmpty) {
              return true;
            }
            return (row['tipo_movimentacao'] as String?) == tipoMovimentacao;
          })
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      entradas.sort((a, b) {
        final aData = DateTime.tryParse((a['registrado_em'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bData = DateTime.tryParse((b['registrado_em'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bData.compareTo(aData);
      });

      if (entradas.length > limite) {
        return entradas.sublist(0, limite);
      }
      return entradas;
    });
  }

  Stream<List<Map<String, dynamic>>> observarUltimasMovimentacoesEntrada({
    int limite = 20,
  }) {
    return observarUltimasMovimentacoes(
      tipoMovimentacao: 'ENTRADA',
      limite: limite,
    );
  }
}
