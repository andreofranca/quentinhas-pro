import 'package:flutter/material.dart';
import '../../models/dominio.dart';
import '../../services/dashboard_pedido_service.dart';
import '../../models/models_quentinha.dart';
import '../../theme/app_theme.dart';

class TelaDashboardReal extends StatefulWidget {
  const TelaDashboardReal({super.key});

  @override
  State<TelaDashboardReal> createState() => _TelaDashboardRealState();
}

class _TelaDashboardRealState extends State<TelaDashboardReal> {
  final DashboardPedidoService _pedidoService = DashboardPedidoService();
  late Future<List<Pedido>> _futurePedidos;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() {
    setState(() {
      _futurePedidos = _pedidoService.obterPedidos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: FutureBuilder<List<Pedido>>(
        future: _futurePedidos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar dashboard: ${snapshot.error}'));
          }

          final pedidos = snapshot.data ?? [];
          final hoje = pedidos.where((p) => p.dataHora.day == DateTime.now().day).toList();
          final emProducao = hoje.where((p) => p.statusLogistico == 'EM_PRODUCAO').length;
          final prontos = hoje.where((p) => p.statusLogistico == 'PRONTO').length;
          final faturamento = hoje.fold(0.0, (sum, p) => sum + p.total);
          final ticketMedio = hoje.isNotEmpty ? faturamento / hoje.length : 0.0;

          return RefreshIndicator(
            onRefresh: () async => _carregarDados(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DASHBOARD OPERACIONAL', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildKPICard('Pedidos Hoje', '${hoje.length}', Icons.shopping_bag, AppTheme.primary),
                      _buildKPICard('Faturamento', 'R\$ ${faturamento.toStringAsFixed(2).replaceAll('.', ',')}', Icons.attach_money, AppTheme.success),
                      _buildKPICard('Ticket Médio', 'R\$ ${ticketMedio.toStringAsFixed(2).replaceAll('.', ',')}', Icons.receipt, Colors.purple),
                      _buildKPICard('Em Preparação', '$emProducao', Icons.restaurant, AppTheme.warning),
                      _buildKPICard('Prontos', '$prontos', Icons.check_circle, AppTheme.success),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('PEDIDOS RECENTES', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  const SizedBox(height: 16),
                  _buildPedidosRecentes(hoje),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKPICard(String titulo, String valor, IconData icone, Color cor) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: cor, size: 28),
              const SizedBox(width: 8),
              Expanded(child: Text(titulo, style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 16),
          Text(valor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cor)),
        ],
      ),
    );
  }

  Widget _buildPedidosRecentes(List<Pedido> pedidosHoje) {
    if (pedidosHoje.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text('Nenhum pedido registrado hoje.')),
        ),
      );
    }
    
    // Pegar ultimos 5
    final recentes = pedidosHoje.reversed.take(5).toList();

    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentes.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final p = recentes[index];
          return ListTile(
            leading: CircleAvatar(backgroundColor: _getCorStatus(p.statusLogistico), child: const Icon(Icons.receipt, color: Colors.white)),
            title: Text('${p.nomeCliente ?? 'Cliente Balcão'} (Pedido ${p.numeroPedido.substring(0, 8)})'),
            subtitle: Text('${p.statusLogistico} - R\$ ${p.total.toStringAsFixed(2).replaceAll('.', ',')}'),
            trailing: Text('${p.dataHora.hour.toString().padLeft(2, '0')}:${p.dataHora.minute.toString().padLeft(2, '0')}'),
          );
        },
      ),
    );
  }

  Color _getCorStatus(String status) {
    switch (status) {
      case 'CONFIRMADO': return Colors.blue;
      case 'EM_PRODUCAO': return AppTheme.warning;
      case 'PRONTO': return AppTheme.success;
      default: return Colors.grey;
    }
  }
}


