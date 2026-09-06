import 'package:flutter/material.dart';
import '../../models/dominio.dart';
import '../../services/dashboard_pedido_service.dart';
import '../../services/pedido_service.dart';
import '../../models/models_quentinha.dart';
import '../../theme/app_theme.dart';
import 'dart:async';

class TelaKDS extends StatefulWidget {
  const TelaKDS({super.key});
  @override State<TelaKDS> createState() => _TelaKDSState();
}

class _TelaKDSState extends State<TelaKDS> {
  final DashboardPedidoService _dashboardService = DashboardPedidoService();
  final PedidoService _pedidoService = PedidoService();
  List<Pedido> _pedidos = [];
  bool _isLoading = true;
  Timer? _timer;

  @override void initState() {
    super.initState();
    _carregarPedidos();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _carregarPedidos(silent: true));
  }
  @override void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _carregarPedidos({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final pedidos = await _dashboardService.obterPedidos();
      if (mounted) setState(() { _pedidos = pedidos; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _avancarStatus(Pedido p) async {
    String novoStatus;
    if (p.statusLogistico == 'NOVO') novoStatus = 'PREPARANDO';
    else if (p.statusLogistico == 'PREPARANDO') novoStatus = 'PRONTO';
    else return;

    try {
      await _dashboardService.atualizarStatus(p.numeroPedido, novoStatus);
      _carregarPedidos();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override Widget build(BuildContext context) {
    if (_isLoading && _pedidos.isEmpty) return const Center(child: CircularProgressIndicator());
    
    // Only show active kitchen orders
    final ativos = _pedidos.where((p) => p.statusLogistico == 'NOVO' || p.statusLogistico == 'PREPARANDO' || p.statusLogistico == 'PRONTO').toList();
    final novos = ativos.where((p) => p.statusLogistico == 'NOVO').toList();
    final preparando = ativos.where((p) => p.statusLogistico == 'PREPARANDO').toList();
    final prontos = ativos.where((p) => p.statusLogistico == 'PRONTO').toList();

    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('KDS - Kitchen Display System', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarPedidos),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildColuna('NOVOS', novos, AppTheme.primaryColor)),
                const SizedBox(width: 16),
                Expanded(child: _buildColuna('EM PREPARAÇÃO', preparando, AppTheme.secondaryColor)),
                const SizedBox(width: 16),
                Expanded(child: _buildColuna('PRONTOS', prontos, AppTheme.successColor)),
              ],
            ),
          )
        ],
      )
    );
  }

  Widget _buildColuna(String titulo, List<Pedido> lista, Color corHeader) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: corHeader, borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
          child: Text('$titulo (${lista.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
        ),
        Expanded(
          child: Container(
            color: Colors.white,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: lista.length,
              itemBuilder: (context, index) => _buildCardPedido(lista[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardPedido(Pedido p) {
    final tempoDecorrido = DateTime.now().difference(p.dataHora).inMinutes;
    final colorTempo = tempoDecorrido > 30 ? Colors.red : Colors.green;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${p.numeroPedido.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('$tempoDecorrido min', style: TextStyle(color: colorTempo, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Cliente: ${p.nomeCliente ?? 'Balcão'} (${p.tipoEntrega})', style: const TextStyle(fontWeight: FontWeight.w600)),
            const Divider(),
            ...p.itens.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${i.quantidade}x ${i.produto.nome}', style: const TextStyle(fontSize: 15)),
            )),
            if (p.observacao != null && p.observacao!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.amber.shade100,
                child: Text('Obs: ${p.observacao}', style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
              ),
            ],
            const SizedBox(height: 12),
            if (p.statusLogistico == 'NOVO')
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _avancarStatus(p), child: const Text('INICIAR PREPARO'))),
            if (p.statusLogistico == 'PREPARANDO')
              SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor), onPressed: () => _avancarStatus(p), child: const Text('MARCAR PRONTO'))),
          ],
        ),
      ),
    );
  }
}
