import 'package:flutter/material.dart';
import '../../services/catalogo_service.dart';
import 'package:lanchonete_controle/services/pedido_service.dart';
import 'package:lanchonete_controle/screens/gestao/tela_gestao_cardapio.dart';
import '../../main.dart';
import '../../models/models_quentinha.dart';
import '../../models/dominio.dart';
import '../../theme/app_theme.dart';
import '../../widgets/card_oferta_quentinha.dart';
import '../../widgets/dialog_adicionais_widget.dart';
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
  
  late Future<CatalogoCompleto> _futureCatalogo;
  late Future<List<Pedido>> _futurePedidos;
  final DashboardPedidoService _pedidoService = DashboardPedidoService();
  final CatalogoService _catalogoService = CatalogoService();
  List<AdicionalQuentinha> _adicionaisCarregados = [];

  @override
  void initState() {
    super.initState();
    _futureCatalogo = _catalogoService.buscarCatalogo().then((c) {
      _adicionaisCarregados = c.adicionais;
      return c;
    });
    _futurePedidos = _pedidoService.obterPedidos();
  }

  void _adicionarAoCarrinho(OfertaQuentinha oferta, TamanhoOpcao tamanho) async {
    List<AdicionalQuentinha> adicionaisSelecionados = [];

    if (_adicionaisCarregados.isNotEmpty && oferta.categoria != 'BEBIDA') {
      final List<AdicionalQuentinha>? result = await showDialog<List<AdicionalQuentinha>>(
        context: context,
        builder: (context) => DialogAdicionaisWidget(
          adicionaisDisponiveis: _adicionaisCarregados,
        ),
      );
      if (result != null) {
        adicionaisSelecionados = result;
      }
    }

    if (!mounted) return;

    setState(() {
      final index = _carrinho.indexWhere((item) {
        if (item.oferta.id != oferta.id || item.tamanhoEscolhido.tamanho != tamanho.tamanho) return false;
        if (item.adicionais.length != adicionaisSelecionados.length) return false;
        for (var a in adicionaisSelecionados) {
          if (!item.adicionais.any((ia) => ia.id == a.id)) return false;
        }
        return true;
      });

      if (index >= 0) {
        _carrinho[index].quantidade++;
      } else {
        _carrinho.add(ItemCarrinhoQuentinha(
          idItem: DateTime.now().millisecondsSinceEpoch.toString(),
          oferta: oferta,
          tamanhoEscolhido: tamanho,
          quantidade: 1,
          adicionais: adicionaisSelecionados,
        ));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(' () adicionado!'),
        backgroundColor: AppTheme.success,
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
          itens: List.from(_carrinho),
          total: totalAtual,
          whatsappService: widget.whatsappService ?? WhatsAppUrlLauncherService(),
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _carrinho.clear();
        _futurePedidos = _pedidoService.obterPedidos();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido enviado para produção com sucesso!'),
            backgroundColor: AppTheme.success,
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
        title: const Text('Fechar Caixa Atual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tem certeza que deseja fechar o caixa do PDV Atual? Informe o saldo final:'),
            const SizedBox(height: 10),
            TextField(
              controller: saldoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Saldo Final (R\$)'),
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
                      content: Text('O caixa foi fechado. Quebra: R\$ '),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        )
                      ]
                    )
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erro ao fechar caixa: '),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
            child: const Text('CONFIRMAR FECHAMENTO'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktopOrTablet = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: isDesktopOrTablet ? null : AppBar(
        title: const Text('Novo Pedido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.point_of_sale, color: Colors.orange),
            tooltip: 'Fechar Caixa',
            onPressed: _mostrarModalFechamentoCaixa,
          ),
          if (!isDesktopOrTablet)
            IconButton(
              icon: Badge(
                label: Text(''),
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
                          color: AppTheme.textSecondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Grid para desktop, Lista para mobile
                      FutureBuilder<CatalogoCompleto>(
                        future: _futureCatalogo,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                          }
                          if (snapshot.hasError) {
                            return Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Erro ao carregar cardápio. \n', textAlign: TextAlign.center, style: TextStyle(color: Colors.red))));
                          }
                          
                          final catalogoCompleto = snapshot.data;
                          final catalogo = catalogoCompleto?.ofertas ?? [];
                          if (catalogo.isEmpty) {
                            return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Nenhuma oferta disponível hoje.', style: TextStyle(color: Colors.grey))));
                          }

                          Map<String, List<OfertaQuentinha>> porCategoria = {};
                          for (var oferta in catalogo) {
                            if (!porCategoria.containsKey(oferta.categoria)) {
                              porCategoria[oferta.categoria] = [];
                            }
                            porCategoria[oferta.categoria]!.add(oferta);
                          }

                          List<Widget> sections = [];
                          for (var categoria in porCategoria.keys) {
                            sections.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Text(categoria, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                              ),
                            );
                            final itensCategoria = porCategoria[categoria]!;

                            if (isDesktopOrTablet) {
                              sections.add(GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.5,
                                ),
                                itemCount: itensCategoria.length,
                                itemBuilder: (context, index) {
                                  return CardOfertaQuentinha(
                                    oferta: itensCategoria[index],
                                    onAdicionar: (TamanhoOpcao tamanho) =>
                                        _adicionarAoCarrinho(itensCategoria[index], tamanho),
                                  );
                                },
                              ));
                            } else {
                              sections.add(ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: itensCategoria.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: CardOfertaQuentinha(
                                      oferta: itensCategoria[index],
                                      onAdicionar: (TamanhoOpcao tamanho) =>
                                          _adicionarAoCarrinho(itensCategoria[index], tamanho),
                                    ),
                                  );
                                },
                              ));
                            }
                          }
                          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: sections);
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
          final emProducao = hoje.where((p) => p.statusLogistico == 'EM_PRODUCAO').length;
          final prontos = hoje.where((p) => p.statusLogistico == 'PRONTO').length;
          final faturamento = hoje.fold(0.0, (sum, p) => sum + p.total);
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildKPIItem('PEDIDOS HOJE', '', AppTheme.primary),
              _buildKPIItem('EM PRODUÇÃO', '', AppTheme.warning),
              _buildKPIItem('PRONTOS', '', AppTheme.success),
              _buildKPIItem('FATURAMENTO', 'R\$ ', AppTheme.textPrimary),
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
            color: AppTheme.textSecondary,
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



