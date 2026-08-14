import 'package:flutter/material.dart';
import '../../models/models_quentinha.dart';
import '../../theme/app_theme.dart';

class TelaCheckoutMock extends StatefulWidget {
  final List<ItemCarrinhoQuentinha> itens;
  final double total;

  const TelaCheckoutMock({
    super.key,
    required this.itens,
    required this.total,
  });

  @override
  State<TelaCheckoutMock> createState() => _TelaCheckoutMockState();
}

class _TelaCheckoutMockState extends State<TelaCheckoutMock> {
  // Estado do formulário
  final _formKey = GlobalKey<FormState>();
  
  String _nome = '';
  String _whatsapp = '';
  TipoEntrega _tipoEntrega = TipoEntrega.retirada;
  
  // Endereço
  String _cep = '';
  String _logradouro = '';
  String _numero = '';
  String _bairro = '';
  String _complemento = '';
  
  FormaPagamentoDraft _formaPagamento = FormaPagamentoDraft.pix;
  String _observacoes = '';

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
                              decoration: const InputDecoration(labelText: 'Nome do Cliente', border: OutlineInputBorder()),
                              onChanged: (v) => _nome = v,
                              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'WhatsApp', border: OutlineInputBorder()),
                              keyboardType: TextInputType.phone,
                              onChanged: (v) => _whatsapp = v,
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
                                decoration: const InputDecoration(labelText: 'CEP', border: OutlineInputBorder()),
                                onChanged: (v) => _cep = v,
                                validator: (v) => _tipoEntrega == TipoEntrega.entrega && v!.isEmpty ? 'Obrigatório' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'Logradouro / Rua', border: OutlineInputBorder()),
                                onChanged: (v) => _logradouro = v,
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
                                decoration: const InputDecoration(labelText: 'Número', border: OutlineInputBorder()),
                                onChanged: (v) => _numero = v,
                                validator: (v) => _tipoEntrega == TipoEntrega.entrega && v!.isEmpty ? 'Obrigatório' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'Bairro', border: OutlineInputBorder()),
                                onChanged: (v) => _bairro = v,
                                validator: (v) => _tipoEntrega == TipoEntrega.entrega && v!.isEmpty ? 'Obrigatório' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'Complemento', border: OutlineInputBorder()),
                                onChanged: (v) => _complemento = v,
                              ),
                            ),
                          ],
                        ),
                      ]
                    ]),

                    const SizedBox(height: 24),
                    _buildSecao('OBSERVAÇÕES', [
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Observações do Pedido', border: OutlineInputBorder()),
                        maxLines: 2,
                        onChanged: (v) => _observacoes = v,
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
                            subtitle: Text('Tamanho ${item.tamanhoEscolhido.tamanho.nome}'),
                            trailing: Text('R\$ ${item.subtotal.toStringAsFixed(2)}'),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('SUBTOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('R\$ ${widget.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (_tipoEntrega == TipoEntrega.entrega) ...[
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TAXA DE ENTREGA'),
                          Text('R\$ 5.00'), // Mock
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL A PAGAR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(
                          'R\$ ${(_tipoEntrega == TipoEntrega.entrega ? widget.total + 5.0 : widget.total).toStringAsFixed(2)}',
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _finalizarDraft,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 24)),
                        child: const Text('FINALIZAR DRAFT', style: TextStyle(fontSize: 18)),
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

  void _finalizarDraft() {
    if (_formKey.currentState!.validate()) {
      // Aqui, futuramente, instanciaremos o PedidoDraft e enviaremos para a Transition Engine
      Navigator.pop(context, true);
    }
  }
}
