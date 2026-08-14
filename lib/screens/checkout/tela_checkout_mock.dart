import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/models_quentinha.dart';
import '../../theme/app_theme.dart';
import '../../services/whatsapp_service.dart';
import '../../services/cep_service.dart';
import '../../utils/whatsapp_message_builder.dart';

class TelaCheckoutMock extends StatefulWidget {
  final List<ItemCarrinhoQuentinha> itens;
  final double total;
  final WhatsAppService whatsappService;

  TelaCheckoutMock({
    super.key,
    required this.itens,
    required this.total,
    WhatsAppService? whatsappService,
  }) : whatsappService = whatsappService ?? WhatsAppUrlLauncherService();

  @override
  State<TelaCheckoutMock> createState() => _TelaCheckoutMockState();
}

class _TelaCheckoutMockState extends State<TelaCheckoutMock> {
  final _formKey = GlobalKey<FormState>();
  
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
        title: const Text('FINALIZAR DRAFT DE PEDIDO'),
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
                              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _whatsappController,
                              decoration: const InputDecoration(labelText: 'WhatsApp', border: OutlineInputBorder()),
                              keyboardType: TextInputType.phone,
                              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
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
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${item.quantidade}x ${item.oferta.nome}'),
                            subtitle: Text('Tamanho ${item.tamanhoEscolhido.tamanho.sigla}'), // Usando a sigla explícita (P, M, G)
                            trailing: Text('R\$ ${item.subtotal.toStringAsFixed(2).replaceAll('.', ',')}'),
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
                          Text('R\$ 5,00'), // Mock para UX visual, o draft cobrará 5
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
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('PAGAMENTO', style: AppTheme.themeData.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<FormaPagamentoDraft>(
                      value: _formaPagamento,
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
        Text(titulo, style: AppTheme.themeData.textTheme.titleMedium?.copyWith(color: AppTheme.primaryColor)),
        const SizedBox(height: 16),
        ...filhos,
      ],
    );
  }

  Future<void> _finalizarDraft() async {
    if (!_formKey.currentState!.validate()) return;
    
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
        taxaEntrega: _tipoEntrega == TipoEntrega.entrega ? 5.0 : 0.0, // Hardcoded conforme UI antiga
        formaPagamento: _formaPagamento,
        valorRecebido: valorRecebido,
        observacoes: _observacoesController.text,
      );

      final msgOperacional = WhatsAppMessageBuilder.buildOperacional(draft);
      final msgCliente = WhatsAppMessageBuilder.buildCliente(draft);
      
      // REGRA DE NEGÓCIO: BAIXA DE ESTOQUE (Mockada na UI para o EOS-004.8)
      for (var item in draft.itens) {
        item.tamanhoEscolhido.consumir(item.quantidade);
      }

      const whatsappCozinhaMock = '5511999999999';

      await widget.whatsappService.enviarMensagem(telefone: whatsappCozinhaMock, mensagem: msgOperacional);
      await Future.delayed(const Duration(milliseconds: 600));
      await widget.whatsappService.enviarMensagem(telefone: draft.cliente!.telefoneWhatsApp, mensagem: msgCliente);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp acionado com sucesso!')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Não foi possível finalizar.\nVerifique os dados: ${e.toString().replaceAll('Exception: Domínio: ', '')}'),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 4),
      ));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }
}
