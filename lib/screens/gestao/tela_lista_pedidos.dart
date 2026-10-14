import 'package:flutter/material.dart';
import '../../models/dominio.dart';
import '../../services/dashboard_pedido_service.dart';
import '../../theme/app_theme.dart';
import '../../services/whatsapp_service.dart';

class TelaListaPedidos extends StatefulWidget {
  const TelaListaPedidos({super.key});
  @override
  State<TelaListaPedidos> createState() => _TelaListaPedidosState();
}

class _TelaListaPedidosState extends State<TelaListaPedidos> {
  final DashboardPedidoService _service = DashboardPedidoService();
  final WhatsAppService _whatsapp = WhatsAppUrlLauncherService();
  late Future<List<Pedido>> _future;
  String _filtroStatus = 'TODOS';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    setState(() {
      _future = _service.obterPedidos();
    });
  }

  Future<void> _avancarStatus(Pedido p) async {
    String novoStatus;
    if (p.statusLogistico == 'NOVO' || p.statusLogistico == 'CONFIRMADO') {
      novoStatus = 'EM_PRODUCAO';
    } else if (p.statusLogistico == 'EM_PRODUCAO') {
      novoStatus = 'PRONTO';
    } else if (p.statusLogistico == 'PRONTO') {
      novoStatus = 'ENTREGUE';
    } else {
      return;
    }

    try {
      await _service.atualizarStatus(p.numeroPedido, novoStatus);
      _carregar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido atualizado para: ${_formatarStatus(novoStatus)}'),
          backgroundColor: AppTheme.success,
          action: p.telefoneCliente.isNotEmpty
              ? SnackBarAction(
                  label: 'AVISAR WHATSAPP',
                  textColor: Colors.amber,
                  onPressed: () => _enviarStatusWhatsApp(p, statusSobrescrito: novoStatus),
                )
              : null,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível atualizar o status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _enviarStatusWhatsApp(Pedido p, {String? statusSobrescrito}) async {
    if (p.telefoneCliente.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este pedido não possui telefone cadastrado para WhatsApp.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final status = statusSobrescrito ?? p.statusLogistico;
    String statusAmigavel = status;
    if (status == 'CONFIRMADO' || status == 'NOVO') {
      statusAmigavel = 'Confirmado e na fila de preparo 📋';
    } else if (status == 'EM_PRODUCAO') {
      statusAmigavel = 'Sendo preparado com carinho pelo nosso chef 🍳';
    } else if (status == 'PRONTO') {
      statusAmigavel = p.tipoEntrega == 'ENTREGA'
          ? 'Prontinho e saindo para entrega! 🛵💨'
          : 'PRONTO para retirada no balcão! 🍽️';
    } else if (status == 'SAIU_ENTREGA') {
      statusAmigavel = 'A caminho do seu endereço 🛵';
    } else if (status == 'ENTREGUE') {
      statusAmigavel = 'Entregue com sucesso! Bom apetite! 🎉';
    }

    final numCurto = p.numeroPedido.length >= 8 ? p.numeroPedido.substring(0, 8).toUpperCase() : p.numeroPedido;
    final msg = 'Olá, *${p.nomeCliente.isNotEmpty ? p.nomeCliente : "Cliente"}*!\n\n'
        'Atualização do seu pedido *#$numCurto*:\n'
        'Status: *$statusAmigavel*\n\n'
        'Total: R\$ ${p.total.toStringAsFixed(2).replaceAll('.', ',')}\n\n'
        'Agradecemos a preferência — *Quentinhas Pro*!';

    try {
      await _whatsapp.enviarMensagem(telefone: p.telefoneCliente, mensagem: msg);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aviso ao acionar WhatsApp: $e'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    }
  }

  String _formatarStatus(String status) {
    switch (status) {
      case 'NOVO':
      case 'CONFIRMADO':
        return 'Novo / Na Fila';
      case 'EM_PRODUCAO':
        return 'Em Preparo';
      case 'PRONTO':
        return 'Pronto';
      case 'SAIU_ENTREGA':
        return 'A Caminho';
      case 'ENTREGUE':
        return 'Entregue';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return status;
    }
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'NOVO':
      case 'CONFIRMADO':
        return Colors.blue;
      case 'EM_PRODUCAO':
        return AppTheme.warning;
      case 'PRONTO':
        return AppTheme.success;
      case 'ENTREGUE':
        return Colors.teal;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: AppTheme.primary),
            SizedBox(width: 10),
            Text(
              'Recebimento de Pedidos (Loja)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primary),
            tooltip: 'Atualizar Pedidos',
            onPressed: _carregar,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<List<Pedido>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Erro ao carregar pedidos: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _carregar,
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final todos = (snapshot.data ?? []).reversed.toList();
          final novos = todos.where((p) => p.statusLogistico == 'NOVO' || p.statusLogistico == 'CONFIRMADO').toList();
          final emPreparo = todos.where((p) => p.statusLogistico == 'EM_PRODUCAO').toList();
          final prontos = todos.where((p) => p.statusLogistico == 'PRONTO').toList();

          List<Pedido> pedidosFiltrados = todos;
          if (_filtroStatus == 'NOVOS') {
            pedidosFiltrados = novos;
          } else if (_filtroStatus == 'PREPARO') {
            pedidosFiltrados = emPreparo;
          } else if (_filtroStatus == 'PRONTOS') {
            pedidosFiltrados = prontos;
          }

          return Column(
            children: [
              // Barra de Filtros Rápidos
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    _buildFiltroChip('TODOS', 'Todos (${todos.length})', todos.length),
                    const SizedBox(width: 8),
                    _buildFiltroChip('NOVOS', 'Novos (${novos.length})', novos.length, corDestaque: Colors.blue),
                    const SizedBox(width: 8),
                    _buildFiltroChip('PREPARO', 'Em Preparo (${emPreparo.length})', emPreparo.length, corDestaque: AppTheme.warning),
                    const SizedBox(width: 8),
                    _buildFiltroChip('PRONTOS', 'Prontos (${prontos.length})', prontos.length, corDestaque: AppTheme.success),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Lista de Pedidos
              Expanded(
                child: pedidosFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Nenhum pedido nesta categoria no momento.',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: pedidosFiltrados.length,
                        itemBuilder: (context, index) {
                          final p = pedidosFiltrados[index];
                          return _buildCardPedido(p);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltroChip(String chave, String label, int quantidade, {Color? corDestaque}) {
    final bool selecionado = _filtroStatus == chave;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
          color: selecionado ? Colors.white : (corDestaque ?? Colors.black87),
        ),
      ),
      selected: selecionado,
      selectedColor: corDestaque ?? AppTheme.primary,
      backgroundColor: Colors.grey.shade100,
      onSelected: (val) {
        if (val) setState(() => _filtroStatus = chave);
      },
    );
  }

  Widget _buildCardPedido(Pedido p) {
    final cor = _corStatus(p.statusLogistico);
    final numCurto = p.numeroPedido.length >= 8 ? p.numeroPedido.substring(0, 8).toUpperCase() : p.numeroPedido;
    final hora = '${p.dataHora.hour.toString().padLeft(2, '0')}:${p.dataHora.minute.toString().padLeft(2, '0')}';
    final bool isEntrega = p.tipoEntrega.toUpperCase().contains('ENTREGA');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cor.withAlpha(80), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do Pedido
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cor.withAlpha(20),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '#$numCurto',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatarStatus(p.statusLogistico).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(hora, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cliente e Contato
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black12,
                      child: Icon(Icons.person, size: 18, color: Colors.black87),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nomeCliente.isNotEmpty ? p.nomeCliente : 'Balcão / Não Informado',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (p.telefoneCliente.isNotEmpty)
                            Text(
                              p.telefoneCliente,
                              style: const TextStyle(color: Colors.black54, fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                    if (p.telefoneCliente.isNotEmpty)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF25D366),
                          side: const BorderSide(color: Color(0xFF25D366)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _enviarStatusWhatsApp(p),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Modalidade de Entrega / Endereço
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isEntrega ? Colors.blue.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isEntrega ? Colors.blue.shade200 : Colors.amber.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isEntrega ? Icons.delivery_dining : Icons.restaurant,
                        color: isEntrega ? Colors.blue.shade800 : Colors.amber.shade900,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isEntrega
                              ? 'Entrega: ${p.enderecoCompleto ?? "Endereço a confirmar"}'
                              : 'Retirada no Balcão da Loja',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isEntrega ? Colors.blue.shade900 : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Itens do Pedido
                const Text('Itens do Pedido:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 6),
                ...p.itens.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('${item.quantidade}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(item.produto.nome, style: const TextStyle(fontSize: 14)),
                          ),
                          Text(
                            'R\$ ${(item.produto.preco * item.quantidade).toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    )),

                // Observações (se houver)
                if (p.observacao != null && p.observacao!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note_alt_outlined, size: 16, color: Colors.brown),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Obs: ${p.observacao}',
                            style: const TextStyle(fontSize: 13, color: Colors.brown, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Rodapé Financeiro e Botão de Ação Operacional
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p.formaPagamento} (${p.statusPagamento})',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        Text(
                          'Total: R\$ ${p.total.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary),
                        ),
                      ],
                    ),

                    // Botão de Avanço Rápido de Status
                    _buildBotaoAcaoStatus(p),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoAcaoStatus(Pedido p) {
    if (p.statusLogistico == 'NOVO' || p.statusLogistico == 'CONFIRMADO') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.warning,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.kitchen, size: 18),
        label: const Text('INICIAR PREPARO', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _avancarStatus(p),
      );
    } else if (p.statusLogistico == 'EM_PRODUCAO') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.success,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.check_circle_outline, size: 18),
        label: const Text('MARCAR PRONTO', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _avancarStatus(p),
      );
    } else if (p.statusLogistico == 'PRONTO') {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.delivery_dining, size: 18),
        label: const Text('DESPACHAR / ENTREGAR', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _avancarStatus(p),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
