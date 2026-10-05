import 'package:flutter/material.dart';
import '../../models/dominio.dart';
import '../../services/dashboard_pedido_service.dart';
import '../../models/models_quentinha.dart';
import '../../theme/app_theme.dart';
import '../../services/whatsapp_service.dart';
import '../../utils/whatsapp_message_builder.dart';

class TelaListaPedidos extends StatefulWidget {
  const TelaListaPedidos({super.key});
  @override State<TelaListaPedidos> createState() => _TelaListaPedidosState();
}

class _TelaListaPedidosState extends State<TelaListaPedidos> {
  final DashboardPedidoService _service = DashboardPedidoService();
  final WhatsAppService _whatsapp = WhatsAppUrlLauncherService();
  late Future<List<Pedido>> _future;

  @override void initState() {
    super.initState();
    _carregar();
  }
  void _carregar() { setState(() { _future = _service.obterPedidos(); }); }

  Future<void> _enviarStatusWhatsApp(Pedido p) async {
    if (p.telefoneCliente.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente não possui telefone cadastrado.')));
      return;
    }
    
    // Constrói uma mensagem simples de atualização de status
    String statusAmigavel = p.statusLogistico;
    if (statusAmigavel == 'CONFIRMADO') statusAmigavel = 'Confirmado e na fila da cozinha';
    else if (statusAmigavel == 'EM_PRODUCAO') statusAmigavel = 'Sendo preparado pelo chef';
    else if (statusAmigavel == 'PRONTO') statusAmigavel = 'Pronto para você!';
    else if (statusAmigavel == 'SAIU_ENTREGA') statusAmigavel = 'A caminho da sua casa';
    else if (statusAmigavel == 'ENTREGUE') statusAmigavel = 'Entregue. Bom apetite!';
    
    final msg = 'Olá, ${p.nomeCliente}!\n\nAtualização do seu pedido *#${p.numeroPedido.substring(0,8).toUpperCase()}*:\n\nStatus: *$statusAmigavel*.\n\nObrigado por comprar com a Quentinhas Pro!';
    
    try {
      await _whatsapp.enviarMensagem(telefone: p.telefoneCliente, mensagem: msg);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao abrir WhatsApp: $e')));
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Histórico de Pedidos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar)
        ]
      ),
      body: FutureBuilder<List<Pedido>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final pedidos = snapshot.data ?? [];
          if (pedidos.isEmpty) return const Center(child: Text('Nenhum pedido encontrado.'));
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.resolveWith((states) => Colors.grey.shade50),
                  columns: const [
                    DataColumn(label: Text('Número', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
                    DataColumn(label: Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
                    DataColumn(label: Text('Horário', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
                    DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
                    DataColumn(label: Text('Pagamento', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
                    DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
                  ],
                  rows: pedidos.reversed.map((p) => DataRow(
                    cells: [
                      DataCell(Text('#${p.numeroPedido.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(p.nomeCliente.isNotEmpty ? p.nomeCliente : 'Balcão', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      )),
                      DataCell(Text('${p.dataHora.day.toString().padLeft(2,'0')}/${p.dataHora.month.toString().padLeft(2,'0')} ${p.dataHora.hour.toString().padLeft(2,'0')}:${p.dataHora.minute.toString().padLeft(2,'0')}')),
                      DataCell(Text('R\$ ${p.total.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text('${p.formaPagamento} (${p.statusPagamento})')),
                      DataCell(_buildStatusBadge(p.statusLogistico)),
                      DataCell(
                        IconButton(
                          tooltip: 'Enviar Status por WhatsApp',
                          icon: const Icon(Icons.chat, color: Colors.green),
                          onPressed: () => _enviarStatusWhatsApp(p),
                        )
                      ),
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
      case 'CONFIRMADO': cor = Colors.blue; break;
      case 'EM_PRODUCAO': cor = AppTheme.warning; break;
      case 'PRONTO': cor = AppTheme.success; break;
      case 'CANCELADO': cor = Colors.red; break;
      case 'ENTREGUE': cor = Colors.green; break;
      default: cor = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: cor.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: cor.withOpacity(0.5))),
      child: Text(status, style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}


