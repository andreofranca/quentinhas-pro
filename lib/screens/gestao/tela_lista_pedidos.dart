import 'package:flutter/material.dart';
import '../../models/dominio.dart';
import '../../services/dashboard_pedido_service.dart';
import '../../models/models_quentinha.dart';
import '../../theme/app_theme.dart';

class TelaListaPedidos extends StatefulWidget {
  const TelaListaPedidos({super.key});
  @override State<TelaListaPedidos> createState() => _TelaListaPedidosState();
}

class _TelaListaPedidosState extends State<TelaListaPedidos> {
  final DashboardPedidoService _service = DashboardPedidoService();
  late Future<List<Pedido>> _future;

  @override void initState() {
    super.initState();
    _carregar();
  }
  void _carregar() { setState(() { _future = _service.obterPedidos(); }); }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('Histórico de Pedidos'), backgroundColor: Colors.white, foregroundColor: Colors.black, actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar)]),
      body: FutureBuilder<List<Pedido>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final pedidos = snapshot.data ?? [];
          if (pedidos.isEmpty) return const Center(child: Text('Nenhum pedido encontrado.'));
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Número', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Horário', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Pagamento', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: pedidos.reversed.map((p) => DataRow(
                    cells: [
                      DataCell(Text('#${p.numeroPedido.substring(0, 8)}')),
                      DataCell(Text(p.nomeCliente ?? 'Balcão')),
                      DataCell(Text('${p.dataHora.day.toString().padLeft(2,'0')}/${p.dataHora.month.toString().padLeft(2,'0')} ${p.dataHora.hour.toString().padLeft(2,'0')}:${p.dataHora.minute.toString().padLeft(2,'0')}')),
                      DataCell(Text('R\$ ${p.total.toStringAsFixed(2).replaceAll('.', ',')}')),
                      DataCell(Text('${p.formaPagamento} (${p.statusPagamento})')),
                      DataCell(_buildStatusBadge(p.statusLogistico)),
                    ]
                  )).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color cor;
    switch(status) {
      case 'NOVO': cor = Colors.blue; break;
      case 'PREPARANDO': cor = AppTheme.secondaryColor; break;
      case 'PRONTO': cor = AppTheme.successColor; break;
      case 'CANCELADO': cor = Colors.red; break;
      case 'ENTREGUE': cor = Colors.green; break;
      default: cor = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: cor.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: cor)),
      child: Text(status, style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
