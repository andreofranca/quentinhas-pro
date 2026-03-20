import 'package:flutter/material.dart';

import '../models/ingrediente.dart';
import '../repositories/estoque_repository.dart';

class TelaTesteEstoque extends StatefulWidget {
  const TelaTesteEstoque({super.key});

  @override
  State<TelaTesteEstoque> createState() => _TelaTesteEstoqueState();
}

class _TelaTesteEstoqueState extends State<TelaTesteEstoque> {
  final EstoqueRepository _repository = EstoqueRepository();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _buscaController = TextEditingController();
  final TextEditingController _estoqueAtualController =
      TextEditingController(text: '10');
  final TextEditingController _estoqueMinimoController =
      TextEditingController(text: '2');
  final TextEditingController _custoUnitarioController =
      TextEditingController(text: '5.50');
    final TextEditingController _entradaQuantidadeController =
      TextEditingController(text: '1');
    final TextEditingController _entradaObservacaoController =
      TextEditingController();
      final TextEditingController _saidaQuantidadeController =
        TextEditingController(text: '1');
      final TextEditingController _saidaObservacaoController =
        TextEditingController();
  UnidadeMedida _unidadeSelecionada = UnidadeMedida.un;
  String _categoriaSelecionada = 'Todas';
  String _periodoMovimentacaoSelecionado = '7 dias';
  String? _ingredienteEntradaId;
  bool _carregandoLote = false;
    bool _salvandoEntrada = false;
  bool _salvandoSaida = false;

  Future<void> _salvarIngrediente() async {
    if (_nomeController.text.trim().isEmpty) return;

    final estoqueAtual = double.tryParse(_estoqueAtualController.text) ?? 0;
    final estoqueMinimo = double.tryParse(_estoqueMinimoController.text) ?? 0;
    final custoUnitario = double.tryParse(_custoUnitarioController.text) ?? 0;

    final novoIngrediente = Ingrediente(
      id: '',
      nome: _nomeController.text.trim(),
      unidadeMedida: _unidadeSelecionada,
      estoqueAtual: estoqueAtual,
      estoqueMinimo: estoqueMinimo,
      custoUnitario: custoUnitario,
    );

    await _repository.adicionarIngrediente(novoIngrediente);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${novoIngrediente.nome} salvo com sucesso.'),
      ),
    );
    _nomeController.clear();
  }

  Future<void> _popularBaseGrandePorte() async {
    setState(() => _carregandoLote = true);

    try {
      final existentes = await _repository.buscarIngredientes();
      final nomesExistentes = existentes
          .map((item) => item.nome.toLowerCase().trim())
          .toSet();

      final lote = _ingredientesGrandePorte.where((item) {
        return !nomesExistentes.contains(item.nome.toLowerCase().trim());
      }).toList();

      await _repository.adicionarIngredientesEmLote(lote);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lote.isEmpty
                ? 'Base grande porte ja estava cadastrada.'
                : '${lote.length} ingredientes inseridos na base.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _carregandoLote = false);
      }
    }
  }

  Future<void> _registrarEntrada(List<Ingrediente> ingredientes) async {
    final ingredienteId = _ingredienteEntradaId;
    final quantidade =
        double.tryParse(_entradaQuantidadeController.text.replaceAll(',', '.')) ??
            0;

    if (ingredienteId == null || ingredienteId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o ingrediente para entrada.')),
      );
      return;
    }

    if (quantidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma quantidade maior que zero.')),
      );
      return;
    }

    final ingrediente = ingredientes.firstWhere(
      (item) => item.id == ingredienteId,
      orElse: () => throw StateError('Ingrediente nao encontrado.'),
    );

    setState(() => _salvandoEntrada = true);
    try {
      await _repository.registrarEntradaEstoque(
        ingrediente: ingrediente,
        quantidadeEntrada: quantidade,
        observacao: _entradaObservacaoController.text,
      );

      if (!mounted) return;
      _entradaQuantidadeController.text = '1';
      _entradaObservacaoController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Entrada registrada: ${ingrediente.nome} (+${quantidade.toStringAsFixed(2)} ${ingrediente.unidadeMedida.sigla}).',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _salvandoEntrada = false);
      }
    }
  }

  Future<void> _registrarSaida(List<Ingrediente> ingredientes) async {
    final ingredienteId = _ingredienteEntradaId;
    final quantidade =
        double.tryParse(_saidaQuantidadeController.text.replaceAll(',', '.')) ?? 0;

    if (ingredienteId == null || ingredienteId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o ingrediente para saida.')),
      );
      return;
    }

    if (quantidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma quantidade maior que zero.')),
      );
      return;
    }

    final ingrediente = ingredientes.firstWhere(
      (item) => item.id == ingredienteId,
      orElse: () => throw StateError('Ingrediente nao encontrado.'),
    );

    if (quantidade > ingrediente.estoqueAtual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saida maior que o estoque atual do item.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _salvandoSaida = true);
    try {
      await _repository.registrarSaidaEstoque(
        ingrediente: ingrediente,
        quantidadeSaida: quantidade,
        observacao: _saidaObservacaoController.text,
      );

      if (!mounted) return;
      _saidaQuantidadeController.text = '1';
      _saidaObservacaoController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saida registrada: ${ingrediente.nome} (-${quantidade.toStringAsFixed(2)} ${ingrediente.unidadeMedida.sigla}).',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _salvandoSaida = false);
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _buscaController.dispose();
    _estoqueAtualController.dispose();
    _estoqueMinimoController.dispose();
    _custoUnitarioController.dispose();
    _entradaQuantidadeController.dispose();
    _entradaObservacaoController.dispose();
    _saidaQuantidadeController.dispose();
    _saidaObservacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6F8FC), Color(0xFFE8ECF6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<Ingrediente>>(
            stream: _repository.observarIngredientes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Erro ao carregar: ${snapshot.error}'),
                );
              }

              final ingredientes = snapshot.data ?? const <Ingrediente>[];
              final criticos =
                  ingredientes.where((item) => item.estoqueAbaixoDoMinimo).length;
              final categorias = _categoriasDisponiveis(ingredientes);
              final ingredientesFiltrados = ingredientes
                  .where(_atendeBuscaEFiltro)
                  .toList()
                ..sort((a, b) => a.nome.compareTo(b.nome));
              final valorTotalFiltrado = ingredientesFiltrados.fold<double>(
                0,
                (soma, item) => soma + item.valorTotalEmEstoque,
              );

              if (_ingredienteEntradaId == null && ingredientes.isNotEmpty) {
                _ingredienteEntradaId = ingredientes.first.id;
              }

              final ingredienteEntradaSelecionado = ingredientes
                  .where((item) => item.id == _ingredienteEntradaId)
                  .cast<Ingrediente?>()
                  .firstOrNull;

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F9D58), Color(0xFF087F4A)],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Painel de Estoque em Tempo Real',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Base completa para apresentacao de lanchonete de grande porte.',
                          style: TextStyle(
                            color: Colors.white.withAlpha(220),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _buildKpiChip(
                              icon: Icons.inventory_2,
                              label:
                                  'Visiveis: ${ingredientesFiltrados.length}/${ingredientes.length}',
                            ),
                            _buildKpiChip(
                              icon: Icons.warning_amber_rounded,
                              label: 'Criticos: $criticos',
                            ),
                            _buildKpiChip(
                              icon: Icons.payments,
                              label:
                                  'Valor: R\$ ${valorTotalFiltrado.toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _nomeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nome do ingrediente',
                                      hintText: 'Ex: Pao Brioche, Cheddar Fatiado',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<UnidadeMedida>(
                                          initialValue: _unidadeSelecionada,
                                          decoration: const InputDecoration(
                                            labelText: 'Unidade',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: UnidadeMedida.values
                                              .map(
                                                (item) => DropdownMenuItem(
                                                  value: item,
                                                  child: Text(item.sigla),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() {
                                                _unidadeSelecionada = value;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: _estoqueAtualController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'Estoque atual',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _estoqueMinimoController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'Estoque minimo',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: _custoUnitarioController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'Custo unitario (R\$)',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _salvarIngrediente,
                                        icon: const Icon(Icons.save),
                                        label: const Text('Salvar ingrediente'),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: _carregandoLote
                                            ? null
                                            : _popularBaseGrandePorte,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0A66C2),
                                          foregroundColor: Colors.white,
                                        ),
                                        icon: _carregandoLote
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(Icons.dataset),
                                        label: Text(
                                          _carregandoLote
                                              ? 'Carregando...'
                                              : 'Popular base grande porte',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Entrada de Estoque (com historico)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Registre entradas informando o que ja existia e o que esta entrando agora.',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    initialValue: _ingredienteEntradaId,
                                    decoration: const InputDecoration(
                                      labelText: 'Ingrediente',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: ingredientes
                                        .map(
                                          (item) => DropdownMenuItem(
                                            value: item.id,
                                            child: Text(
                                              '${item.nome} (${item.unidadeMedida.sigla})',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _ingredienteEntradaId = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _entradaQuantidadeController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'Quantidade de entrada',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: _entradaObservacaoController,
                                          decoration: const InputDecoration(
                                            labelText: 'Observacao (nota, fornecedor)',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  if (ingredienteEntradaSelecionado != null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F8FF),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFFBFD1FF),
                                        ),
                                      ),
                                      child: Text(
                                        'Estoque atual do item: ${ingredienteEntradaSelecionado.estoqueAtual.toStringAsFixed(2)} ${ingredienteEntradaSelecionado.unidadeMedida.sigla} | Data do registro: ${_formatarDataHora(DateTime.now())}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF243B6B),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: _salvandoEntrada
                                        ? null
                                        : () => _registrarEntrada(ingredientes),
                                    icon: _salvandoEntrada
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.move_down),
                                    label: Text(
                                      _salvandoEntrada
                                          ? 'Registrando entrada...'
                                          : 'Registrar entrada',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Saida de Estoque (quebra/perda/ajuste)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Registre reducoes de estoque com motivo para manter auditoria completa.',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _saidaQuantidadeController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'Quantidade de saida',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: _saidaObservacaoController,
                                          decoration: const InputDecoration(
                                            labelText: 'Motivo (quebra, perda, ajuste)',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: _salvandoSaida
                                        ? null
                                        : () => _registrarSaida(ingredientes),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: _salvandoSaida
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.move_up),
                                    label: Text(
                                      _salvandoSaida
                                          ? 'Registrando saida...'
                                          : 'Registrar saida',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _repository.observarUltimasMovimentacoes(
                              limite: 250,
                            ),
                            builder: (context, movimentoSnapshot) {
                              final movimentos = movimentoSnapshot.data ??
                                  const <Map<String, dynamic>>[];
                              final movimentosFiltrados = movimentos
                                  .where((mov) =>
                                      _atendePeriodoMovimentacao(mov))
                                  .toList();

                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Ultimas movimentacoes de estoque',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: ['Hoje', '7 dias', '30 dias', 'Todos']
                                            .map(
                                              (periodo) => ChoiceChip(
                                                label: Text(periodo),
                                                selected:
                                                    _periodoMovimentacaoSelecionado ==
                                                        periodo,
                                                onSelected: (_) {
                                                  setState(() {
                                                    _periodoMovimentacaoSelecionado =
                                                        periodo;
                                                  });
                                                },
                                              ),
                                            )
                                            .toList(),
                                      ),
                                      const SizedBox(height: 10),
                                      if (movimentosFiltrados.isEmpty)
                                        const Text(
                                          'Nenhuma movimentacao para o periodo selecionado.',
                                          style: TextStyle(color: Colors.black54),
                                        )
                                      else
                                        ...movimentosFiltrados.map((mov) {
                                          final nome =
                                              (mov['ingrediente_nome'] ?? '-')
                                                  .toString();
                                            final tipo =
                                              (mov['tipo_movimentacao'] ?? '-')
                                                .toString();
                                          final qtd =
                                              (mov['quantidade_movimentada']
                                                          as num? ??
                                                      0)
                                                  .toDouble();
                                          final anterior =
                                              (mov['estoque_anterior'] as num? ??
                                                      0)
                                                  .toDouble();
                                          final atual =
                                              (mov['estoque_atual'] as num? ?? 0)
                                                  .toDouble();
                                          final data = DateTime.tryParse(
                                            (mov['registrado_em'] ?? '')
                                                .toString(),
                                          );
                                          final obs =
                                              (mov['observacao'] ?? '').toString();
                                            final isEntrada = tipo == 'ENTRADA';

                                          return Container(
                                            width: double.infinity,
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(0xFFE1E6F0),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  nome,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Tipo: $tipo',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: isEntrada
                                                        ? Colors.green
                                                        : Colors.orange,
                                                  ),
                                                ),
                                                Text(
                                                  'Anterior: ${anterior.toStringAsFixed(2)} | Mov.: ${isEntrada ? '+' : '-'}${qtd.toStringAsFixed(2)} | Atual: ${atual.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                Text(
                                                  'Data: ${_formatarDataHora(data ?? DateTime.now())}${obs.isEmpty ? '' : ' | Obs: $obs'}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _buscaController,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      prefixIcon: Icon(Icons.search),
                                      labelText: 'Buscar ingrediente por nome',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: categorias
                                          .map(
                                            (categoria) => ChoiceChip(
                                              label: Text(categoria),
                                              selected: _categoriaSelecionada ==
                                                  categoria,
                                              onSelected: (_) {
                                                setState(() {
                                                  _categoriaSelecionada =
                                                      categoria;
                                                });
                                              },
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (ingredientesFiltrados.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Nenhum ingrediente encontrado para os filtros selecionados.',
                                ),
                              ),
                            )
                          else
                            ...ingredientesFiltrados.map(
                              (ing) => Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: ing.estoqueAbaixoDoMinimo
                                        ? const Color(0xFFFFD8D8)
                                        : const Color(0xFFD9F2E6),
                                    child: Icon(
                                      ing.estoqueAbaixoDoMinimo
                                          ? Icons.priority_high
                                          : Icons.kitchen,
                                      color: ing.estoqueAbaixoDoMinimo
                                          ? const Color(0xFFC1121F)
                                          : const Color(0xFF0B6E4F),
                                    ),
                                  ),
                                  title: Text(
                                    ing.nome,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Unidade: ${ing.unidadeMedida.sigla}  |  Estoque: ${ing.estoqueAtual.toStringAsFixed(2)}  |  Minimo: ${ing.estoqueMinimo.toStringAsFixed(2)}  |  Custo: R\$ ${ing.custoUnitario.toStringAsFixed(2)}',
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ing.estoqueAbaixoDoMinimo
                                          ? const Color(0xFFFFEAEA)
                                          : colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      ing.estoqueAbaixoDoMinimo
                                          ? 'Critico'
                                          : 'Ok',
                                      style: TextStyle(
                                        color: ing.estoqueAbaixoDoMinimo
                                            ? const Color(0xFFC1121F)
                                            : colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  isThreeLine: true,
                                  dense: false,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildKpiChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(34),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatarDataHora(DateTime dataHora) {
    final dia = dataHora.day.toString().padLeft(2, '0');
    final mes = dataHora.month.toString().padLeft(2, '0');
    final ano = dataHora.year.toString();
    final hora = dataHora.hour.toString().padLeft(2, '0');
    final minuto = dataHora.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$ano $hora:$minuto';
  }

  bool _atendePeriodoMovimentacao(Map<String, dynamic> mov) {
    final data =
        DateTime.tryParse((mov['registrado_em'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
    final agora = DateTime.now();

    switch (_periodoMovimentacaoSelecionado) {
      case 'Hoje':
        return data.year == agora.year &&
            data.month == agora.month &&
            data.day == agora.day;
      case '7 dias':
        return data.isAfter(agora.subtract(const Duration(days: 7)));
      case '30 dias':
        return data.isAfter(agora.subtract(const Duration(days: 30)));
      case 'Todos':
      default:
        return true;
    }
  }

  bool _atendeBuscaEFiltro(Ingrediente item) {
    final busca = _buscaController.text.trim().toLowerCase();
    final nome = item.nome.toLowerCase();
    final categoria = _categoriaDoIngrediente(item);
    final atendeBusca = busca.isEmpty || nome.contains(busca);
    final atendeCategoria =
        _categoriaSelecionada == 'Todas' || categoria == _categoriaSelecionada;
    return atendeBusca && atendeCategoria;
  }

  List<String> _categoriasDisponiveis(List<Ingrediente> ingredientes) {
    final categorias = ingredientes
        .map(_categoriaDoIngrediente)
        .toSet()
        .toList()
      ..sort();
    return ['Todas', ...categorias];
  }

  String _categoriaDoIngrediente(Ingrediente item) {
    final nome = item.nome.toLowerCase();
    if (nome.contains('embalagem') ||
        nome.contains('guardanapo') ||
        nome.contains('luva')) {
      return 'Embalagens e Limpeza';
    }
    if (nome.contains('refrigerante') || nome.contains('suco')) {
      return 'Bebidas';
    }
    if (nome.contains('molho') ||
        nome.contains('ketchup') ||
        nome.contains('mostarda') ||
        nome.contains('maionese')) {
      return 'Molhos';
    }
    if (nome.contains('sorvete') ||
        nome.contains('brownie') ||
        nome.contains('calda') ||
        nome.contains('ovomaltine') ||
        nome.contains('chantilly')) {
      return 'Sobremesas';
    }
    if (nome.contains('pao') ||
        nome.contains('hamburguer') ||
        nome.contains('frango') ||
        nome.contains('bacon')) {
      return 'Proteinas e Paes';
    }
    if (nome.contains('cheddar') ||
        nome.contains('mussarela') ||
        nome.contains('presunto') ||
        nome.contains('leite')) {
      return 'Frios e Laticinios';
    }
    if (nome.contains('alface') ||
        nome.contains('tomate') ||
        nome.contains('cebola') ||
        nome.contains('picles')) {
      return 'Hortifruti';
    }
    if (nome.contains('batata') ||
        nome.contains('nuggets') ||
        nome.contains('anel de cebola')) {
      return 'Porcoes';
    }
    if (nome.contains('oleo') || nome.contains('gas')) {
      return 'Operacao';
    }
    return 'Outros';
  }

  List<Ingrediente> get _ingredientesGrandePorte {
    return const [
      Ingrediente(id: '', nome: 'Pao Brioche', unidadeMedida: UnidadeMedida.un, estoqueAtual: 1800, estoqueMinimo: 600, custoUnitario: 1.10),
      Ingrediente(id: '', nome: 'Pao Australiano', unidadeMedida: UnidadeMedida.un, estoqueAtual: 900, estoqueMinimo: 300, custoUnitario: 1.35),
      Ingrediente(id: '', nome: 'Hamburguer Bovino 90g', unidadeMedida: UnidadeMedida.un, estoqueAtual: 2600, estoqueMinimo: 900, custoUnitario: 3.40),
      Ingrediente(id: '', nome: 'Hamburguer Bovino 150g', unidadeMedida: UnidadeMedida.un, estoqueAtual: 1200, estoqueMinimo: 450, custoUnitario: 4.90),
      Ingrediente(id: '', nome: 'File de Frango Empanado', unidadeMedida: UnidadeMedida.un, estoqueAtual: 1500, estoqueMinimo: 500, custoUnitario: 3.20),
      Ingrediente(id: '', nome: 'Bacon Fatiado', unidadeMedida: UnidadeMedida.kg, estoqueAtual: 140, estoqueMinimo: 40, custoUnitario: 32.50),
      Ingrediente(id: '', nome: 'Cheddar Fatiado', unidadeMedida: UnidadeMedida.kg, estoqueAtual: 180, estoqueMinimo: 60, custoUnitario: 39.90),
      Ingrediente(id: '', nome: 'Mussarela Fatiada', unidadeMedida: UnidadeMedida.kg, estoqueAtual: 220, estoqueMinimo: 80, custoUnitario: 34.80),
      Ingrediente(id: '', nome: 'Presunto Fatiado', unidadeMedida: UnidadeMedida.kg, estoqueAtual: 160, estoqueMinimo: 50, custoUnitario: 29.70),
      Ingrediente(id: '', nome: 'Alface Americana', unidadeMedida: UnidadeMedida.kg, estoqueAtual: 95, estoqueMinimo: 30, custoUnitario: 9.90),
      Ingrediente(id: '', nome: 'Tomate', unidadeMedida: UnidadeMedida.kg, estoqueAtual: 210, estoqueMinimo: 70, custoUnitario: 8.40),
      Ingrediente(id: '', nome: 'Cebola Roxa', unidadeMedida: UnidadeMedida.kg, estoqueAtual: 130, estoqueMinimo: 45, custoUnitario: 7.60),
      Ingrediente(id: '', nome: 'Picles Fatiado', unidadeMedida: UnidadeMedida.kg, estoqueAtual: 65, estoqueMinimo: 22, custoUnitario: 23.50),
      Ingrediente(id: '', nome: 'Batata Congelada Palito', unidadeMedida: UnidadeMedida.kg, estoqueAtual: 620, estoqueMinimo: 220, custoUnitario: 10.20),
      Ingrediente(id: '', nome: 'Anel de Cebola Congelado', unidadeMedida: UnidadeMedida.kg, estoqueAtual: 210, estoqueMinimo: 70, custoUnitario: 18.90),
      Ingrediente(id: '', nome: 'Nuggets de Frango', unidadeMedida: UnidadeMedida.kg, estoqueAtual: 240, estoqueMinimo: 90, custoUnitario: 17.60),
      Ingrediente(id: '', nome: 'Oleo de Soja', unidadeMedida: UnidadeMedida.l, estoqueAtual: 360, estoqueMinimo: 120, custoUnitario: 5.70),
      Ingrediente(id: '', nome: 'Ketchup Tradicional', unidadeMedida: UnidadeMedida.l, estoqueAtual: 190, estoqueMinimo: 70, custoUnitario: 11.20),
      Ingrediente(id: '', nome: 'Mostarda', unidadeMedida: UnidadeMedida.l, estoqueAtual: 130, estoqueMinimo: 45, custoUnitario: 10.80),
      Ingrediente(id: '', nome: 'Maionese Premium', unidadeMedida: UnidadeMedida.l, estoqueAtual: 210, estoqueMinimo: 75, custoUnitario: 14.60),
      Ingrediente(id: '', nome: 'Molho Barbecue', unidadeMedida: UnidadeMedida.l, estoqueAtual: 95, estoqueMinimo: 30, custoUnitario: 18.30),
      Ingrediente(id: '', nome: 'Molho Especial da Casa', unidadeMedida: UnidadeMedida.l, estoqueAtual: 70, estoqueMinimo: 25, custoUnitario: 21.90),
      Ingrediente(id: '', nome: 'Refrigerante Cola Lata 350ml', unidadeMedida: UnidadeMedida.un, estoqueAtual: 5200, estoqueMinimo: 1800, custoUnitario: 3.10),
      Ingrediente(id: '', nome: 'Refrigerante Guarana Lata 350ml', unidadeMedida: UnidadeMedida.un, estoqueAtual: 3200, estoqueMinimo: 1100, custoUnitario: 2.95),
      Ingrediente(id: '', nome: 'Suco de Laranja Concentrado', unidadeMedida: UnidadeMedida.l, estoqueAtual: 260, estoqueMinimo: 80, custoUnitario: 12.70),
      Ingrediente(id: '', nome: 'Polpa de Morango', unidadeMedida: UnidadeMedida.kg, estoqueAtual: 150, estoqueMinimo: 50, custoUnitario: 19.40),
      Ingrediente(id: '', nome: 'Leite Integral', unidadeMedida: UnidadeMedida.l, estoqueAtual: 380, estoqueMinimo: 120, custoUnitario: 4.60),
      Ingrediente(id: '', nome: 'Sorvete Baunilha', unidadeMedida: UnidadeMedida.kg, estoqueAtual: 190, estoqueMinimo: 65, custoUnitario: 22.10),
      Ingrediente(id: '', nome: 'Sorvete Chocolate', unidadeMedida: UnidadeMedida.kg, estoqueAtual: 160, estoqueMinimo: 55, custoUnitario: 23.40),
      Ingrediente(id: '', nome: 'Chantilly', unidadeMedida: UnidadeMedida.kg, estoqueAtual: 95, estoqueMinimo: 30, custoUnitario: 26.20),
      Ingrediente(id: '', nome: 'Ovomaltine', unidadeMedida: UnidadeMedida.kg, estoqueAtual: 85, estoqueMinimo: 25, custoUnitario: 31.50),
      Ingrediente(id: '', nome: 'Brownie Pronto', unidadeMedida: UnidadeMedida.un, estoqueAtual: 1400, estoqueMinimo: 450, custoUnitario: 2.40),
      Ingrediente(id: '', nome: 'Calda de Chocolate', unidadeMedida: UnidadeMedida.l, estoqueAtual: 120, estoqueMinimo: 40, custoUnitario: 16.90),
      Ingrediente(id: '', nome: 'Embalagem Hamburguer P', unidadeMedida: UnidadeMedida.un, estoqueAtual: 6000, estoqueMinimo: 2000, custoUnitario: 0.42),
      Ingrediente(id: '', nome: 'Embalagem Hamburguer G', unidadeMedida: UnidadeMedida.un, estoqueAtual: 4500, estoqueMinimo: 1500, custoUnitario: 0.57),
      Ingrediente(id: '', nome: 'Embalagem Batata Media', unidadeMedida: UnidadeMedida.un, estoqueAtual: 5000, estoqueMinimo: 1600, custoUnitario: 0.35),
      Ingrediente(id: '', nome: 'Guardanapo', unidadeMedida: UnidadeMedida.un, estoqueAtual: 30000, estoqueMinimo: 10000, custoUnitario: 0.03),
      Ingrediente(id: '', nome: 'Luva Descartavel', unidadeMedida: UnidadeMedida.un, estoqueAtual: 22000, estoqueMinimo: 7000, custoUnitario: 0.09),
      Ingrediente(id: '', nome: 'Gas GLP Cozinha', unidadeMedida: UnidadeMedida.un, estoqueAtual: 22, estoqueMinimo: 8, custoUnitario: 108.00),
    ];
  }
}
