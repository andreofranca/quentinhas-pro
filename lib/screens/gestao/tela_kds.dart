import 'package:flutter/material.dart';
import '../../models/dominio.dart';
import '../../services/dashboard_pedido_service.dart';
import '../../services/whatsapp_service.dart';
import '../../theme/app_theme.dart';

class TelaKds extends StatefulWidget {
  const TelaKds({super.key});
  @override State<TelaKds> createState() => _TelaKdsState();
}

class _TelaKdsState extends State<TelaKds> {
  final DashboardPedidoService _dashboardService = DashboardPedidoService();
  final WhatsAppService _whatsapp = WhatsAppUrlLauncherService();
  List<Pedido> _pedidos = [];
  bool _isLoading = true;

  @override void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _isLoading = true);
    try {
      _pedidos = await _dashboardService.obterPedidos();
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar KDS: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _avancarStatus(Pedido p) async {
    String novoStatus;
    if (p.statusLogistico == 'CONFIRMADO') {
      novoStatus = 'EM_PRODUCAO';
    } else if (p.statusLogistico == 'EM_PRODUCAO') {
      novoStatus = 'PRONTO';
    } else if (p.statusLogistico == 'PRONTO') {
      novoStatus = 'ENTREGUE';
    } else {
      return;
    }

    try {
      await _dashboardService.atualizarStatus(p.numeroPedido, novoStatus);
      _carregar();
      if (novoStatus == 'PRONTO' && p.telefoneCliente.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pedido #${p.numeroPedido.length >= 8 ? p.numeroPedido.substring(0, 8).toUpperCase() : p.numeroPedido} marcado como PRONTO!'),
              action: SnackBarAction(
                label: 'AVISAR WHATSAPP',
                textColor: Colors.amber,
                onPressed: () => _notificarCliente(p, statusSobrescrito: 'PRONTO'),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _notificarCliente(Pedido p, {String? statusSobrescrito}) async {
    if (p.telefoneCliente.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente não possui telefone cadastrado.')));
      return;
    }
    final status = statusSobrescrito ?? p.statusLogistico;
    String statusTexto = status;
    if (status == 'CONFIRMADO') {
      statusTexto = 'está confirmado e entrou na fila de produção da cozinha';
    } else if (status == 'EM_PRODUCAO') {
      statusTexto = 'está sendo preparado com carinho pela nossa cozinha 🍳';
    } else if (status == 'PRONTO') {
      statusTexto = p.tipoEntrega == 'ENTREGA'
          ? 'está pronto e saindo para entrega! 🛵'
          : 'está PRONTO para retirada no balcão! 🍽️';
    } else if (status == 'ENTREGUE') {
      statusTexto = 'foi finalizado/entregue com sucesso! Bom apetite! 🎉';
    }

    final numCurto = p.numeroPedido.length >= 8 ? p.numeroPedido.substring(0, 8).toUpperCase() : p.numeroPedido;
    final msg = 'Olá, ${p.nomeCliente.isNotEmpty ? p.nomeCliente : "Cliente"}!\n\nAtualização do seu pedido *#$numCurto*:\nEle $statusTexto.\n\nAgradecemos a preferência — *Quentinhas Pro*!';
    try {
      await _whatsapp.enviarMensagem(telefone: p.telefoneCliente, mensagem: msg);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aviso ao abrir WhatsApp: $e')));
    }
  }

  @override Widget build(BuildContext context) {
    if (_isLoading && _pedidos.isEmpty) return const Center(child: CircularProgressIndicator());
    
    final ativos = _pedidos.where((p) => p.statusLogistico == 'CONFIRMADO' || p.statusLogistico == 'EM_PRODUCAO' || p.statusLogistico == 'PRONTO').toList();
    final novos = ativos.where((p) => p.statusLogistico == 'CONFIRMADO').toList();
    final preparando = ativos.where((p) => p.statusLogistico == 'EM_PRODUCAO').toList();
    final prontos = ativos.where((p) => p.statusLogistico == 'PRONTO').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('KDS - Kitchen Display System', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primary,
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar)
        ]
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildColuna('NOVOS', novos, AppTheme.primary, Icons.receipt_long)),
            const SizedBox(width: 16),
            Expanded(child: _buildColuna('EM PREPARAÇÃO', preparando, AppTheme.warning, Icons.local_fire_department)),
            const SizedBox(width: 16),
            Expanded(child: _buildColuna('PRONTOS', prontos, AppTheme.success, Icons.check_circle_outline)),
          ],
        ),
      ),
    );
  }

  Widget _buildColuna(String titulo, List<Pedido> pedidos, Color cor, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: cor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))]
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('$titulo (${pedidos.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.white,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: pedidos.length,
              itemBuilder: (context, i) {
                final p = pedidos[i];
                final tempo = DateTime.now().difference(p.dataHora).inMinutes;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text('#${p.numeroPedido.length >= 8 ? p.numeroPedido.substring(0, 8).toUpperCase() : p.numeroPedido}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                if (p.telefoneCliente.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(Icons.chat, color: Colors.green, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Avisar Cliente no WhatsApp',
                                    onPressed: () => _notificarCliente(p),
                                  ),
                                ],
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: tempo > 15 ? Colors.red.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                              child: Text('$tempo min', style: TextStyle(color: tempo > 15 ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(p.tipoEntrega == 'ENTREGA' ? Icons.moped : Icons.storefront, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(child: Text('${p.nomeCliente.isNotEmpty ? p.nomeCliente : 'Balcão'} (${p.tipoEntrega})', style: const TextStyle(color: Colors.black87))),
                          ],
                        ),
                        const Divider(height: 24),
                        ...p.itens.map((i) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• ${i.quantidade}x ${i.produto.nome}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                        )),
                        if (p.observacao?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.amber.shade200)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                                const SizedBox(width: 4),
                                Expanded(child: Text(p.observacao!, style: const TextStyle(color: Colors.orange))),
                              ],
                            ),
                          )
                        ],
                        const SizedBox(height: 16),
                        if (p.statusLogistico == 'CONFIRMADO')
                          SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.play_arrow), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white), onPressed: () => _avancarStatus(p), label: const Text('INICIAR PREPARO'))),
                        if (p.statusLogistico == 'EM_PRODUCAO')
                          SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.check), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white), onPressed: () => _avancarStatus(p), label: const Text('MARCAR PRONTO'))),
                        if (p.statusLogistico == 'PRONTO')
                          SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: Icon(p.tipoEntrega == 'ENTREGA' ? Icons.delivery_dining : Icons.done_all), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white), onPressed: () => _avancarStatus(p), label: Text(p.tipoEntrega == 'ENTREGA' ? 'DESPACHAR ENTREGA' : 'FINALIZAR RETIRADA'))),
                      ],
                    ),
                  )
                );
              }
            )
          )
        )
      ],
    );
  }
}


