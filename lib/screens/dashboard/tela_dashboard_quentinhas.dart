import 'package:flutter/material.dart';
import '../../models/models_quentinha.dart';
import '../../theme/app_theme.dart';
import '../../widgets/card_oferta_quentinha.dart';
import '../../widgets/carrinho_lateral_widget.dart';
import '../checkout/tela_checkout_mock.dart';

import '../../services/whatsapp_service.dart';

class TelaDashboardQuentinhas extends StatefulWidget {
  final WhatsAppService? whatsappService;

  const TelaDashboardQuentinhas({super.key, this.whatsappService});

  @override
  State<TelaDashboardQuentinhas> createState() => _TelaDashboardQuentinhasState();
}

class _TelaDashboardQuentinhasState extends State<TelaDashboardQuentinhas> {
  // Estado Local: Carrinho
  final List<ItemCarrinhoQuentinha> _carrinho = [];

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
        builder: (context) => TelaCheckoutMock(
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

  @override
  Widget build(BuildContext context) {
    // Breakpoint simples para responsividade
    final isDesktopOrTablet = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QUENTINHAS PRO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        actions: [
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
      body: Row(
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
                      if (isDesktopOrTablet)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5, // Ajuste para altura dos cards
                          ),
                          itemCount: mockCardapioHoje.length,
                          itemBuilder: (context, index) {
                            return CardOfertaQuentinha(
                              oferta: mockCardapioHoje[index],
                              onAdicionar: (TamanhoOpcao tamanho) =>
                                  _adicionarAoCarrinho(mockCardapioHoje[index], tamanho),
                            );
                          },
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: mockCardapioHoje.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: CardOfertaQuentinha(
                                oferta: mockCardapioHoje[index],
                                onAdicionar: (TamanhoOpcao tamanho) =>
                                    _adicionarAoCarrinho(mockCardapioHoje[index], tamanho),
                              ),
                            );
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildKPIItem('PEDIDOS HOJE', '27', AppTheme.primaryColor),
          _buildKPIItem('EM PRODUÇÃO', '8', AppTheme.secondaryColor),
          _buildKPIItem('PRONTOS', '6', AppTheme.successColor),
          _buildKPIItem('FATURAMENTO', 'R\$ 845,00', AppTheme.textDark),
        ],
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
