// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

import '../../models/models_quentinha.dart';
import '../../theme/app_theme.dart';
import '../../services/whatsapp_service.dart';
import '../../services/cep_service.dart';
import '../../services/pedido_service.dart';
import '../../utils/whatsapp_message_builder.dart';

class TelaCheckout extends StatefulWidget {
  final List<ItemCarrinhoQuentinha> itens;
  final double total;
  final WhatsAppService whatsappService;

  TelaCheckout({
    super.key,
    required this.itens,
    required this.total,
    WhatsAppService? whatsappService,
  }) : whatsappService = whatsappService ?? WhatsAppUrlLauncherService();

  @override
  State<TelaCheckout> createState() => _TelaCheckoutState();
}

class _TelaCheckoutState extends State<TelaCheckout> {
  final _formKey = GlobalKey<FormState>();

  final CaixaService _caixaService = CaixaService();
  final PedidoService _pedidoService = PedidoService();

  // Controladores do Cliente
  final _nomeController = TextEditingController();
  final _whatsappController = TextEditingController();

  // Estado de Entrega
  TipoEntrega _tipoEntrega = TipoEntrega.retirada;

  // Controladores de Endereço
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ufController = TextEditingController();

  // Serviço de CEP
  late final CepService _cepService;
  bool _buscandoCep = false;

  FormaPagamentoDraft _formaPagamento = FormaPagamentoDraft.pix;
  final _observacoesController = TextEditingController();
  final _trocoController = TextEditingController();

  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cepService = CepService();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _whatsappController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _complementoController.dispose();
    _cidadeController.dispose();
    _ufController.dispose();
    _observacoesController.dispose();
    _trocoController.dispose();
    super.dispose();
  }

  Future<void> _buscarCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) return;

    setState(() => _buscandoCep = true);
    try {
      final endereco = await _cepService.buscarCep(cep);
      setState(() {
        _logradouroController.text = endereco.logradouro;
        _bairroController.text = endereco.bairro;
        _cidadeController.text = endereco.cidade;
        _ufController.text = endereco.uf;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FINALIZAR PEDIDO'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Painel Esquerdo: Formulário
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSecao('CLIENTE & WHATSAPP', [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nomeController,
                              decoration: const InputDecoration(labelText: 'Nome do Cliente', border: OutlineInputBorder()),
                              validator: (v) { if (v == null || v.isEmpty) return 'Obrigatório'; if (v.replaceAll(new RegExp(r'[^0-9]'), '').length < 10) return 'Número inválido'; return null; }
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _whatsappController,
                              decoration: const InputDecoration(labelText: 'WhatsApp', border: OutlineInputBorder()),
                              keyboardType: TextInputType.phone,
                              validator: (v) { if (v == null || v.isEmpty) return 'Obrigatório'; if (v.replaceAll(new RegExp(r'[^0-9]'), '').length < 10) return 'Número inválido'; return null; }
                            ),
                          ),
                        ],
                      ),
                    ]),

                    const SizedBox(height: 24),
                    _buildSecao('TIPO DE ENTREGA', [
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<TipoEntrega>(
                              title: const Text('Retirada no Balcão'),
                              value: TipoEntrega.retirada,
                              groupValue: _tipoEntrega,
                              onChanged: (v) => setState(() => _tipoEntrega = v!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<TipoEntrega>(
                              title: const Text('Entrega'),
                              value: TipoEntrega.entrega,
                              groupValue: _tipoEntrega,
                              onChanged: (v) => setState(() => _tipoEntrega = v!),
                            ),
                          ),
                        ],
                      ),
                      if (_tipoEntrega == TipoEntrega.entrega) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _cepController,
                                decoration: InputDecoration(
                                  labelText: 'CEP',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: _buscandoCep
                                    ? const SizedBox(
                                        width: 24, height: 24,
                                        child: Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.search),
                                        onPressed: _buscarCep,
                                      ),
                                ),
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (_) => _buscarCep(),
                                validator: (v) => _tipoEntrega == TipoEntrega.entrega && v!.isEmpty ? 'Obrigatório' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _logradouroController,
                                decoration: const InputDecoration(labelText: 'Logradouro / Rua', border: OutlineInputBorder()),
                                validator: (v) => _tipoEntrega == TipoEntrega.entrega && v!.isEmpty ? 'Obrigatório' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _numeroController,
                                decoration: const InputDecoration(labelText: 'Número', border: OutlineInputBorder()),
                                validator: (v) => _tipoEntrega == TipoEntrega.entrega && v!.isEmpty ? 'Obrigatório' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _bairroController,
                                decoration: const InputDecoration(labelText: 'Bairro', border: OutlineInputBorder()),
                                validator: (v) => _tipoEntrega == TipoEntrega.entrega && v!.isEmpty ? 'Obrigatório' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _complementoController,
                                decoration: const InputDecoration(labelText: 'Complemento', border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                      ]
                    ]),

                    const SizedBox(height: 24),
                    _buildSecao('OBSERVAÇÕES', [
                      TextFormField(
                        controller: _observacoesController,
                        decoration: const InputDecoration(labelText: 'Observações do Pedido', border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            // Painel Direito: Resumo e Pagamento
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                color: Colors.grey.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SEU PEDIDO', style: AppTheme.themeData.textTheme.titleMedium),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.itens.length,
                        itemBuilder: (context, index) {
                          final item = widget.itens[index];
                          final List<Widget> subs = [];
                          if (item.adicionais.isNotEmpty) {
                            subs.addAll(item.adicionais.map((a) => Text('Adicional: ' + a.nome + ' + R\$ ' + a.preco.toStringAsFixed(2).replaceAll('.', ','))));
                          }
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.quantidade.toString() + 'x ' + item.oferta.nome + ' — ' + item.tamanhoEscolhido.tamanho.sigla, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: subs.isNotEmpty ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: subs) : null,
                            trailing: Text('R\$ ' + item.subtotal.toStringAsFixed(2).replaceAll('.', ','), style: const TextStyle(fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('SUBTOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('R\$ ${widget.total.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (_tipoEntrega == TipoEntrega.entrega) ...[
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TAXA DE ENTREGA'),
                          Text('R\$ 5,00'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL A PAGAR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(
                          'R\$ ${(_tipoEntrega == TipoEntrega.entrega ? widget.total + 5.0 : widget.total).toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('PAGAMENTO', style: AppTheme.themeData.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<FormaPagamentoDraft>(
                      initialValue: _formaPagamento,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: FormaPagamentoDraft.pix, child: Text('PIX')),
                        DropdownMenuItem(value: FormaPagamentoDraft.dinheiro, child: Text('Dinheiro')),
                        DropdownMenuItem(value: FormaPagamentoDraft.cartao, child: Text('Cartão')),
                        DropdownMenuItem(value: FormaPagamentoDraft.pendente, child: Text('Pendente / A Combinar')),
                      ],
                      onChanged: (v) => setState(() => _formaPagamento = v!),
                    ),
                    if (_formaPagamento == FormaPagamentoDraft.dinheiro) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _trocoController,
                        decoration: const InputDecoration(labelText: 'Troco para R\$', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _enviando ? null : _finalizarDraft,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 24)),
                        child: Text(_enviando ? 'ENVIANDO...' : 'FINALIZAR PEDIDO', style: const TextStyle(fontSize: 18)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecao(String titulo, List<Widget> filhos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: AppTheme.themeData.textTheme.titleMedium?.copyWith(color: AppTheme.primary)),
        const SizedBox(height: 16),
        ...filhos,
      ],
    );
  }

  Future<void> _finalizarDraft() async {
    if (!_formKey.currentState!.validate()) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, corrija os erros no formulário antes de continuar.', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.red)); return; }

    setState(() => _enviando = true);

    try {
      final endereco = _tipoEntrega == TipoEntrega.entrega
        ? EnderecoEntrega(
            cep: _cepController.text,
            logradouro: _logradouroController.text,
            numero: _numeroController.text,
            complemento: _complementoController.text,
            bairro: _bairroController.text,
            cidade: _cidadeController.text,
            uf: _ufController.text,
          )
        : null;

      double? valorRecebido;
      if (_formaPagamento == FormaPagamentoDraft.dinheiro && _trocoController.text.isNotEmpty) {
        valorRecebido = double.tryParse(_trocoController.text.replaceAll(',', '.'));
      }

      final draft = PedidoDraft(
        itens: widget.itens,
        subtotalItens: widget.total, // O total da dashboard é apenas a soma dos itens
        cliente: ClienteContato(nome: _nomeController.text, telefoneWhatsApp: _whatsappController.text),
        tipoEntrega: _tipoEntrega,
        endereco: endereco,
        taxaEntrega: _tipoEntrega == TipoEntrega.entrega ? 5.0 : 0.0, 
        formaPagamento: _formaPagamento,
        valorRecebido: valorRecebido,
        observacoes: _observacoesController.text,
      );

      // Integracao com o backend
      String? caixaId;
      try {
        caixaId = await _caixaService.getCaixaAtivoId();
      } catch (e) {
        if (e.toString().contains('Nenhum caixa aberto')) {
          caixaId = await _mostrarModalAberturaCaixa();
          if (caixaId == null) {
            if (mounted) setState(() => _enviando = false);
            return; // Usurio cancelou
          }
        } else {
          rethrow;
        }
      }

      final pedidoId = await _pedidoService.criarPedido(draft, caixaId);

      final msgOperacional = WhatsAppMessageBuilder.buildOperacional(draft, numeroPedido: pedidoId.length >= 8 ? pedidoId.substring(0, 8) : pedidoId);
      final msgCliente = WhatsAppMessageBuilder.buildCliente(draft, numeroPedido: pedidoId.length >= 8 ? pedidoId.substring(0, 8) : pedidoId);

      
      await widget.whatsappService.enviarMensagem(telefone: draft.cliente!.telefoneWhatsApp, mensagem: msgCliente);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido criado com sucesso!')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Nao foi possivel finalizar o pedido. Verifique os dados e o caixa e tente novamente.'),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 4),
      ));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<String?> _mostrarModalAberturaCaixa() async {
    final saldoController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.point_of_sale, color: AppTheme.success, size: 32),
            const SizedBox(width: 12),
            const Text('Abrir Caixa', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('O PDV atual está fechado. Para registrar este pedido, abra o caixa informando o troco inicial:', style: TextStyle(color: Colors.black87, fontSize: 15)),
            const SizedBox(height: 24),
            TextField(
              controller: saldoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Saldo Inicial (R\$)',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              try {
                final saldo = double.tryParse(saldoController.text.replaceAll(',', '.')) ?? 0.0;
                final novoCaixaId = await _caixaService.abrirCaixa(saldo);
                if (context.mounted) Navigator.pop(context, novoCaixaId);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Nao foi possivel abrir o caixa. Verifique se outro operador ja abriu no PDV atual e tente novamente.', style: const TextStyle(fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.orange.shade800,
                  ));
                }
              }
            },
            child: const Text('ABRIR E CONTINUAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}









