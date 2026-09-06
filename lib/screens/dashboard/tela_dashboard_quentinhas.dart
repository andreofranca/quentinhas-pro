import 'package:flutter/material.dart';
import '../../services/catalogo_service.dart';
import 'package:lanchonete_controle/services/pedido_service.dart';
import 'package:lanchonete_controle/screens/gestao/tela_gestao_cardapio.dart';
import '../../main.dart';
import '../../models/models_quentinha.dart';
import '../../models/dominio.dart';
import '../../theme/app_theme.dart';
import '../../widgets/card_oferta_quentinha.dart';
import '../../widgets/carrinho_lateral_widget.dart';
import '../checkout/tela_checkout.dart';

import '../../services/whatsapp_service.dart';
import '../../services/dashboard_pedido_service.dart';


class TelaDashboardQuentinhas extends StatefulWidget {
  final WhatsAppService? whatsappService;
  final Usuario? usuarioLogado;

  const TelaDashboardQuentinhas({super.key, this.whatsappService, this.usuarioLogado});

  @override
  State<TelaDashboardQuentinhas> createState() => _TelaDashboardQuentinhasState();
}

class _TelaDashboardQuentinhasState extends State<TelaDashboardQuentinhas> {
  // Estado Local: Carrinho
  final List<ItemCarrinhoQuentinha> _carrinho = [];
  
  late Future<List<OfertaQuentinha>> _futureCatalogo;
  late Future<List<Pedido>> _futurePedidos;
  final DashboardPedidoService _pedidoService = DashboardPedidoService();
  final CatalogoService _catalogoService = CatalogoService();

  @override
  void initState() {
    super.initState();
    _futureCatalogo = _catalogoService.buscarCatalogo();
    _futurePedidos = _pedidoService.obterPedidos();
  }

  void _adicionarAoCarrinho(OfertaQuentinha oferta, TamanhoOpcao tamanho) {
    setState(() {
      // Verifica se já existe o mesmo prato com o mesmo tamanho
      final index = _carrinho.indexWhere((item) =>
          item.oferta.id == oferta.id &&
          item.tamanhoEscolhido.tamanho == tamanho.tamanho);

      if (index >= 0) {
        _carrinho[index].quantidade++;
      } else {
        _carrinho.add(ItemCarrinhoQuentinha(
          idItem: DateTime.now().millisecondsSinceEpoch.toString(),
          oferta: oferta,
          tamanhoEscolhido: tamanho,
          quantidade: 1,
        ));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${oferta.nome} (${tamanho.tamanho.sigla}) adicionado!'),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _aumentarQuantidade(ItemCarrinhoQuentinha item) {
    setState(() {
      item.quantidade++;
    });
  }

  void _reduzirQuantidade(ItemCarrinhoQuentinha item) {
    setState(() {
      if (item.quantidade > 1) {
        item.quantidade--;
      } else {
        _removerDoCarrinho(item);
      }
    });
  }

  void _removerDoCarrinho(ItemCarrinhoQuentinha item) {
    setState(() {
      _carrinho.removeWhere((i) => i.idItem == item.idItem);
    });
  }

  void _finalizarPedido() async {
    if (_carrinho.isEmpty) return;
    
    double totalAtual = _carrinho.fold(0, (sum, item) => sum + item.subtotal);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaCheckout(
          itens: _carrinho,
          total: totalAtual,
          whatsappService: widget.whatsappService,
        ),
      ),
    );

    // Se result for true, o pedido foi confirmado com sucesso.
    if (result == true) {
      setState(() {
        _carrinho.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido enviado para produção com sucesso!'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _mostrarModalFechamentoCaixa() async {
    final saldoController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Fechar Caixa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Informe o saldo atual em dinheiro na gaveta:'),
            const SizedBox(height: 10),
            TextField(
              controller: saldoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Saldo Informado (R\$)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final saldo = double.tryParse(saldoController.text.replaceAll(',', '.')) ?? 0.0;
                final res = await CaixaService().fecharCaixa(saldo);
                if (context.mounted) {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Caixa Fechado'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Faturamento do Sistema: R\$ ${res['faturamentoSistema']}'),
                          Text('Saldo Informado: R\$ ${res['saldoInformado']}'),
                          Text('Diferença: R\$ ${res['diferenca']}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        )
                      ],
                    )
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: Colors.red.shade800,
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('FECHAR CAIXA', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Breakpoint simples para responsividade
    final isDesktopOrTablet = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QUENTINHAS PRO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Gestão de Cardápio',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaGestaoCardapio()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.point_of_sale),
            tooltip: 'Fechar Caixa',
            onPressed: _mostrarModalFechamentoCaixa,
          ),
          if (!isDesktopOrTablet)
            IconButton(
              icon: Badge(
                label: Text('${_carrinho.length}'),
                isLabelVisible: _carrinho.isNotEmpty,
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => FractionallySizedBox(
                    heightFactor: 0.9,
                    child: CarrinhoLateralWidget(
                      itens: _carrinho,
                      onAdicionarQuantidade: _aumentarQuantidade,
                      onReduzirQuantidade: _reduzirQuantidade,
                      onRemover: _removerDoCarrinho,
                      onFinalizar: () {
                        Navigator.pop(context);
                        _finalizarPedido();
                      },
                    ),
                  ),
                );
              },
            ),
          const SizedBox(width: 16),
        ],
      ),

      body:
 Row(
        children: [
          // Área Esquerda (Dashboard + Cardápio)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildTopKPIs(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      const Text(
                        'CARDÁPIO DE HOJE',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Grid para desktop, Lista para mobile
                      FutureBuilder<List<OfertaQuentinha>>(
                        future: _futureCatalogo,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                          }
                          if (snapshot.hasError) {
                            return Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Erro ao carregar cardápio. \n${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: Colors.red))));
                          }
                          
                          final catalogo = snapshot.data ?? [];
                          if (catalogo.isEmpty) {
                            return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Nenhuma oferta disponível hoje.', style: TextStyle(color: Colors.grey))));
                          }

                          if (isDesktopOrTablet) {
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.5, // Ajuste para altura dos cards
                              ),
                              itemCount: catalogo.length,
                              itemBuilder: (context, index) {
                                return CardOfertaQuentinha(
                                  oferta: catalogo[index],
                                  onAdicionar: (TamanhoOpcao tamanho) =>
                                      _adicionarAoCarrinho(catalogo[index], tamanho),
                                );
                              },
                            );
                          } else {
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: catalogo.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: CardOfertaQuentinha(
                                    oferta: catalogo[index],
                                    onAdicionar: (TamanhoOpcao tamanho) =>
                                        _adicionarAoCarrinho(catalogo[index], tamanho),
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Área Direita (Carrinho - Somente Desktop/Tablet)
          if (isDesktopOrTablet)
            Container(
              width: 380,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13), // ~0.05 opacity
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: CarrinhoLateralWidget(
                itens: _carrinho,
                onAdicionarQuantidade: _aumentarQuantidade,
                onReduzirQuantidade: _reduzirQuantidade,
                onRemover: _removerDoCarrinho,
                onFinalizar: _finalizarPedido,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopKPIs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: Colors.white,
      child: FutureBuilder<List<Pedido>>(
        future: _futurePedidos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final pedidos = snapshot.data ?? [];
          final hoje = pedidos.where((p) => p.dataHora.day == DateTime.now().day).toList();
          final emProducao = hoje.where((p) => p.statusLogistico == 'PREPARANDO').length;
          final prontos = hoje.where((p) => p.statusLogistico == 'PRONTO').length;
          final faturamento = hoje.fold(0.0, (sum, p) => sum + p.total);
          
          
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildKPIItem('PEDIDOS HOJE', '${hoje.length}', AppTheme.primaryColor),
              _buildKPIItem('EM PRODUÇÃO', '$emProducao', AppTheme.secondaryColor),
              _buildKPIItem('PRONTOS', '$prontos', AppTheme.successColor),
              _buildKPIItem('FATURAMENTO', 'R\$ ${faturamento.toStringAsFixed(2).replaceAll('.', ',')}', AppTheme.textDark),
            ],
          );
        }
      ),
    );
  }

  Widget _buildKPIItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

