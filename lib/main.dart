import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';
import 'formatters.dart'; 
import 'screens/teste_estoque_screen.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard/tela_dashboard_quentinhas.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tlpfusvvypkmggyxjbrw.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_QIjcG1GfDqCw2PRsZhW9sQ_5YdpZUma',
  );

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    runApp(const AppConfiguracaoInvalida());
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const AppLanchonete());
}

class AppConfiguracaoInvalida extends StatelessWidget {
  const AppConfiguracaoInvalida({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Configuracao ausente. Informe SUPABASE_URL e SUPABASE_ANON_KEY via --dart-define-from-file=dart_defines.local.json para iniciar o app.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}


// =============================================================================
// --- 1. MODELOS DE DADOS ---
// =============================================================================

class Produto {
  final String idProduto;
  String nome, descricao, categoria, imagemUrl; 
  double preco;
  int estoqueAtual;
  int estoqueMinimo; // Nível mínimo de alerta: abaixo disso = Crítico
  
  Produto({
    required this.idProduto, 
    required this.nome, 
    required this.descricao, 
    required this.preco, 
    required this.categoria, 
    required this.imagemUrl,
    this.estoqueAtual = estoqueDefault,
    this.estoqueMinimo = 8,
  });
}

class ItemCarrinho {
  final Produto produto;
  int quantidade;
  ItemCarrinho({required this.produto, this.quantidade = 1});
}

class ResultadoNotificacaoWhatsApp {
  final bool enviadoFabrica;
  final bool enviadoCliente;

  const ResultadoNotificacaoWhatsApp({
    required this.enviadoFabrica,
    required this.enviadoCliente,
  });

  bool get ambosEnviados => enviadoFabrica && enviadoCliente;
  bool get algumEnviado => enviadoFabrica || enviadoCliente;
}

class Pedido {
  final String numeroPedido, nomeCliente, telefoneCliente;
  String statusLogistico; 
  String statusPagamento; 
  final String tipoEntrega; 
  final String? enderecoCompleto; 
  final double taxaEntrega;
  final String formaPagamento;
  final double? trocoPara;
  final List<ItemCarrinho> itens;
  final double total;
  final DateTime dataHora;
  bool notificacaoNovoPedidoFabrica;
  bool notificacaoNovoPedidoCliente;
  bool notificacaoDespachoFabrica;
  bool notificacaoDespachoCliente;

  Pedido({
    required this.numeroPedido, 
    required this.nomeCliente, 
    required this.telefoneCliente, 
    required this.tipoEntrega, 
    this.enderecoCompleto, 
    required this.taxaEntrega,
    required this.formaPagamento, 
    this.trocoPara,
    required this.itens, 
    required this.total, 
    required this.dataHora, 
    this.statusLogistico = 'NOVO', 
    this.statusPagamento = 'AGUARDANDO',
    this.notificacaoNovoPedidoFabrica = false,
    this.notificacaoNovoPedidoCliente = false,
    this.notificacaoDespachoFabrica = false,
    this.notificacaoDespachoCliente = false,
  });
}

class Usuario {
  final String idUsuario; 
  String senha, nomeCompleto, cargo, cpf, telefone, email;
  String cep, logradouro, numero, complemento, bairro, cidade, uf; 
  bool situacaoConta;
  
  Usuario({ 
    required this.idUsuario, 
    required this.senha, 
    required this.nomeCompleto, 
    required this.cargo, 
    this.cpf = "", 
    this.telefone = "", 
    this.email = "", 
    this.cep = "", 
    this.logradouro = "", 
    this.numero = "", 
    this.complemento = "", 
    this.bairro = "", 
    this.cidade = "", 
    this.uf = "", 
    this.situacaoConta = true
  });
}

class RegistroDiferencaCaixa {
  final String id;
  final DateTime dataHora;
  final double faturamentoSistema;
  final double valorContado;
  final double diferenca;
  final String caixaId;
  final String gerenteId;
  final String observacao;
  RegistroDiferencaCaixa({required this.id, required this.dataHora, required this.faturamentoSistema, required this.valorContado, required this.diferenca, required this.caixaId, required this.gerenteId, required this.observacao});
}

// --- 2. BANCOS DE DADOS TEMPORÁRIOS ---
List<Usuario> listaUsuarios = [
  Usuario(idUsuario: "ANDRE", senha: "123", nomeCompleto: "André Administrador", cargo: "ADMIN"),
  Usuario(idUsuario: "JOAO", senha: "123", nomeCompleto: "João Atendente", cargo: "FUNCIONARIO") 
];
List<ItemCarrinho> carrinhoAtual = [];
List<Pedido> listaPedidosGerais = []; 
List<RegistroDiferencaCaixa> listaFechamentosDiferenca = [];

// =============================================================================
// 🍔 CARDÁPIO GIGANTE RESTAURADO (COM ESTOQUE)
// =============================================================================
List<Produto> cardapio = [
  Produto(idProduto: "L01", nome: "Smash Burger Duplo", descricao: "Pão brioche selado na manteiga, 2 blends de 90g, muito queijo cheddar e molho especial da casa.", preco: 28.90, categoria: "Lanches", imagemUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=600&auto=format&fit=crop", estoqueAtual: 20, estoqueMinimo: 10),
  Produto(idProduto: "L02", nome: "X-Bacon Artesanal", descricao: "Hambúrguer 150g suculento, fatias de bacon crocante, queijo derretido, alface e tomate fresco.", preco: 32.00, categoria: "Lanches", imagemUrl: "https://images.unsplash.com/photo-1553979459-d2229ba7433b?q=80&w=600&auto=format&fit=crop", estoqueAtual: 15, estoqueMinimo: 8),
  Produto(idProduto: "L03", nome: "Chicken Crispy", descricao: "Filé de frango empanado super crocante, maionese temperada, picles e alface americana.", preco: 26.50, categoria: "Lanches", imagemUrl: "https://images.unsplash.com/photo-1606755962773-d324e0a13086?q=80&w=600&auto=format&fit=crop", estoqueAtual: 5, estoqueMinimo: 8),
  Produto(idProduto: "L04", nome: "X-Tudo Monstro", descricao: "O gigante da casa! 2 hambúrgueres, salsicha, bacon, ovo, presunto, queijo e salada completa.", preco: 38.90, categoria: "Lanches", imagemUrl: "https://images.unsplash.com/photo-1586816001966-79b736744398?q=80&w=600&auto=format&fit=crop", estoqueAtual: 10, estoqueMinimo: 10),
  Produto(idProduto: "P01", nome: "Batata Suprema", descricao: "Porção generosa de batatas fritas crocantes com cobertura de cheddar cremoso e bacon em cubos.", preco: 24.90, categoria: "Porções", imagemUrl: "https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?q=80&w=600&auto=format&fit=crop", estoqueAtual: 30, estoqueMinimo: 15),
  Produto(idProduto: "P02", nome: "Onion Rings", descricao: "Anéis de cebola empanados e fritos, acompanhados do nosso molho barbecue especial.", preco: 19.90, categoria: "Porções", imagemUrl: "https://images.unsplash.com/photo-1639024470081-ce036f0a6e38?q=80&w=600&auto=format&fit=crop", estoqueAtual: 25, estoqueMinimo: 12),
  Produto(idProduto: "P03", nome: "Nuggets de Frango", descricao: "12 unidades de nuggets de frango super crocantes. Acompanha maionese verde da casa.", preco: 21.00, categoria: "Porções", imagemUrl: "https://images.unsplash.com/photo-1562967914-608f82629710?q=80&w=600&auto=format&fit=crop", estoqueAtual: 40, estoqueMinimo: 20),
  Produto(idProduto: "B01", nome: "Coca-Cola Lata", descricao: "Refrigerante 350ml bem gelado.", preco: 6.00, categoria: "Bebidas", imagemUrl: "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?q=80&w=600&auto=format&fit=crop", estoqueAtual: 100, estoqueMinimo: 30),
  Produto(idProduto: "B02", nome: "Suco de Laranja Natural", descricao: "Copo de 500ml de suco de laranja feito na hora, sem açúcar e sem água.", preco: 9.50, categoria: "Bebidas", imagemUrl: "https://images.unsplash.com/photo-1600271886742-f049cd451bba?q=80&w=600&auto=format&fit=crop", estoqueAtual: 50, estoqueMinimo: 15),
  Produto(idProduto: "B03", nome: "Milkshake de Morango", descricao: "Milkshake cremoso de morango batido com sorvete artesanal e chantilly.", preco: 16.90, categoria: "Bebidas", imagemUrl: "https://images.unsplash.com/photo-1572490122747-3968b75cc699?q=80&w=600&auto=format&fit=crop", estoqueAtual: 20, estoqueMinimo: 8),
  Produto(idProduto: "B04", nome: "Milkshake de Ovomaltine", descricao: "O clássico! Sorvete de baunilha batido com muito Ovomaltine crocante.", preco: 18.90, categoria: "Bebidas", imagemUrl: "https://images.unsplash.com/photo-1553177595-4de2bb0842b9?q=80&w=600&auto=format&fit=crop", estoqueAtual: 20, estoqueMinimo: 8),
  Produto(idProduto: "S01", nome: "Brownie com Sorvete", descricao: "Brownie de chocolate quente com uma bola de sorvete de baunilha e calda de chocolate.", preco: 18.00, categoria: "Sobremesas", imagemUrl: "https://images.unsplash.com/photo-1606313564200-e75d5e30476c?q=80&w=600&auto=format&fit=crop", estoqueAtual: 12, estoqueMinimo: 6),
  Produto(idProduto: "S02", nome: "Taça de Sorvete Artesanal", descricao: "Três bolas de sorvete à sua escolha, com chantilly, castanhas e cereja.", preco: 15.50, categoria: "Sobremesas", imagemUrl: "https://images.unsplash.com/photo-1557142046-c704a3adf364?q=80&w=600&auto=format&fit=crop", estoqueAtual: 15, estoqueMinimo: 6),
  Produto(idProduto: "S03", nome: "Torta de Chocolate", descricao: "Fatia generosa de torta mousse de chocolate meio amargo.", preco: 14.90, categoria: "Sobremesas", imagemUrl: "https://images.unsplash.com/photo-1606890737304-57a1ca8a5b62?q=80&w=600&auto=format&fit=crop", estoqueAtual: 8, estoqueMinimo: 5),
];

class AppLanchonete extends StatelessWidget {
  const AppLanchonete({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'Quentinhas Pro',
      theme: AppTheme.themeData,
      home: const TelaDashboardQuentinhas(),
    );
  }
}

class PainelTesteCompleto extends StatefulWidget {
  const PainelTesteCompleto({super.key});

  @override
  State<PainelTesteCompleto> createState() => _PainelTesteCompletoState();
}

class _PainelTesteCompletoState extends State<PainelTesteCompleto> {
  int _abaAtual = 0;

  late final List<Widget> _abas = const [
    TelaCardapioCliente(),
    TelaTesteEstoque(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _abaAtual,
        children: _abas,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaAtual,
        onDestinationSelected: (value) {
          setState(() {
            _abaAtual = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Sistema',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Estoque',
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// --- MÓDULO DO CLIENTE ---
// =============================================================================
class TelaCardapioCliente extends StatefulWidget { 
  const TelaCardapioCliente({super.key}); 
  @override State<TelaCardapioCliente> createState() => _TelaCardapioClienteState(); 
}

class _TelaCardapioClienteState extends State<TelaCardapioCliente> {
  void _adicionarAoCarrinho(Produto p) { 
    if (p.estoqueAtual <= 0) return; // TRAVA DE ESTOQUE
    setState(() { 
      int index = carrinhoAtual.indexWhere((item) => item.produto.idProduto == p.idProduto); 
      if (index != -1) {
        if (carrinhoAtual[index].quantidade < p.estoqueAtual) {
          carrinhoAtual[index].quantidade++;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Estoque máximo atingido!"), backgroundColor: Colors.orange));
          return;
        }
      } else {
        carrinhoAtual.add(ItemCarrinho(produto: p));
      }
    }); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${p.nome} adicionado!"), duration: const Duration(seconds: 1), backgroundColor: Colors.green)
    ); 
  }
  
  Widget _buildProdutoCard(Produto p) {
    bool esgotado = p.estoqueAtual <= 0;
    IconData iconCategoria = _getIconeCategoria(p.categoria);
    
    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // IMAGEM COM BADGES
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  p.imagemUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stk) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.fastfood, size: 50, color: Colors.grey),
                  ),
                ),
                // OVERLAY ESGOTADO
                if (esgotado)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Text(
                        "ESGOTADO",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                // BADGES NO CANTO SUPERIOR
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(iconCategoria, size: 16, color: corPrimaria),
                        const SizedBox(width: 6),
                        Text(
                          p.categoria,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: corPrimaria,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // BADGE DE ESTOQUE
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: esgotado ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      esgotado ? "SEM ESTOQUE" : "${p.estoqueAtual} em estoque",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // CONTEÚDO DO CARD
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NOME
                  Text(
                    p.nome,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // DESCRIÇÃO
                  Expanded(
                    child: Text(
                      p.descricao,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // PREÇO E BOTÃO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CurrencyHelper.formatCurrency(p.preco),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: esgotado ? Colors.grey : Colors.green,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: esgotado ? Colors.grey : corPrimaria,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: esgotado ? null : () => _adicionarAoCarrinho(p),
                        icon: Icon(
                          esgotado ? Icons.block : Icons.add_shopping_cart,
                          size: 18,
                        ),
                        label: Text(esgotado ? "Indisponível" : "Adicionar"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconeCategoria(String categoria) {
    switch (categoria) {
      case 'Lanches':
        return Icons.fastfood;
      case 'Bebidas':
        return Icons.local_drink;
      case 'Porções':
        return Icons.set_meal;
      case 'Sobremesas':
        return Icons.cake;
      default:
        return Icons.restaurant;
    }
  }

  @override 
  Widget build(BuildContext context) {
    int totalItens = carrinhoAtual.fold(0, (total, item) => total + item.quantidade);
    
    return DefaultTabController(
      length: categoriasMenu.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Cardápio Digital", style: TextStyle(fontWeight: FontWeight.bold)), 
          centerTitle: true, 
          leading: IconButton(
            icon: const Icon(Icons.lock_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TelaLogin()),
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: categoriasMenu
                .map((cat) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getIconeCategoria(cat), size: 20),
                      const SizedBox(width: 8),
                      Text(cat, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ))
                .toList(),
          ),
        ),
        body: TabBarView(
          children: categoriasMenu.map((categoria) {
            List<Produto> produtosCategoria =
                cardapio.where((p) => p.categoria == categoria).toList();
            
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: produtosCategoria.length,
                  itemBuilder: (context, index) {
                    return _buildProdutoCard(produtosCategoria[index]);
                  },
                ),
              ),
            );
          }).toList(),
        ),
        floatingActionButton: totalItens > 0
          ? FloatingActionButton.extended(
              backgroundColor: Colors.green,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TelaCheckoutExpresso(),
                ),
              ).then((_) => setState(() {})),
              icon: const Icon(Icons.shopping_bag, color: Colors.white),
              label: Text(
                "Finalizar ($totalItens)",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
          : null,
      ),
    );
  }
}

class TelaCheckoutExpresso extends StatefulWidget { 
  const TelaCheckoutExpresso({super.key}); 
  @override State<TelaCheckoutExpresso> createState() => _TelaCheckoutExpressoState(); 
}

class _TelaCheckoutExpressoState extends State<TelaCheckoutExpresso> {
  final _chaveForm = GlobalKey<FormState>(); 
  final _nome = TextEditingController(); 
  final _telefone = TextEditingController(); 
  final _cep = TextEditingController(); 
  final _logradouro = TextEditingController(); 
  final _numero = TextEditingController(); 
  final _complemento = TextEditingController(); 
  final _bairro = TextEditingController(); 
  final _cidade = TextEditingController(); 
  final _trocoPara = TextEditingController();
  
  bool _buscandoCep = false; 
  String _tipoEntrega = 'ENTREGA'; 
  String _formaPagamento = 'PIX'; 
  bool _precisaTroco = false;
  
  double get subtotal => carrinhoAtual.fold(0, (total, item) => total + (item.produto.preco * item.quantidade)); 
  double get taxaAplicada => _tipoEntrega == 'ENTREGA' ? taxaEntregaFixa : 0.0; 
  double get valorTotal => subtotal + taxaAplicada;

  String _normalizarTelefoneWhatsApp(String telefone) {
    var telefoneLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!telefoneLimpo.startsWith(whatsappPais)) {
      telefoneLimpo = '$whatsappPais$telefoneLimpo';
    }
    return telefoneLimpo;
  }

  Future<void> _abrirConversaWhatsApp({
    required String telefone,
    required String mensagem,
  }) async {
    final uri = Uri.parse(
      'https://api.whatsapp.com/send?phone=$telefone&text=${Uri.encodeComponent(mensagem)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    throw Exception(msgErroWhatsapp);
  }

  String _montarMensagemNovoPedidoFabrica({
    required Pedido pedido,
    required String textoItens,
    required String cabecalhoLogistica,
    required String detalhesPagamento,
  }) {
    return '*NOVO PEDIDO: ${pedido.numeroPedido}*\n\n*Cliente:* ${pedido.nomeCliente}\n*Contato:* ${pedido.telefoneCliente}\n\n$cabecalhoLogistica\n*ITENS:*\n$textoItens\n\n---------------------------\n*SUBTOTAL:* R\$ ${subtotal.toStringAsFixed(2).replaceAll('.', ',')}\n*TOTAL A PAGAR: R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}*\n---------------------------\n\n$detalhesPagamento\n\n⏳ _Tempo estimado: 40 a 60 minutos._\nPor favor, confirmem o recebimento do pedido!';
  }

  String _montarMensagemNovoPedidoCliente({
    required Pedido pedido,
    required String textoItens,
    required double valorDinheiroCliente,
    required double valorTrocoCalculado,
  }) {
    var mensagemCliente = 'Olá, ${pedido.nomeCliente}!\n\nSeu pedido *${pedido.numeroPedido}* foi registrado com sucesso na lanchonete.\n\n*Resumo do pedido:*\n$textoItens\n\n*Total:* R\$ ${pedido.total.toStringAsFixed(2).replaceAll('.', ',')}\n*Entrega:* ${pedido.tipoEntrega}';

    if (pedido.tipoEntrega == 'ENTREGA' && pedido.enderecoCompleto != null) {
      mensagemCliente += '\n*Endereço:* ${pedido.enderecoCompleto}';
    }

    mensagemCliente += '\n*Pagamento:* ${pedido.formaPagamento}';

    if (pedido.formaPagamento == 'DINHEIRO' && valorDinheiroCliente > 0) {
      mensagemCliente += '\n*Troco para:* R\$ ${valorDinheiroCliente.toStringAsFixed(2).replaceAll('.', ',')}';
      mensagemCliente += '\n*Troco previsto:* R\$ ${valorTrocoCalculado.toStringAsFixed(2).replaceAll('.', ',')}';
    }

    mensagemCliente += '\n\nEstamos preparando seu pedido. Em breve enviaremos nova atualização.';
    return mensagemCliente;
  }

  Future<ResultadoNotificacaoWhatsApp> _enviarMensagensNovoPedido({
    required Pedido pedido,
    required String textoItens,
    required String cabecalhoLogistica,
    required String detalhesPagamento,
    required double valorDinheiroCliente,
    required double valorTrocoCalculado,
  }) async {
    bool enviadoFabrica = false;
    bool enviadoCliente = false;

    final mensagemFabrica = _montarMensagemNovoPedidoFabrica(
      pedido: pedido,
      textoItens: textoItens,
      cabecalhoLogistica: cabecalhoLogistica,
      detalhesPagamento: detalhesPagamento,
    );
    final mensagemCliente = _montarMensagemNovoPedidoCliente(
      pedido: pedido,
      textoItens: textoItens,
      valorDinheiroCliente: valorDinheiroCliente,
      valorTrocoCalculado: valorTrocoCalculado,
    );

    try {
      await _abrirConversaWhatsApp(
        telefone: whatsappLanchonete,
        mensagem: mensagemFabrica,
      );
      enviadoFabrica = true;
    } catch (e) {
      debugPrint('Falha ao abrir WhatsApp da fabrica: $e');
    }

    await Future.delayed(const Duration(milliseconds: 600));

    try {
      await _abrirConversaWhatsApp(
        telefone: _normalizarTelefoneWhatsApp(pedido.telefoneCliente),
        mensagem: mensagemCliente,
      );
      enviadoCliente = true;
    } catch (e) {
      debugPrint('Falha ao abrir WhatsApp do cliente: $e');
    }

    return ResultadoNotificacaoWhatsApp(
      enviadoFabrica: enviadoFabrica,
      enviadoCliente: enviadoCliente,
    );
  }
  
  Future<void> _buscarCEP() async { 
    String cep = _cep.text.replaceAll(RegExp(r'[^0-9]'), ''); 
    if (cep.length != 8) return; 
    setState(() => _buscandoCep = true); 
    try { 
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/')); 
      if (!mounted) return; 
      if (response.statusCode == 200) { 
        var dados = jsonDecode(response.body); 
        if (dados['erro'] == null) { 
          setState(() { 
            _logradouro.text = dados['logradouro'] ?? ''; 
            _bairro.text = dados['bairro'] ?? ''; 
            _cidade.text = dados['localidade'] ?? ''; 
          }); 
        } 
      } 
    } catch (e) {
      debugPrint("Erro CEP: $e");
    } finally { 
      setState(() => _buscandoCep = false); 
    } 
  }
  
  Future<void> _finalizarPedido() async {
    if (_chaveForm.currentState!.validate()) {
      if (carrinhoAtual.isEmpty) return;
      
      double valorTrocoCalculado = 0; 
      double valorDinheiroCliente = 0;
      
      if (_formaPagamento == 'DINHEIRO' && _precisaTroco) { 
        valorDinheiroCliente = double.tryParse(_trocoPara.text.replaceAll(',', '.')) ?? 0; 
        if (valorDinheiroCliente <= valorTotal) { 
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("O valor para troco deve ser maior que o total!"), backgroundColor: Colors.red)); 
          return; 
        } 
        valorTrocoCalculado = valorDinheiroCliente - valorTotal; 
      }
      
      // REGRA DE NEGÓCIO: BAIXA DE ESTOQUE
      for (var item in carrinhoAtual) {
        Produto pReal = cardapio.firstWhere((p) => p.idProduto == item.produto.idProduto);
        pReal.estoqueAtual -= item.quantidade;
      }

      String numeroPedido = "#PED-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}"; 
      String? enderecoMontado;
      
      if (_tipoEntrega == 'ENTREGA') {
        enderecoMontado = "${_logradouro.text}, ${_numero.text} - ${_complemento.text.isNotEmpty ? '(${_complemento.text}) - ' : ''}${_bairro.text}, ${_cidade.text}";
      }
      
      listaPedidosGerais.add(Pedido(
        numeroPedido: numeroPedido, 
        nomeCliente: _nome.text, 
        telefoneCliente: _telefone.text, 
        tipoEntrega: _tipoEntrega, 
        taxaEntrega: taxaAplicada, 
        enderecoCompleto: enderecoMontado, 
        formaPagamento: _formaPagamento, 
        trocoPara: valorDinheiroCliente > 0 ? valorDinheiroCliente : null, 
        itens: List.from(carrinhoAtual), 
        total: valorTotal, 
        dataHora: DateTime.now()
      ));
      
      String textoItens = carrinhoAtual.map((i) => "${i.quantidade}x ${i.produto.nome} (${CurrencyHelper.formatCurrency(i.produto.preco * i.quantidade)})" ).join('\n');
      String cabecalhoLogistica = _tipoEntrega == 'ENTREGA' ? "🛵 *ENTREGA EM:*\n$enderecoMontado\n*Taxa de Entrega:* ${CurrencyHelper.formatCurrency(taxaAplicada)}\n" : "🛍️ *RETIRADA NO BALCÃO*\nO cliente virá buscar na loja.\n";
      String detalhesPagamento = "*Forma de Pagamento:* $_formaPagamento"; 
      
      if (_formaPagamento == 'DINHEIRO') {
        detalhesPagamento += _precisaTroco ? "\n*Troco para:* R\$ ${valorDinheiroCliente.toStringAsFixed(2).replaceAll('.', ',')} *(Levar R\$ ${valorTrocoCalculado.toStringAsFixed(2).replaceAll('.', ',')} de troco)*" : "\n*Não precisa de troco.*";
      }
      
      final pedidoCriado = listaPedidosGerais.last;

      final resultadoNotificacao = await _enviarMensagensNovoPedido(
          pedido: pedidoCriado,
          textoItens: textoItens,
          cabecalhoLogistica: cabecalhoLogistica,
          detalhesPagamento: detalhesPagamento,
          valorDinheiroCliente: valorDinheiroCliente,
          valorTrocoCalculado: valorTrocoCalculado,
        );

      pedidoCriado.notificacaoNovoPedidoFabrica = resultadoNotificacao.enviadoFabrica;
      pedidoCriado.notificacaoNovoPedidoCliente = resultadoNotificacao.enviadoCliente;

      if (mounted) {
        if (resultadoNotificacao.ambosEnviados) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pedido encaminhado para a fabrica e para o cliente.'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (resultadoNotificacao.algumEnviado) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pedido aberto apenas parcialmente no WhatsApp. Use a comanda para reenviar o que faltar.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nao foi possivel abrir as conversas do WhatsApp. Use a comanda para tentar novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      
      setState(() => carrinhoAtual.clear()); 
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Finalizar Pedido")),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900), 
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              // LADO ESQUERDO: RESUMO
              Expanded(
                flex: 1, 
                child: Container(
                  color: Colors.white, 
                  padding: const EdgeInsets.all(24), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      const Text("Seu Pedido", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), 
                      const Divider(), 
                      Expanded(
                        child: ListView.builder(
                          itemCount: carrinhoAtual.length, 
                          itemBuilder: (context, index) { 
                            final item = carrinhoAtual[index]; 
                            return ListTile(
                              contentPadding: EdgeInsets.zero, 
                              title: Text("${item.quantidade}x ${item.produto.nome}"), 
                              trailing: Text(CurrencyHelper.formatCurrency(item.produto.preco * item.quantidade), style: const TextStyle(fontWeight: FontWeight.bold))
                            ); 
                          }
                        )
                      ), 
                      const Divider(), 
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: [const Text("Subtotal:"), Text(CurrencyHelper.formatCurrency(subtotal))]
                      ), 
                      if (_tipoEntrega == 'ENTREGA') 
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0), 
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                            children: [const Text("Taxa de Entrega:", style: TextStyle(color: Colors.red)), Text("+ R\$ ${taxaAplicada.toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(color: Colors.red))]
                          )
                        ), 
                      const Divider(), 
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: [
                          const Text("TOTAL:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), 
                          Expanded(child: FittedBox(alignment: Alignment.centerRight, fit: BoxFit.scaleDown, child: Text(CurrencyHelper.formatCurrency(valorTotal), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green))))
                        ]
                      )
                    ]
                  )
                )
              ),
              // LADO DIREITO: FORMULÁRIO 
              Expanded(
                flex: 2, 
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32), 
                  child: Form(
                    key: _chaveForm, 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        const Text("1. Como deseja receber?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)), 
                        const SizedBox(height: 10), 
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment<String>(
                                value: 'ENTREGA',
                                icon: Icon(Icons.moped),
                                label: Text('Entrega'),
                              ),
                              ButtonSegment<String>(
                                value: 'RETIRADA',
                                icon: Icon(Icons.storefront),
                                label: Text('Retirada na Loja'),
                              ),
                            ],
                            selected: {_tipoEntrega},
                            showSelectedIcon: false,
                            onSelectionChanged: (selecionados) {
                              setState(() => _tipoEntrega = selecionados.first);
                            },
                          ),
                        ), 
                        const SizedBox(height: 20),
                        
                        const Text("2. Seus Dados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)), 
                        const SizedBox(height: 15), 
                        Row(
                          children: [
                            Expanded(
                              flex: 2, 
                              child: TextFormField(
                                controller: _nome, textInputAction: TextInputAction.next, inputFormatters: [PrimeiraLetraMaiusculaFormatter()], 
                                decoration: const InputDecoration(labelText: 'Como quer ser chamado? *', hintText: 'Seu Nome'), 
                                validator: (v) => v!.isEmpty ? 'Obrigatório' : null
                              )
                            ), 
                            const SizedBox(width: 15), 
                            Expanded(
                              child: TextFormField(
                                controller: _telefone, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next, 
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly, TelefoneInputFormatter()], 
                                decoration: const InputDecoration(labelText: 'WhatsApp *', hintText: '(00) 00000-0000'), 
                                validator: (v) => v!.length < 14 ? 'Telefone inválido' : null
                              )
                            )
                          ]
                        ), 
                        const SizedBox(height: 20),
                        
                        if (_tipoEntrega == 'ENTREGA') ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cep, keyboardType: TextInputType.number, textInputAction: TextInputAction.next, 
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, CepInputFormatter()], 
                                  decoration: InputDecoration(
                                    labelText: 'CEP *', 
                                    suffixIcon: _buscandoCep ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search)
                                  ), 
                                  validator: (v) => v!.isEmpty ? 'Obrigatório' : null, 
                                  onChanged: (v) { if (v.length == 9) _buscarCEP(); }
                                )
                              ), 
                              const SizedBox(width: 15), 
                              Expanded(
                                flex: 2, 
                                child: TextFormField(
                                  controller: _logradouro, decoration: const InputDecoration(labelText: 'Rua / Avenida *'), 
                                  validator: (v) => v!.isEmpty ? 'Obrigatório' : null
                                )
                              )
                            ]
                          ), 
                          const SizedBox(height: 20), 
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _numero, textInputAction: TextInputAction.next, inputFormatters: [NumeroEnderecoFormatter()], 
                                  decoration: const InputDecoration(labelText: 'Número *', hintText: '123 ou SN'), 
                                  validator: (v) => v!.isEmpty ? 'Obrigatório' : null
                                )
                              ), 
                              const SizedBox(width: 15), 
                              Expanded(
                                flex: 2, 
                                child: TextFormField(
                                  controller: _complemento, textInputAction: TextInputAction.next, 
                                  decoration: const InputDecoration(labelText: 'Complemento', hintText: 'Apto, Bloco...')
                                )
                              )
                            ]
                          ), 
                          const SizedBox(height: 20), 
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _bairro, decoration: const InputDecoration(labelText: 'Bairro *'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null
                                )
                              ), 
                              const SizedBox(width: 15), 
                              Expanded(
                                child: TextFormField(
                                  controller: _cidade, decoration: const InputDecoration(labelText: 'Cidade *'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null
                                )
                              )
                            ]
                          ), 
                          const SizedBox(height: 30)
                        ],
                        
                        const Text("3. Pagamento", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)), 
                        const SizedBox(height: 15), 
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _formaPagamento, 
                                items: ['PIX', 'CRÉDITO', 'DÉBITO', 'DINHEIRO'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), 
                                onChanged: (v) => setState(() { _formaPagamento = v!; _precisaTroco = false; _trocoPara.clear(); }), 
                                decoration: const InputDecoration(labelText: 'Forma de Pagamento')
                              )
                            ), 
                            const SizedBox(width: 15), 
                            if (_formaPagamento == 'DINHEIRO') ...[
                              Expanded(
                                child: Column(
                                  children: [
                                    SwitchListTile(
                                      title: const Text("Precisa de troco?"), activeThumbColor: Colors.green, value: _precisaTroco, 
                                      onChanged: (v) => setState(() => _precisaTroco = v)
                                    ), 
                                    if (_precisaTroco) 
                                      TextFormField(
                                        controller: _trocoPara, keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                                        decoration: const InputDecoration(labelText: 'Troco para quanto?', hintText: 'Ex: 100,00', prefixText: 'R\$ '), 
                                        validator: (v) => v!.isEmpty ? 'Informe o valor' : null
                                      )
                                  ]
                                )
                              )
                            ] else ...[
                              const Expanded(child: SizedBox())
                            ]
                          ]
                        ), 
                        const SizedBox(height: 40),
                        
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 60, 
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.pop(context), 
                                  icon: const Icon(Icons.arrow_back), label: const Text("VOLTAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                                )
                              )
                            ), 
                            const SizedBox(width: 15), 
                            Expanded(
                              flex: 2, 
                              child: SizedBox(
                                height: 60, 
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green), 
                                  onPressed: _finalizarPedido, 
                                  icon: const Icon(Icons.send_rounded, size: 28), label: const Text("ENVIAR PEDIDO", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                                )
                              )
                            )
                          ]
                        )
                      ]
                    )
                  )
                )
              )
            ]
          )
        )
      ),
    );
  }
}

// =============================================================================
// --- MÓDULO ERP (ADMINISTRAÇÃO E GESTÃO) ---
// =============================================================================
class TelaLogin extends StatefulWidget { 
  const TelaLogin({super.key}); 
  @override State<TelaLogin> createState() => _TelaLoginState(); 
}

class _TelaLoginState extends State<TelaLogin> {
  final _controleLogin = TextEditingController(); 
  final _controleSenha = TextEditingController();
  
  void _tentarLogin() {
    try {
      Usuario user = listaUsuarios.firstWhere((u) => u.idUsuario == _controleLogin.text.toUpperCase() && u.senha == _controleSenha.text);
      if (!user.situacaoConta) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Acesso Bloqueado. Conta inativada."), backgroundColor: Colors.red));
        return;
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TelaDashboard(usuarioLogado: user)));
    } catch (e) { 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Acesso Negado. Verifique usuário e senha."), backgroundColor: Colors.red)); 
    }
  }
  
  @override 
  Widget build(BuildContext context) { 
    return Scaffold(
      appBar: AppBar(title: const Text("Acesso Restrito")), 
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400), padding: const EdgeInsets.all(40.0), 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, 
            children: [
              const Icon(Icons.admin_panel_settings, size: 80, color: corPrimaria), const SizedBox(height: 40), 
              TextField(controller: _controleLogin, autofocus: true, inputFormatters: [UpperCaseTextFormatter()], decoration: const InputDecoration(labelText: 'USUÁRIO', prefixIcon: Icon(Icons.person))), const SizedBox(height: 20), 
              TextField(controller: _controleSenha, obscureText: true, onSubmitted: (_) => _tentarLogin(), decoration: const InputDecoration(labelText: 'SENHA', prefixIcon: Icon(Icons.lock))), const SizedBox(height: 30), 
              SizedBox(height: 55, child: ElevatedButton(onPressed: _tentarLogin, child: const Text("ENTRAR NO ERP")))
            ]
          )
        )
      )
    ); 
  }
}

class TelaDashboard extends StatefulWidget {
  final Usuario usuarioLogado; 
  const TelaDashboard({super.key, required this.usuarioLogado});
  @override State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  int _indiceMenuSelecionado = 0; // Inicia no Dashboard Financeiro

  Widget _obterTelaAtual() {
    switch (_indiceMenuSelecionado) {
      case 0: return TelaRelatoriosFinanceiros(usuarioLogado: widget.usuarioLogado); // NOVO: DASHBOARD
      case 1: return const TelaGestaoPedidos(); 
      case 2: return const TelaControleEstoqueRapido(); // NOVO: ESTOQUE
      case 3: return const TelaGestaoProdutos(); 
      case 4: return const TelaGestaoEquipe(); // NOVO: RH
      default: return const Center(child: Text("Módulo em Construção", style: TextStyle(fontSize: 24, color: Colors.grey)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250, color: corSidebar,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20), width: double.infinity, color: Colors.black26, 
                  child: Column(
                    children: [
                      const CircleAvatar(radius: 40, backgroundColor: corPrimaria, child: Icon(Icons.person, size: 40, color: Colors.white)), const SizedBox(height: 10), 
                      Text(widget.usuarioLogado.nomeCompleto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center), 
                      Text(widget.usuarioLogado.cargo, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12))
                    ]
                  )
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _ItemMenu(icone: Icons.analytics, titulo: "Fechamento & Relatórios", ativo: _indiceMenuSelecionado == 0, onTap: () => setState(() => _indiceMenuSelecionado = 0)),
                      _ItemMenu(icone: Icons.receipt_long, titulo: "Pedidos e Caixa", ativo: _indiceMenuSelecionado == 1, onTap: () => setState(() => _indiceMenuSelecionado = 1)),
                      _ItemMenu(icone: Icons.inventory_2, titulo: "Controle de Estoque", ativo: _indiceMenuSelecionado == 2, onTap: () => setState(() => _indiceMenuSelecionado = 2)),
                      _ItemMenu(icone: Icons.fastfood, titulo: "Cadastro de Produtos", ativo: _indiceMenuSelecionado == 3, onTap: () => setState(() => _indiceMenuSelecionado = 3)),
                      if (widget.usuarioLogado.cargo == 'ADMIN')
                        _ItemMenu(icone: Icons.badge, titulo: "Equipe & Acessos", ativo: _indiceMenuSelecionado == 4, onTap: () => setState(() => _indiceMenuSelecionado = 4)),
                    ],
                  ),
                ),
                ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text("Sair do ERP", style: TextStyle(color: Colors.redAccent)), onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TelaLogin())))
              ],
            ),
          ),
          Expanded(child: Container(color: corFundoEsmaecido, child: _obterTelaAtual()))
        ],
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final IconData icone; final String titulo; final bool ativo; final VoidCallback onTap;
  const _ItemMenu({required this.icone, required this.titulo, required this.ativo, required this.onTap});
  @override Widget build(BuildContext context) { 
    return ListTile(leading: Icon(icone, color: ativo ? corPrimaria : Colors.grey), title: Text(titulo, style: TextStyle(color: ativo ? Colors.white : Colors.grey, fontWeight: ativo ? FontWeight.bold : FontWeight.normal)), selected: ativo, selectedTileColor: Colors.white10, onTap: onTap); 
  }
}

// =============================================================================
// --- NOVOS MÓDULOS DE DIRETORIA ---
// =============================================================================

class TelaRelatoriosFinanceiros extends StatefulWidget {
  final Usuario usuarioLogado;
  const TelaRelatoriosFinanceiros({super.key, required this.usuarioLogado});
  @override State<TelaRelatoriosFinanceiros> createState() => _TelaRelatoriosFinanceirosState();
}

class _TelaRelatoriosFinanceirosState extends State<TelaRelatoriosFinanceiros> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _valorContadoController = TextEditingController();
  final _observacaoController = TextEditingController();
  bool _diferencaAutorizada = false;
  String _gerenteAutorizouId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _valorContadoController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  void _executarFechamento(double faturamentoSistema, double valorContado, double diferenca) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Fechamento de Caixa"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Faturamento sistema: R\$ ${faturamentoSistema.toStringAsFixed(2).replaceAll('.', ',')}"),
            if (diferenca.abs() > 0.01) ...[
              Text("Valor contado: R\$ ${valorContado.toStringAsFixed(2).replaceAll('.', ',')}"),
              Text("Diferença: R\$ ${diferenca.toStringAsFixed(2).replaceAll('.', ',')}", style: TextStyle(color: diferenca < 0 ? Colors.red : Colors.orange, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 8),
            const Text("Esta ação arquiva todos os pedidos concluídos e cancelados."),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              if (diferenca.abs() > 0.01 && _diferencaAutorizada) {
                listaFechamentosDiferenca.add(RegistroDiferencaCaixa(
                  id: 'FC-${DateTime.now().millisecondsSinceEpoch}',
                  dataHora: DateTime.now(),
                  faturamentoSistema: faturamentoSistema,
                  valorContado: valorContado,
                  diferenca: diferenca,
                  caixaId: widget.usuarioLogado.idUsuario,
                  gerenteId: _gerenteAutorizouId,
                  observacao: _observacaoController.text.trim(),
                ));
              }
              setState(() {
                listaPedidosGerais.removeWhere((p) => p.statusPagamento == 'PAGO' || p.statusLogistico == 'CANCELADO');
                _valorContadoController.clear();
                _observacaoController.clear();
                _diferencaAutorizada = false;
                _gerenteAutorizouId = '';
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Caixa fechado com sucesso!"), backgroundColor: Colors.green));
            },
            child: const Text("CONFIRMAR"),
          ),
        ],
      ),
    );
  }

  Future<void> _solicitarAutorizacaoGerente(double diferenca, double faturamentoSistema, double valorContado) async {
    final loginCtrl = TextEditingController();
    final senhaCtrl = TextEditingController();
    bool senhaVisivel = false;
    final autorizado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Row(children: [Icon(Icons.admin_panel_settings, color: Colors.deepOrange), SizedBox(width: 8), Text("Autorização Gerencial")]),
          content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Diferença de caixa detectada:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                  const SizedBox(height: 4),
                  Text("Sistema: R\$ ${faturamentoSistema.toStringAsFixed(2).replaceAll('.', ',')}"),
                  Text("Contado: R\$ ${valorContado.toStringAsFixed(2).replaceAll('.', ',')}"),
                  Text("Diferença: R\$ ${diferenca.toStringAsFixed(2).replaceAll('.', ',')}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: diferenca < 0 ? Colors.red : Colors.orange)),
                ]),
              ),
              const SizedBox(height: 16),
              const Text("Credenciais do gerente para autorização:"),
              const SizedBox(height: 12),
              TextField(controller: loginCtrl, inputFormatters: [UpperCaseTextFormatter()], decoration: const InputDecoration(labelText: "LOGIN GERENTE", prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 12),
              TextField(
                controller: senhaCtrl,
                obscureText: !senhaVisivel,
                decoration: InputDecoration(
                  labelText: "SENHA",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(icon: Icon(senhaVisivel ? Icons.visibility_off : Icons.visibility), onPressed: () => setDs(() => senhaVisivel = !senhaVisivel)),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              icon: const Icon(Icons.verified_user),
              label: const Text("AUTORIZAR"),
              onPressed: () {
                try {
                  final gerente = listaUsuarios.firstWhere((u) => u.idUsuario == loginCtrl.text.toUpperCase() && u.senha == senhaCtrl.text && u.cargo == 'ADMIN' && u.situacaoConta);
                  _gerenteAutorizouId = gerente.idUsuario;
                  Navigator.pop(ctx, true);
                } catch (_) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Credenciais inválidas ou usuário não é gerente."), backgroundColor: Colors.red));
                }
              },
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (autorizado == true) {
      setState(() => _diferencaAutorizada = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Diferença autorizada por $_gerenteAutorizouId"), backgroundColor: Colors.orange));
    }
  }

  Widget _kpiCard(String titulo, String valor, IconData icone, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Row(children: [
          CircleAvatar(radius: 22, backgroundColor: cor.withValues(alpha: 0.15), child: Icon(icone, color: cor, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 11)), Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))])),
        ]),
      ),
    );
  }

  Widget _pgtoCard(String titulo, double total, int count, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: cor.withValues(alpha: 0.35), width: 1.4)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text("R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}", style: TextStyle(fontSize: 20, color: cor, fontWeight: FontWeight.bold)),
          Text("$count pedido${count != 1 ? 's' : ''}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ),
    );
  }

  Widget _infoFechamento(String label, String valor, Color cor) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 4),
      Text(valor, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cor)),
    ]);
  }

  String _formatarDataHora(DateTime dt) => "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

  Widget _buildAbaRelatorioSintetico(List<Pedido> pagos, List<Pedido> cancelados) {
    final faturamentoTotal = pagos.fold<double>(0, (s, p) => s + p.total);
    final totalPix = pagos.where((p) => p.formaPagamento == 'PIX').fold<double>(0, (s, p) => s + p.total);
    final totalDinheiro = pagos.where((p) => p.formaPagamento == 'DINHEIRO').fold<double>(0, (s, p) => s + p.total);
    final totalCredito = pagos.where((p) => p.formaPagamento == 'CRÉDITO').fold<double>(0, (s, p) => s + p.total);
    final totalDebito = pagos.where((p) => p.formaPagamento == 'DÉBITO').fold<double>(0, (s, p) => s + p.total);
    final ticketMedio = pagos.isEmpty ? 0.0 : faturamentoTotal / pagos.length;
    final totalEntregas = pagos.where((p) => p.tipoEntrega == 'ENTREGA').length;
    final totalRetiradas = pagos.where((p) => p.tipoEntrega == 'RETIRADA').length;
    final totalTaxaEntrega = pagos.where((p) => p.tipoEntrega == 'ENTREGA').fold<double>(0, (s, p) => s + p.taxaEntrega);
    final aguardandoPgto = listaPedidosGerais.where((p) => p.statusPagamento == 'AGUARDANDO').length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _kpiCard("Faturamento Bruto", "R\$ ${faturamentoTotal.toStringAsFixed(2).replaceAll('.', ',')}", Icons.monetization_on, Colors.green),
          const SizedBox(width: 12),
          _kpiCard("Pedidos Concluídos", "${pagos.length}", Icons.check_circle, Colors.blue),
          const SizedBox(width: 12),
          _kpiCard("Ticket Médio", "R\$ ${ticketMedio.toStringAsFixed(2).replaceAll('.', ',')}", Icons.receipt, Colors.purple),
          const SizedBox(width: 12),
          _kpiCard("Cancelamentos", "${cancelados.length}", Icons.cancel, Colors.red),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _kpiCard("Entregas", "$totalEntregas pedidos", Icons.delivery_dining, Colors.indigo),
          const SizedBox(width: 12),
          _kpiCard("Retiradas", "$totalRetiradas pedidos", Icons.storefront, Colors.teal),
          const SizedBox(width: 12),
          _kpiCard("Taxa de Entrega", "R\$ ${totalTaxaEntrega.toStringAsFixed(2).replaceAll('.', ',')}", Icons.local_shipping, Colors.brown),
          const SizedBox(width: 12),
          _kpiCard("Aguard. Pagamento", "$aguardandoPgto", Icons.pending, aguardandoPgto > 0 ? Colors.orange : Colors.grey),
        ]),
        const SizedBox(height: 24),
        const Text("Resumo por Forma de Pagamento", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 12),
        Row(children: [
          _pgtoCard("PIX", totalPix, pagos.where((p) => p.formaPagamento == 'PIX').length, Colors.teal),
          const SizedBox(width: 12),
          _pgtoCard("Dinheiro", totalDinheiro, pagos.where((p) => p.formaPagamento == 'DINHEIRO').length, Colors.green),
          const SizedBox(width: 12),
          _pgtoCard("Crédito", totalCredito, pagos.where((p) => p.formaPagamento == 'CRÉDITO').length, Colors.orange),
          const SizedBox(width: 12),
          _pgtoCard("Débito", totalDebito, pagos.where((p) => p.formaPagamento == 'DÉBITO').length, Colors.blue),
        ]),
        if (listaFechamentosDiferenca.isNotEmpty) ...[
          const SizedBox(height: 28),
          const Text("Histórico de Diferenças de Caixa", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 12),
          ...listaFechamentosDiferenca.map((r) => Card(
            child: ListTile(
              leading: Icon(r.diferenca < 0 ? Icons.arrow_downward : Icons.arrow_upward, color: r.diferenca < 0 ? Colors.red : Colors.orange),
              title: Text("Fechamento em ${_formatarDataHora(r.dataHora)}"),
              subtitle: Text("Sistema: R\$ ${r.faturamentoSistema.toStringAsFixed(2).replaceAll('.', ',')}  |  Contado: R\$ ${r.valorContado.toStringAsFixed(2).replaceAll('.', ',')}  |  Dif.: R\$ ${r.diferenca.toStringAsFixed(2).replaceAll('.', ',')}${r.observacao.isNotEmpty ? '\n"${r.observacao}"' : ''}"),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text("Aut.: ${r.gerenteId}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text("Op.: ${r.caixaId}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ),
          )),
        ],
      ]),
    );
  }

  Widget _buildAbaRelatorioAnalitico(List<Pedido> pagos, List<Pedido> cancelados) {
    final totalGeral = pagos.fold<double>(0, (s, p) => s + p.total);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("Relatório Analítico de Pedidos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
            child: Text("Total: R\$ ${totalGeral.toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
          ),
        ]),
        const SizedBox(height: 20),
        if (pagos.isEmpty)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: Text("Nenhum pedido concluído nesta sessão.", style: TextStyle(color: Colors.grey, fontSize: 16))))
        else ...[
          const Text("PEDIDOS CONCLUÍDOS (PAGOS)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6))),
            child: const Row(children: [
              SizedBox(width: 110, child: Text("PEDIDO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey))),
              SizedBox(width: 60, child: Text("HORA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey))),
              Expanded(flex: 2, child: Text("CLIENTE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey))),
              SizedBox(width: 75, child: Text("TIPO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey))),
              Expanded(flex: 3, child: Text("ITENS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey))),
              SizedBox(width: 80, child: Text("PAGTO.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey))),
              SizedBox(width: 90, child: Text("TOTAL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey), textAlign: TextAlign.right)),
            ]),
          ),
          ...pagos.asMap().entries.map((e) {
            final p = e.value;
            final itens = p.itens.map((it) => "${it.quantidade}x ${it.produto.nome}").join(", ");
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: e.key.isEven ? Colors.white : Colors.grey.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(children: [
                SizedBox(width: 110, child: Text(p.numeroPedido, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo))),
                SizedBox(width: 60, child: Text("${p.dataHora.hour.toString().padLeft(2, '0')}:${p.dataHora.minute.toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 12))),
                Expanded(flex: 2, child: Text(p.nomeCliente, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                SizedBox(width: 75, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: p.tipoEntrega == 'RETIRADA' ? Colors.teal.shade50 : Colors.indigo.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text(p.tipoEntrega == 'RETIRADA' ? 'RETIRADA' : 'ENTREGA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: p.tipoEntrega == 'RETIRADA' ? Colors.teal : Colors.indigo), overflow: TextOverflow.ellipsis),
                )),
                Expanded(flex: 3, child: Text(itens, style: const TextStyle(fontSize: 11, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                SizedBox(width: 80, child: Text(p.formaPagamento, style: const TextStyle(fontSize: 11))),
                SizedBox(width: 90, child: Text("R\$ ${p.total.toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green), textAlign: TextAlign.right)),
              ]),
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("TOTAL — ${pagos.length} pedido${pagos.length != 1 ? 's' : ''}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
              Text("R\$ ${totalGeral.toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
            ]),
          ),
        ],
        if (cancelados.isNotEmpty) ...[
          const SizedBox(height: 28),
          const Text("PEDIDOS CANCELADOS", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          ...cancelados.map((p) {
            final itens = p.itens.map((it) => "${it.quantidade}x ${it.produto.nome}").join(", ");
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red.shade100)),
              child: Row(children: [
                const Icon(Icons.cancel, color: Colors.red, size: 15),
                const SizedBox(width: 8),
                SizedBox(width: 110, child: Text(p.numeroPedido, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red))),
                SizedBox(width: 60, child: Text("${p.dataHora.hour.toString().padLeft(2, '0')}:${p.dataHora.minute.toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 12))),
                Expanded(flex: 2, child: Text(p.nomeCliente, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                Expanded(flex: 4, child: Text(itens, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis)),
              ]),
            );
          }),
        ],
      ]),
    );
  }

  Widget _buildAbaFechamento(double faturamentoSistema) {
    final valorContadoStr = _valorContadoController.text.trim().replaceAll(',', '.');
    final valorContado = double.tryParse(valorContadoStr) ?? -1.0;
    final inputValido = valorContado >= 0;
    final diferenca = inputValido ? valorContado - faturamentoSistema : 0.0;
    final temDiferenca = inputValido && diferenca.abs() > 0.01;
    final podeFecchar = inputValido && (!temDiferenca || _diferencaAutorizada);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Fechamento de Caixa", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
        const SizedBox(height: 4),
        const Text("Confira o caixa físico e registre qualquer diferença antes de fechar.", style: TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)]),
          child: Row(children: [
            const CircleAvatar(radius: 28, backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.account_balance_wallet, color: Colors.green, size: 28)),
            const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Faturamento pelo Sistema", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
              Text("R\$ ${faturamentoSistema.toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green)),
              const Text("(total de pedidos marcados como PAGO nesta sessão)", style: TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Lançamento do Caixa", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 14),
            TextField(
              controller: _valorContadoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() { _diferencaAutorizada = false; _gerenteAutorizouId = ''; }),
              decoration: const InputDecoration(labelText: "Valor contado no caixa (R\$)", prefixIcon: Icon(Icons.attach_money), hintText: "Ex: 176,30"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _observacaoController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: "Observação (opcional)", prefixIcon: Icon(Icons.notes), hintText: "Ex: troco, erro de caixa, quebrado..."),
            ),
          ]),
        ),
        if (inputValido) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: temDiferenca ? (diferenca < 0 ? Colors.red.shade50 : Colors.orange.shade50) : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: temDiferenca ? (diferenca < 0 ? Colors.red.shade300 : Colors.orange.shade300) : Colors.green.shade300),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(temDiferenca ? Icons.warning_amber : Icons.check_circle, color: temDiferenca ? (diferenca < 0 ? Colors.red : Colors.orange) : Colors.green, size: 22),
                const SizedBox(width: 8),
                Text(temDiferenca ? (diferenca < 0 ? "CAIXA COM FALTA" : "CAIXA COM SOBRA") : "CAIXA CONFERIDO — SEM DIFERENÇA",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: temDiferenca ? (diferenca < 0 ? Colors.red : Colors.orange) : Colors.green)),
              ]),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _infoFechamento("Sistema", "R\$ ${faturamentoSistema.toStringAsFixed(2).replaceAll('.', ',')}", Colors.blueGrey),
                _infoFechamento("Contado", "R\$ ${valorContado.toStringAsFixed(2).replaceAll('.', ',')}", Colors.indigo),
                _infoFechamento("Diferença", "R\$ ${diferenca.toStringAsFixed(2).replaceAll('.', ',')}", temDiferenca ? (diferenca < 0 ? Colors.red : Colors.orange) : Colors.green),
              ]),
              if (temDiferenca && !_diferencaAutorizada) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text("Fechamento com diferença requer autorização gerencial.", style: TextStyle(color: Colors.red, fontSize: 13)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, padding: const EdgeInsets.all(14)),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text("SOLICITAR AUTORIZAÇÃO DO GERENTE", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _solicitarAutorizacaoGerente(diferenca, faturamentoSistema, valorContado),
                  ),
                ),
              ],
              if (_diferencaAutorizada) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(6)),
                  child: Row(children: [
                    const Icon(Icons.verified, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text("Dif. autorizada pelo gerente: $_gerenteAutorizouId", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ],
            ]),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: podeFecchar ? Colors.green : Colors.grey, padding: const EdgeInsets.all(18)),
            icon: const Icon(Icons.point_of_sale, size: 26),
            label: const Text("FECHAR CAIXA DO DIA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            onPressed: podeFecchar ? () => _executarFechamento(faturamentoSistema, inputValido ? valorContado : faturamentoSistema, diferenca) : null,
          ),
        ),
        const SizedBox(height: 8),
        if (!inputValido)
          const Text("Informe o valor contado para habilitar o fechamento.", style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center)
        else if (temDiferenca && !_diferencaAutorizada)
          const Text("Autorize a diferença com o gerente para prosseguir.", style: TextStyle(fontSize: 12, color: Colors.red), textAlign: TextAlign.center),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pagos = listaPedidosGerais.where((p) => p.statusPagamento == 'PAGO').toList();
    final cancelados = listaPedidosGerais.where((p) => p.statusLogistico == 'CANCELADO').toList();
    final faturamentoSistema = pagos.fold<double>(0, (s, p) => s + p.total);
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Fechamento & Relatórios", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
            Text("Operador: ${widget.usuarioLogado.nomeCompleto}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepOrange,
            tabs: const [
              Tab(icon: Icon(Icons.bar_chart), text: "SINTÉTICO"),
              Tab(icon: Icon(Icons.list_alt), text: "ANALÍTICO"),
              Tab(icon: Icon(Icons.point_of_sale), text: "FECHAMENTO"),
            ],
          ),
        ]),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAbaRelatorioSintetico(pagos, cancelados),
            _buildAbaRelatorioAnalitico(pagos, cancelados),
            _buildAbaFechamento(faturamentoSistema),
          ],
        ),
      ),
    ]);
  }
}

class TelaControleEstoqueRapido extends StatefulWidget { const TelaControleEstoqueRapido({super.key}); @override State<TelaControleEstoqueRapido> createState() => _TelaControleEstoqueRapidoState(); }
class _TelaControleEstoqueRapidoState extends State<TelaControleEstoqueRapido> {
  final TextEditingController _buscaController = TextEditingController();
  String _filtroCategoria = 'Todas';
  bool _mostrarApenasAlertas = false;
  bool _simulacaoReajusteAtiva = false;
  double _reajustePercentual = 0;

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  // Determina o status visual de cada produto
  _StatusEstoque _getStatus(Produto p) {
    if (p.estoqueAtual == 0) return _StatusEstoque.esgotado;
    if (p.estoqueAtual <= p.estoqueMinimo) return _StatusEstoque.critico;
    return _StatusEstoque.saudavel;
  }

  double _percentualCustoPorCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'lanches':
        return 0.42;
      case 'porções':
      case 'porcoes':
        return 0.38;
      case 'bebidas':
        return 0.30;
      case 'sobremesas':
        return 0.36;
      default:
        return 0.40;
    }
  }

  double _precoConsiderado(Produto p) {
    if (!_simulacaoReajusteAtiva) return p.preco;
    final fator = 1 + (_reajustePercentual / 100);
    return p.preco * fator;
  }

  double _custoUnitarioEstimado(Produto p) {
    return _precoConsiderado(p) * _percentualCustoPorCategoria(p.categoria);
  }

  double _margemUnitarioEstimado(Produto p) {
    return _precoConsiderado(p) - _custoUnitarioEstimado(p);
  }

  double _margemPercentualEstimado(Produto p) {
    final preco = _precoConsiderado(p);
    if (preco <= 0) return 0;
    return (_margemUnitarioEstimado(p) / preco) * 100;
  }

  bool _atendeFiltro(Produto p) {
    final busca = _buscaController.text.trim().toLowerCase();
    final nome = p.nome.toLowerCase();
    final categoriaOk = _filtroCategoria == 'Todas' || p.categoria == _filtroCategoria;
    final alertaOk = !_mostrarApenasAlertas || _getStatus(p) != _StatusEstoque.saudavel;
    final buscaOk = busca.isEmpty || nome.contains(busca);
    return categoriaOk && alertaOk && buscaOk;
  }

  List<String> _categoriasDisponiveis() {
    final categorias = cardapio.map((p) => p.categoria).toSet().toList()..sort();
    return ['Todas', ...categorias];
  }

  Widget _buildHeader(List<Produto> lista) {
    final esgotados = lista.where((p) => _getStatus(p) == _StatusEstoque.esgotado).length;
    final criticos  = lista.where((p) => _getStatus(p) == _StatusEstoque.critico).length;
    final saudaveis = lista.where((p) => _getStatus(p) == _StatusEstoque.saudavel).length;
    final valorEstimado = lista.fold<double>(0, (soma, p) => soma + (_precoConsiderado(p) * p.estoqueAtual));
    final margemEstoque = lista.fold<double>(0, (soma, p) => soma + (_margemUnitarioEstimado(p) * p.estoqueAtual));
    final margemMedia = lista.isEmpty ? 0.0 : lista.fold<double>(0, (soma, p) => soma + _margemPercentualEstimado(p)) / lista.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Wrap(
        runSpacing: 10,
        spacing: 10,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2, color: Colors.blueGrey, size: 28),
              SizedBox(width: 10),
              Text("Painel de Estoque", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          _buildChipResumo("Esgotados", esgotados, Colors.red, Icons.block),
          _buildChipResumo("Críticos", criticos, Colors.orange, Icons.warning_amber),
          _buildChipResumo("Saudáveis", saudaveis, Colors.green, Icons.check_circle_outline),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.indigo.withValues(alpha: 0.4))),
            child: Text("Valor estimado: ${CurrencyHelper.formatCurrency(valorEstimado)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 13)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.teal.withValues(alpha: 0.4))),
            child: Text("Margem total est.: ${CurrencyHelper.formatCurrency(margemEstoque)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.deepPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.4))),
            child: Text("Margem media: ${margemMedia.toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 13)),
          ),
          if (_simulacaoReajusteAtiva)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.withValues(alpha: 0.4))),
              child: Text("Simulação ativa: ${_reajustePercentual.toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _buildChipResumo(String label, int count, Color cor, IconData icone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: cor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: cor.withValues(alpha: 0.4))),
      child: Row(children: [
        Icon(icone, size: 16, color: cor),
        const SizedBox(width: 6),
        Text("$count $label", style: TextStyle(fontWeight: FontWeight.bold, color: cor, fontSize: 13))
      ]),
    );
  }

  IconData _getIconeCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'lanches':
        return Icons.lunch_dining;
      case 'porções':
      case 'porcoes':
        return Icons.restaurant;
      case 'bebidas':
        return Icons.local_drink;
      case 'sobremesas':
        return Icons.icecream;
      default:
        return Icons.fastfood;
    }
  }

  Widget _buildCardProduto(Produto p) {
    final status = _getStatus(p);
    final precoBase = p.preco;
    final precoSimulado = _precoConsiderado(p);
    final custoUnitarioEst = _custoUnitarioEstimado(p);
    final margemUnitEst = _margemUnitarioEstimado(p);
    final margemPctEst = _margemPercentualEstimado(p);
    Color borderColor;
    Color bgColor;
    Color badgeColor;
    IconData badgeIcon;
    String badgeTexto;

    switch (status) {
      case _StatusEstoque.esgotado:
        borderColor = Colors.red;
        bgColor = Colors.grey[100]!;
        badgeColor = Colors.red;
        badgeIcon = Icons.block;
        badgeTexto = "ESGOTADO!";
        break;
      case _StatusEstoque.critico:
        borderColor = Colors.orange;
        bgColor = Colors.white;
        badgeColor = Colors.orange;
        badgeIcon = Icons.warning_amber;
        badgeTexto = "Crítico: ${p.estoqueAtual} unid. (Mín: ${p.estoqueMinimo})";
        break;
      case _StatusEstoque.saudavel:
        borderColor = Colors.transparent;
        bgColor = Colors.white;
        badgeColor = Colors.green;
        badgeIcon = Icons.check_circle_outline;
        badgeTexto = "Saudável: ${p.estoqueAtual} unid.";
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: status == _StatusEstoque.saudavel ? Colors.grey.shade200 : borderColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: status == _StatusEstoque.saudavel ? Colors.transparent : borderColor,
              width: status == _StatusEstoque.saudavel ? 0 : 5,
            ),
          ),
        ),
        child: ListTile(
          dense: false,
          minVerticalPadding: 10,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 58,
              height: 58,
              child: p.imagemUrl.isEmpty
                  ? Container(
                      color: Colors.blueGrey.withValues(alpha: 0.12),
                      child: Icon(_getIconeCategoria(p.categoria), color: Colors.blueGrey),
                    )
                  : Image.network(
                      p.imagemUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.blueGrey.withValues(alpha: 0.12),
                        child: Icon(_getIconeCategoria(p.categoria), color: Colors.blueGrey),
                      ),
                    ),
            ),
          ),
          title: Text(
            p.nome.isEmpty ? p.idProduto : p.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(p.categoria, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
              const SizedBox(height: 2),
              Text(
                _simulacaoReajusteAtiva
                    ? "Preço base: ${CurrencyHelper.formatCurrency(precoBase)}  |  Simulado: ${CurrencyHelper.formatCurrency(precoSimulado)}"
                    : "Preço de venda: ${CurrencyHelper.formatCurrency(precoBase)}",
                style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                "Custo est.: ${CurrencyHelper.formatCurrency(custoUnitarioEst)}  |  Margem est.: ${CurrencyHelper.formatCurrency(margemUnitEst)} (${margemPctEst.toStringAsFixed(1)}%)",
                style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 15, color: badgeColor),
                  const SizedBox(width: 4),
                  Text(
                    badgeTexto,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ],
              ),
            ],
          ),
          trailing: SizedBox(
            width: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: p.estoqueAtual <= 0 ? null : () => setState(() => p.estoqueAtual--),
                  icon: Icon(Icons.remove_circle, color: p.estoqueAtual <= 0 ? Colors.grey : Colors.red),
                ),
                SizedBox(
                  width: 34,
                  child: Text(
                    "${p.estoqueAtual}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => p.estoqueAtual++),
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ORDENAÇÃO: menor estoque primeiro para priorizar atenção
    final listaOrdenada = [...cardapio]..sort((a, b) => a.estoqueAtual.compareTo(b.estoqueAtual));
    final listaFiltrada = listaOrdenada.where(_atendeFiltro).toList();
    final categorias = _categoriasDisponiveis();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(listaFiltrada),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _buscaController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Buscar produto no estoque',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categorias
                              .map(
                                (categoria) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(categoria),
                                    selected: _filtroCategoria == categoria,
                                    onSelected: (_) {
                                      setState(() {
                                        _filtroCategoria = categoria;
                                      });
                                    },
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      label: const Text('Somente alertas'),
                      selected: _mostrarApenasAlertas,
                      onSelected: (value) {
                        setState(() {
                          _mostrarApenasAlertas = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Switch(
                            value: _simulacaoReajusteAtiva,
                            onChanged: (value) {
                              setState(() {
                                _simulacaoReajusteAtiva = value;
                              });
                            },
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Simular reajuste de preço em lote (não altera dados salvos)',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _reajustePercentual = 0;
                                _simulacaoReajusteAtiva = false;
                              });
                            },
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('Resetar'),
                          ),
                        ],
                      ),
                      Slider(
                        value: _reajustePercentual,
                        min: -20,
                        max: 40,
                        divisions: 60,
                        label: '${_reajustePercentual.toStringAsFixed(1)}%',
                        onChanged: (value) {
                          setState(() {
                            _reajustePercentual = value;
                          });
                        },
                      ),
                      Text(
                        'Reajuste configurado: ${_reajustePercentual.toStringAsFixed(1)}%  |  Use para demonstrar cenário comercial sem impactar cadastro real.',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: listaFiltrada.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum produto encontrado para os filtros selecionados.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: listaFiltrada.length,
                    itemBuilder: (context, index) => _buildCardProduto(listaFiltrada[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

enum _StatusEstoque { esgotado, critico, saudavel }

class TelaGestaoEquipe extends StatefulWidget { const TelaGestaoEquipe({super.key}); @override State<TelaGestaoEquipe> createState() => _TelaGestaoEquipeState(); }
class _TelaGestaoEquipeState extends State<TelaGestaoEquipe> {
  @override Widget build(BuildContext context) { return Padding(padding: const EdgeInsets.all(32.0), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Equipe e Acessos (RH)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaCadastroUsuario())).then((_) => setState((){})), icon: const Icon(Icons.person_add), label: const Text("NOVO FUNCIONÁRIO"))]), const SizedBox(height: 20), Expanded(child: ListView.builder(itemCount: listaUsuarios.length, itemBuilder: (context, index) { final u = listaUsuarios[index]; return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: CircleAvatar(backgroundColor: u.situacaoConta ? Colors.blue : Colors.grey, child: const Icon(Icons.person, color: Colors.white)), title: Text(u.nomeCompleto, style: TextStyle(fontWeight: FontWeight.bold, decoration: u.situacaoConta ? null : TextDecoration.lineThrough)), subtitle: Text("Login: ${u.idUsuario} | Cargo: ${u.cargo}"), trailing: Row(mainAxisSize: MainAxisSize.min, children: [const Text("Ativo: ", style: TextStyle(color: Colors.grey)), Switch(value: u.situacaoConta, activeThumbColor: Colors.green, onChanged: (bool valor) { if (u.idUsuario == 'ANDRE' && valor == false) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("O Admin Mestre não pode ser desativado!"), backgroundColor: Colors.red)); return; } setState(() => u.situacaoConta = valor); }), IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TelaCadastroUsuario(usuarioOriginal: u))).then((_) => setState((){})))]))); }))])); }
}

class TelaCadastroUsuario extends StatefulWidget { final Usuario? usuarioOriginal; const TelaCadastroUsuario({super.key, this.usuarioOriginal}); @override State<TelaCadastroUsuario> createState() => _TelaCadastroUsuarioState(); }
class _TelaCadastroUsuarioState extends State<TelaCadastroUsuario> {
  final _chaveForm = GlobalKey<FormState>(); final _idUsuario = TextEditingController(); final _nomeCompleto = TextEditingController(); final _senha = TextEditingController(); String _cargo = 'FUNCIONARIO';
  @override void initState() { super.initState(); if (widget.usuarioOriginal != null) { final u = widget.usuarioOriginal!; _idUsuario.text = u.idUsuario; _nomeCompleto.text = u.nomeCompleto; _senha.text = u.senha; _cargo = u.cargo; } }
  void _salvarUsuario() { if (_chaveForm.currentState!.validate()) { if (widget.usuarioOriginal != null) { Usuario u = widget.usuarioOriginal!; u.nomeCompleto = _nomeCompleto.text; u.senha = _senha.text; u.cargo = _cargo; } else { bool idJaExiste = listaUsuarios.any((u) => u.idUsuario == _idUsuario.text.toUpperCase()); if (idJaExiste) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Este Login já existe!"), backgroundColor: Colors.red)); return; } listaUsuarios.add(Usuario(idUsuario: _idUsuario.text.toUpperCase(), senha: _senha.text, nomeCompleto: _nomeCompleto.text, cargo: _cargo)); } Navigator.pop(context); } }
  @override Widget build(BuildContext context) { bool ehEdicao = widget.usuarioOriginal != null; return Scaffold(appBar: AppBar(title: Text(ehEdicao ? "Editar Funcionário" : "Novo Funcionário")), body: Center(child: Container(constraints: const BoxConstraints(maxWidth: 600), padding: const EdgeInsets.all(32), child: Form(key: _chaveForm, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Dados de Acesso", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)), const SizedBox(height: 15), TextFormField(controller: _nomeCompleto, autofocus: true, textInputAction: TextInputAction.next, inputFormatters: [PrimeiraLetraMaiusculaFormatter()], decoration: const InputDecoration(labelText: 'Nome Completo *', prefixIcon: Icon(Icons.badge)), validator: (v) => v!.isEmpty ? 'Obrigatório' : null), const SizedBox(height: 20), Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: TextFormField(controller: _idUsuario, enabled: !ehEdicao, inputFormatters: [UpperCaseTextFormatter()], decoration: const InputDecoration(labelText: 'Login (ID) *', hintText: 'Ex: MARCOS', prefixIcon: Icon(Icons.person)), validator: (v) => v!.isEmpty ? 'Obrigatório' : null)), const SizedBox(width: 15), Expanded(child: TextFormField(controller: _senha, obscureText: true, decoration: const InputDecoration(labelText: 'Senha Segura *', prefixIcon: Icon(Icons.lock)), validator: (v) => v!.isEmpty ? 'Obrigatório' : null))]), const SizedBox(height: 20), DropdownButtonFormField<String>(initialValue: _cargo, decoration: const InputDecoration(labelText: 'Cargo / Permissão', prefixIcon: Icon(Icons.security)), items: ['ADMIN', 'FUNCIONARIO'].map((c) => DropdownMenuItem(value: c, child: Text(c == 'ADMIN' ? 'Administrador' : 'Atendente'))).toList(), onChanged: (v) => setState(() => _cargo = v!)), const SizedBox(height: 40), Row(mainAxisAlignment: MainAxisAlignment.end, children: [OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.cancel), label: const Text("CANCELAR")), const SizedBox(width: 15), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), onPressed: _salvarUsuario, icon: const Icon(Icons.save), label: const Text("SALVAR"))])])))))); }
}

// =============================================================================
// --- TELA DE GESTÃO DE PEDIDOS ---
// =============================================================================
class TelaGestaoPedidos extends StatefulWidget { const TelaGestaoPedidos({super.key}); @override State<TelaGestaoPedidos> createState() => _TelaGestaoPedidosState(); }
class _TelaGestaoPedidosState extends State<TelaGestaoPedidos> {
  Color _obterCorLogistica(String status) { switch (status) { case 'NOVO': return Colors.redAccent; case 'PREPARANDO': return Colors.amber; case 'DESPACHADO': return Colors.blueAccent; case 'ENTREGUE': return Colors.green; case 'CANCELADO': return Colors.grey; default: return Colors.black; } }
  IconData _obterIconeStatus(String status) { switch (status) { case 'NOVO': return Icons.schedule; case 'PREPARANDO': return Icons.local_fire_department; case 'DESPACHADO': return Icons.local_shipping; case 'ENTREGUE': return Icons.check_circle; case 'CANCELADO': return Icons.cancel; default: return Icons.help; } }

  String _normalizarTelefoneWhatsApp(String telefone) {
    var telefoneLimpo = telefone.replaceAll(RegExp(r'[^\d]'), '');
    if (!telefoneLimpo.startsWith(whatsappPais)) {
      telefoneLimpo = '$whatsappPais$telefoneLimpo';
    }
    return telefoneLimpo;
  }

  Future<void> _abrirConversaWhatsApp({
    required String telefone,
    required String mensagem,
  }) async {
    final uri = Uri.parse(
      'https://api.whatsapp.com/send?phone=$telefone&text=${Uri.encodeComponent(mensagem)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    throw Exception(msgErroWhatsapp);
  }

  String _resumirItensPedido(Pedido pedido) {
    return pedido.itens
        .map((item) => '${item.quantidade}x ${item.produto.nome}')
        .join('\n');
  }

  String _montarMensagemNovoPedidoCliente(Pedido pedido) {
    var mensagem = 'Olá ${pedido.nomeCliente}!\n\nSeu pedido ${pedido.numeroPedido} foi confirmado na lanchonete.\n\n*Itens:*\n${_resumirItensPedido(pedido)}\n\n*Total:* R\$ ${pedido.total.toStringAsFixed(2).replaceAll('.', ',')}\n*Pagamento:* ${pedido.formaPagamento}\n*Entrega:* ${pedido.tipoEntrega}';

    if (pedido.tipoEntrega == 'ENTREGA' && pedido.enderecoCompleto != null) {
      mensagem += '\n*Endereço:* ${pedido.enderecoCompleto}';
    }

    if (pedido.formaPagamento == 'DINHEIRO' && pedido.trocoPara != null) {
      mensagem += '\n*Troco para:* R\$ ${pedido.trocoPara!.toStringAsFixed(2).replaceAll('.', ',')}';
    }

    return '$mensagem\n\nEstamos preparando seu pedido.';
  }

  String _montarMensagemNovoPedidoFabrica(Pedido pedido) {
    final subtotalPedido = pedido.total - pedido.taxaEntrega;
    final logistica = pedido.tipoEntrega == 'ENTREGA'
        ? '🛵 *ENTREGA EM:*\n${pedido.enderecoCompleto ?? 'Endereço não informado'}\n*Taxa de Entrega:* R\$ ${pedido.taxaEntrega.toStringAsFixed(2).replaceAll('.', ',')}'
        : '🛍️ *RETIRADA NO BALCÃO*';

    var mensagem = '*NOVO PEDIDO: ${pedido.numeroPedido}*\n\n*Cliente:* ${pedido.nomeCliente}\n*Contato:* ${pedido.telefoneCliente}\n\n$logistica\n\n*ITENS:*\n${_resumirItensPedido(pedido)}\n\n---------------------------\n*SUBTOTAL:* R\$ ${subtotalPedido.toStringAsFixed(2).replaceAll('.', ',')}\n*TOTAL A PAGAR:* R\$ ${pedido.total.toStringAsFixed(2).replaceAll('.', ',')}\n---------------------------\n\n*Forma de Pagamento:* ${pedido.formaPagamento}';

    if (pedido.formaPagamento == 'DINHEIRO' && pedido.trocoPara != null) {
      final valorTroco = pedido.trocoPara! - pedido.total;
      mensagem += '\n*Troco para:* R\$ ${pedido.trocoPara!.toStringAsFixed(2).replaceAll('.', ',')}';
      mensagem += '\n*Levar de troco:* R\$ ${valorTroco.toStringAsFixed(2).replaceAll('.', ',')}';
    }

    return '$mensagem\n\nPor favor, confirmem o recebimento do pedido!';
  }

  String _montarMensagemDespachoCliente(Pedido pedido) {
    if (pedido.tipoEntrega == 'RETIRADA') {
      return 'Olá ${pedido.nomeCliente}! 🛍️\n\nSeu pedido ${pedido.numeroPedido} está pronto para retirada na loja!\n\n*Total:* R\$ ${pedido.total.toStringAsFixed(2).replaceAll('.', ',')}\n*Pagamento:* ${pedido.formaPagamento}\n\nPode vir retirar no balcão. Estamos te aguardando!';
    }

    return 'Olá ${pedido.nomeCliente}! 🚚\n\nSeu pedido ${pedido.numeroPedido} saiu para entrega!\n\n*Total:* R\$ ${pedido.total.toStringAsFixed(2).replaceAll('.', ',')}\n*Pagamento:* ${pedido.formaPagamento}\n\nAcompanhe seu pedido e esteja pronto para receber.';
  }

  String _montarMensagemDespachoFabrica(Pedido pedido) {
    if (pedido.tipoEntrega == 'RETIRADA') {
      return '*ATUALIZACAO DE RETIRADA*\n\nPedido ${pedido.numeroPedido} pronto para retirada no balcão.\nCliente: ${pedido.nomeCliente}\nTelefone: ${pedido.telefoneCliente}\nTotal: R\$ ${pedido.total.toStringAsFixed(2).replaceAll('.', ',')}\n\nStatus logístico atualizado para DESPACHADO (RETIRADA).';
    }

    return '*ATUALIZACAO DE ENTREGA*\n\nPedido ${pedido.numeroPedido} saiu para entrega.\nCliente: ${pedido.nomeCliente}\nTelefone: ${pedido.telefoneCliente}\nTotal: R\$ ${pedido.total.toStringAsFixed(2).replaceAll('.', ',')}\n\nStatus logístico atualizado para DESPACHADO.';
  }

  Future<bool> _enviarMensagemIndividual({
    required String telefone,
    required String mensagem,
  }) async {
    try {
      await _abrirConversaWhatsApp(telefone: telefone, mensagem: mensagem);
      return true;
    } catch (e) {
      debugPrint('Falha ao abrir conversa do WhatsApp: $e');
      return false;
    }
  }

  Future<void> _reenviarResumoPedido(Pedido pedido, {required bool paraFabrica}) async {
    final enviado = await _enviarMensagemIndividual(
      telefone: paraFabrica ? whatsappLanchonete : _normalizarTelefoneWhatsApp(pedido.telefoneCliente),
      mensagem: paraFabrica ? _montarMensagemNovoPedidoFabrica(pedido) : _montarMensagemNovoPedidoCliente(pedido),
    );

    if (!enviado) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir a conversa para reenvio do pedido.'), backgroundColor: Colors.red));
      }
      return;
    }

    setState(() {
      if (paraFabrica) {
        pedido.notificacaoNovoPedidoFabrica = true;
      } else {
        pedido.notificacaoNovoPedidoCliente = true;
      }
    });
  }

  Future<void> _reenviarDespachoPedido(Pedido pedido, {required bool paraFabrica}) async {
    final enviado = await _enviarMensagemIndividual(
      telefone: paraFabrica ? whatsappLanchonete : _normalizarTelefoneWhatsApp(pedido.telefoneCliente),
      mensagem: paraFabrica ? _montarMensagemDespachoFabrica(pedido) : _montarMensagemDespachoCliente(pedido),
    );

    if (!enviado) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir a conversa para reenvio do despacho.'), backgroundColor: Colors.red));
      }
      return;
    }

    setState(() {
      if (paraFabrica) {
        pedido.notificacaoDespachoFabrica = true;
      } else {
        pedido.notificacaoDespachoCliente = true;
      }
    });
  }

  Widget _buildStatusNotificacao(String titulo, bool enviado) {
    final cor = enviado ? Colors.green : Colors.orange;
    final texto = enviado ? 'aberta' : 'pendente';

    return Row(
      children: [
        Icon(enviado ? Icons.check_circle : Icons.pending_actions, size: 16, color: cor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$titulo: $texto',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cor),
          ),
        ),
      ],
    );
  }

  int _totalNotificacoesEnviadas(Pedido pedido) {
    var total = 0;
    if (pedido.notificacaoNovoPedidoFabrica) total++;
    if (pedido.notificacaoNovoPedidoCliente) total++;
    if (pedido.notificacaoDespachoFabrica) total++;
    if (pedido.notificacaoDespachoCliente) total++;
    return total;
  }

  int _totalNotificacoesEsperadas(Pedido pedido) {
    return pedido.statusLogistico == 'DESPACHADO' || pedido.statusLogistico == 'ENTREGUE'
        ? 4
        : 2;
  }

  Widget _buildResumoWhatsapp(Pedido pedido) {
    final enviados = _totalNotificacoesEnviadas(pedido);
    final esperados = _totalNotificacoesEsperadas(pedido);
    final completo = enviados >= esperados;
    final cor = completo
        ? Colors.green
        : enviados == 0
            ? Colors.redAccent
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat, size: 14, color: cor),
          const SizedBox(width: 4),
          Text(
            'WA $enviados/$esperados',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cor),
          ),
        ],
      ),
    );
  }

  Future<void> _notificarDespachoAutomaticamente(Pedido pedido) async {
    if (pedido.notificacaoDespachoFabrica && pedido.notificacaoDespachoCliente) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Despacho já notificado anteriormente. Use a comanda para reenviar manualmente, se necessário.'),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
      return;
    }

    final enviarFabrica = !pedido.notificacaoDespachoFabrica;
    final enviarCliente = !pedido.notificacaoDespachoCliente;

    bool enviadoFabrica = pedido.notificacaoDespachoFabrica;
    bool enviadoCliente = pedido.notificacaoDespachoCliente;

    if (enviarFabrica) {
      enviadoFabrica = await _enviarMensagemIndividual(
        telefone: whatsappLanchonete,
        mensagem: _montarMensagemDespachoFabrica(pedido),
      );
      pedido.notificacaoDespachoFabrica = enviadoFabrica;
    }

    if (enviarFabrica && enviarCliente) {
      await Future.delayed(const Duration(milliseconds: 600));
    }

    if (enviarCliente) {
      enviadoCliente = await _enviarMensagemIndividual(
        telefone: _normalizarTelefoneWhatsApp(pedido.telefoneCliente),
        mensagem: _montarMensagemDespachoCliente(pedido),
      );
      pedido.notificacaoDespachoCliente = enviadoCliente;
    }

    if (!mounted) return;

    if (pedido.notificacaoDespachoFabrica && pedido.notificacaoDespachoCliente) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Despacho confirmado no WhatsApp para fábrica e cliente de ${pedido.nomeCliente}'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (enviadoFabrica || enviadoCliente) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Despacho atualizado parcialmente. O restante pode ser reenviado pela comanda.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir as notificações pendentes de despacho.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _solicitarAutorizacaoGerente() async { final loginCtrl = TextEditingController(); final senhaCtrl = TextEditingController(); bool autorizado = false; await showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(title: const Row(children: [Icon(Icons.security, color: Colors.red), SizedBox(width: 10), Text("Autorização de Gerente", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("O cancelamento de pedidos exige a assinatura de um Administrador."), const SizedBox(height: 15), TextField(controller: loginCtrl, inputFormatters: [UpperCaseTextFormatter()], decoration: const InputDecoration(labelText: "Usuário Admin", prefixIcon: Icon(Icons.person))), const SizedBox(height: 10), TextField(controller: senhaCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Senha", prefixIcon: Icon(Icons.lock)))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("VOLTAR")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { bool adminValido = listaUsuarios.any((u) => u.idUsuario == loginCtrl.text && u.senha == senhaCtrl.text && u.cargo == 'ADMIN'); if (adminValido) { autorizado = true; Navigator.pop(ctx); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Credenciais inválidas!"), backgroundColor: Colors.red)); } }, child: const Text("AUTORIZAR"))])); return autorizado; }
  void _verDetalhesPedido(Pedido pedido) { 
    bool isCancelado = pedido.statusLogistico == 'CANCELADO';
    Color corStatus = _obterCorLogistica(pedido.statusLogistico);
    
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (dialogContext, setDialogState) => AlertDialog(
      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Comanda: ${pedido.numeroPedido}", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.location_on, size: 14, color: pedido.tipoEntrega == 'ENTREGA' ? Colors.purple : Colors.teal),
            const SizedBox(width: 4),
            Chip(label: Text(pedido.tipoEntrega, style: const TextStyle(color: Colors.white, fontSize: 12)), 
              backgroundColor: pedido.tipoEntrega == 'ENTREGA' ? Colors.purple : Colors.teal, 
              padding: const EdgeInsets.symmetric(horizontal: 8)),
          ])
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: corStatus.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: corStatus, width: 2)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_obterIconeStatus(pedido.statusLogistico), size: 18, color: corStatus),
              const SizedBox(width: 6),
              Text(pedido.statusLogistico, style: TextStyle(fontWeight: FontWeight.bold, color: corStatus, fontSize: 12))
            ])
          )
        ])
      ]),
      content: SizedBox(width: 500, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        if (isCancelado) 
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red[100], border: Border.all(color: Colors.red, width: 2), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.warning_rounded, color: Colors.red, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Text("PEDIDO CANCELADO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[800], fontSize: 14)))
            ])
          ),
        if (isCancelado) const SizedBox(height: 10),
        Text("Cliente: ${pedido.nomeCliente} (${pedido.telefoneCliente})", style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        const Divider(), 
        const Text("ITENS DO PEDIDO:", style: TextStyle(fontWeight: FontWeight.bold)), 
        const SizedBox(height: 10), 
        ...pedido.itens.map((i) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("${i.quantidade}x ${i.produto.nome}"), Text("R\$ ${(i.produto.preco * i.quantidade).toStringAsFixed(2).replaceAll('.', ',')}")]))), 
        const Divider(), 
        if (pedido.tipoEntrega == 'ENTREGA') ...[
          Text("Endereço: ${pedido.enderecoCompleto}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)), 
          const SizedBox(height: 5), 
          Text("Taxa de Entrega: R\$ ${pedido.taxaEntrega.toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(color: Colors.grey, fontSize: 12)), 
          const Divider()
        ], 
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("TOTAL:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
          Text("R\$ ${pedido.total.toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green))
        ]), 
        const SizedBox(height: 15),
        Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Status de Operação:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            Text(pedido.statusLogistico, style: TextStyle(fontWeight: FontWeight.bold, color: corStatus, fontSize: 12))
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Status de Pagamento:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            Text(pedido.statusPagamento, style: TextStyle(fontWeight: FontWeight.bold, color: pedido.statusPagamento == 'PAGO' ? Colors.green : Colors.orange, fontSize: 12))
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Forma de Pagamento:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            Text(pedido.formaPagamento, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
          ]),
          if (pedido.formaPagamento == 'DINHEIRO' && pedido.trocoPara != null) ...[
            const SizedBox(height: 8),
            Text("Troco para: R\$ ${pedido.trocoPara!.toStringAsFixed(2).replaceAll('.', ',')} (Levar R\$ ${(pedido.trocoPara! - pedido.total).toStringAsFixed(2).replaceAll('.', ',')} de troco)", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11))
          ]
        ])),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade100)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Notificações WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            _buildStatusNotificacao('Novo pedido - fábrica', pedido.notificacaoNovoPedidoFabrica),
            const SizedBox(height: 6),
            _buildStatusNotificacao('Novo pedido - cliente', pedido.notificacaoNovoPedidoCliente),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await _reenviarResumoPedido(pedido, paraFabrica: true);
                    setDialogState(() {});
                  },
                  icon: const Icon(Icons.storefront, size: 18),
                  label: const Text('Reenviar fábrica'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _reenviarResumoPedido(pedido, paraFabrica: false);
                    setDialogState(() {});
                  },
                  icon: const Icon(Icons.person, size: 18),
                  label: const Text('Reenviar cliente'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusNotificacao(pedido.tipoEntrega == 'RETIRADA' ? 'Retirada - fábrica' : 'Despacho - fábrica', pedido.notificacaoDespachoFabrica),
            const SizedBox(height: 6),
            _buildStatusNotificacao(pedido.tipoEntrega == 'RETIRADA' ? 'Retirada - cliente' : 'Despacho - cliente', pedido.notificacaoDespachoCliente),
            const SizedBox(height: 10),
            if (pedido.statusLogistico == 'DESPACHADO' || pedido.statusLogistico == 'ENTREGUE')
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _reenviarDespachoPedido(pedido, paraFabrica: true);
                      setDialogState(() {});
                    },
                    icon: const Icon(Icons.local_shipping, size: 18),
                    label: Text(pedido.tipoEntrega == 'RETIRADA' ? 'Retirada fábrica' : 'Despacho fábrica'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _reenviarDespachoPedido(pedido, paraFabrica: false);
                      setDialogState(() {});
                    },
                    icon: Icon(pedido.tipoEntrega == 'RETIRADA' ? Icons.storefront : Icons.delivery_dining, size: 18),
                    label: Text(pedido.tipoEntrega == 'RETIRADA' ? 'Retirada cliente' : 'Despacho cliente'),
                  ),
                ],
              )
            else
              Text(
                pedido.tipoEntrega == 'RETIRADA'
                    ? 'As ações de retirada ficam disponíveis quando o pedido estiver pronto para retirada.'
                    : 'As ações de despacho ficam disponíveis quando o pedido sair para entrega.',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
          ]),
        )
      ]))), 
      actions: [
        TextButton.icon(icon: const Icon(Icons.print, color: Colors.grey), label: const Text("IMPRIMIR COMANDA", style: TextStyle(color: Colors.grey)), onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enviando comando..."), backgroundColor: Colors.blueAccent)); }), 
        ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text("FECHAR"))
      ]))); 
  }
  Widget _abaOperacao(List<Pedido> lista) {
    if (lista.isEmpty) {
      return const Center(
        child: Text(
          "Nenhum pedido na operação.",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final p = lista[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.numeroPedido,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            p.tipoEntrega == 'ENTREGA' ? Icons.moped : Icons.storefront,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            p.tipoEntrega,
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildResumoWhatsapp(p),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nomeCliente, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${p.itens.length} itens (R\$ ${p.total.toStringAsFixed(2).replaceAll('.', ',')})'),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: _obterCorLogistica(p.statusLogistico)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: p.statusLogistico,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: _obterCorLogistica(p.statusLogistico)),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _obterCorLogistica(p.statusLogistico),
                        ),
                        items: ['NOVO', 'PREPARANDO', 'DESPACHADO', 'ENTREGUE', 'CANCELADO']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (novoStatus) async {
                          final statusAnterior = p.statusLogistico;
                          final messenger = ScaffoldMessenger.of(context);

                          if (novoStatus == 'CANCELADO') {
                            final autorizado = await _solicitarAutorizacaoGerente();
                            if (!mounted) return;
                            if (!autorizado) return;

                            setState(() {
                              p.statusLogistico = novoStatus!;
                              p.statusPagamento = 'CANCELADO';
                            });

                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text("Cancelado com sucesso."),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (novoStatus == null) return;

                          setState(() => p.statusLogistico = novoStatus);

                          if (novoStatus == 'DESPACHADO' && statusAnterior != 'DESPACHADO') {
                            Future.delayed(const Duration(milliseconds: 500), () {
                              _notificarDespachoAutomaticamente(p);
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  tooltip: "Ver Comanda",
                  onPressed: () => _verDetalhesPedido(p),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _abaCaixa(List<Pedido> lista) {
    if (lista.isEmpty) {
      return const Center(
        child: Text(
          "Nenhum acerto pendente.",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final p = lista[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.numeroPedido,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        p.formaPagamento,
                        style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildResumoWhatsapp(p),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nomeCliente, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        'Total: R\$ ${p.total.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () => setState(() => p.statusPagamento = 'PAGO'),
                          icon: const Icon(Icons.check_circle),
                          label: const Text("PAGO"),
                        ),
                      ),
                      const SizedBox(width: 5),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: "Cancelar Pedido Financeiro",
                        onPressed: () async {
                          final autorizado = await _solicitarAutorizacaoGerente();
                          if (!mounted) return;
                          if (!autorizado) return;

                          setState(() {
                            p.statusLogistico = 'CANCELADO';
                            p.statusPagamento = 'CANCELADO';
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  tooltip: "Ver Comanda",
                  onPressed: () => _verDetalhesPedido(p),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _abaListagemFinal(List<Pedido> lista, {required bool isCancelado}) { if (lista.isEmpty) return Center(child: Text(isCancelado ? "Nenhum pedido cancelado." : "Nenhum pedido concluído.", style: const TextStyle(fontSize: 18, color: Colors.grey))); return ListView.builder(itemCount: lista.length, itemBuilder: (context, index) { final p = lista[index]; return Card(color: isCancelado ? Colors.red[50] : Colors.green[50], margin: const EdgeInsets.only(bottom: 15), child: ListTile(leading: Icon(isCancelado ? Icons.cancel : Icons.check_circle, color: isCancelado ? Colors.red : Colors.green, size: 30), title: Text("${p.numeroPedido} - ${p.nomeCliente}", style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text("Pagamento: ${p.formaPagamento} | Total: R\$ ${p.total.toStringAsFixed(2).replaceAll('.', ',')}"), const SizedBox(height: 6), _buildResumoWhatsapp(p)]), trailing: IconButton(icon: const Icon(Icons.visibility, color: Colors.blue), onPressed: () => _verDetalhesPedido(p)))); }); }
  @override Widget build(BuildContext context) {
    List<Pedido> opAtivas = listaPedidosGerais.where((p) => p.statusLogistico != 'ENTREGUE' && p.statusLogistico != 'CANCELADO').toList()..sort((a, b) => b.dataHora.compareTo(a.dataHora)); List<Pedido> aguardandoPagamento = listaPedidosGerais.where((p) => p.statusPagamento == 'AGUARDANDO' && p.statusLogistico != 'CANCELADO').toList()..sort((a, b) => b.dataHora.compareTo(a.dataHora)); List<Pedido> concluidos = listaPedidosGerais.where((p) => p.statusLogistico == 'ENTREGUE' && p.statusPagamento == 'PAGO').toList()..sort((a, b) => b.dataHora.compareTo(a.dataHora)); List<Pedido> cancelados = listaPedidosGerais.where((p) => p.statusLogistico == 'CANCELADO').toList()..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return DefaultTabController(length: 4, child: Padding(padding: const EdgeInsets.all(32.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Controle de Pedidos e Caixa", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 20), const TabBar(labelColor: corPrimaria, unselectedLabelColor: Colors.grey, indicatorColor: corPrimaria, isScrollable: true, tabs: [Tab(text: "1. COZINHA (Operação)"), Tab(text: "2. CAIXA (Pendentes)"), Tab(text: "3. CONCLUÍDOS (Sucesso)"), Tab(text: "4. CANCELADOS (Estornos)")]), const SizedBox(height: 20), Expanded(child: TabBarView(children: [_abaOperacao(opAtivas), _abaCaixa(aguardandoPagamento), _abaListagemFinal(concluidos, isCancelado: false), _abaListagemFinal(cancelados, isCancelado: true)]))])));
  }
}

// =============================================================================
// --- TELA DE CADASTRO DE PRODUTOS ---
// =============================================================================
class TelaGestaoProdutos extends StatefulWidget { const TelaGestaoProdutos({super.key}); @override State<TelaGestaoProdutos> createState() => _TelaGestaoProdutosState(); }
class _TelaGestaoProdutosState extends State<TelaGestaoProdutos> {
  final TextEditingController _buscaController = TextEditingController();
  String _categoriaFiltro = 'Todas';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  String _imagemPadraoCategoria(String categoria) {
    switch (categoria) {
      case 'Lanches':
        return 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=900&auto=format&fit=crop';
      case 'Porções':
        return 'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?q=80&w=900&auto=format&fit=crop';
      case 'Bebidas':
        return 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?q=80&w=900&auto=format&fit=crop';
      case 'Sobremesas':
        return 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?q=80&w=900&auto=format&fit=crop';
      default:
        return '';
    }
  }

  void _restaurarImagensAusentes() {
    var atualizados = 0;
    for (final produto in cardapio) {
      if (produto.imagemUrl.trim().isEmpty) {
        produto.imagemUrl = _imagemPadraoCategoria(produto.categoria);
        atualizados++;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          atualizados == 0
              ? 'Nenhum produto sem imagem para restaurar.'
              : '$atualizados produtos receberam imagem padrao da categoria.',
        ),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {});
  }

  bool _atendeFiltros(Produto p) {
    final busca = _buscaController.text.trim().toLowerCase();
    final categoriaOk = _categoriaFiltro == 'Todas' || p.categoria == _categoriaFiltro;
    final buscaOk = busca.isEmpty || p.nome.toLowerCase().contains(busca);
    return categoriaOk && buscaOk;
  }

  @override
  Widget build(BuildContext context) {
    final categorias = cardapio.map((p) => p.categoria).toSet().toList()..sort();
    final lista = cardapio.where(_atendeFiltros).toList();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cadastro de Produtos',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _restaurarImagensAusentes,
                    icon: const Icon(Icons.image),
                    label: const Text('RESTAURAR IMAGENS'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TelaCadastroProduto()),
                    ).then((_) => setState(() {})),
                    icon: const Icon(Icons.add),
                    label: const Text('NOVO PRODUTO'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _buscaController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Buscar produto',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _categoriaFiltro,
                    items: ['Todas', ...categorias]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _categoriaFiltro = v ?? 'Todas'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: lista.length,
              itemBuilder: (context, index) {
                final p = lista[index];
                final imagem = p.imagemUrl.trim().isEmpty
                    ? _imagemPadraoCategoria(p.categoria)
                    : p.imagemUrl.trim();

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: imagem.isEmpty
                            ? Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.fastfood, color: Colors.white),
                              )
                            : Image.network(
                                imagem,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.fastfood, color: Colors.white),
                                ),
                              ),
                      ),
                    ),
                    title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${p.categoria} | R\$ ${p.preco.toStringAsFixed(2).replaceAll('.', ',')} | Estoque: ${p.estoqueAtual}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TelaCadastroProduto(produtoOriginal: p)),
                      ).then((_) => setState(() {})),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TelaCadastroProduto extends StatefulWidget { final Produto? produtoOriginal; const TelaCadastroProduto({super.key, this.produtoOriginal}); @override State<TelaCadastroProduto> createState() => _TelaCadastroProdutoState(); }
class _TelaCadastroProdutoState extends State<TelaCadastroProduto> {
  final _chaveForm = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _descricao = TextEditingController();
  final _preco = TextEditingController();
  final _imagemUrl = TextEditingController();
  final _estoque = TextEditingController();
  String _categoria = 'Lanches';

  String _imagemPadraoCategoria(String categoria) {
    switch (categoria) {
      case 'Lanches':
        return 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=900&auto=format&fit=crop';
      case 'Porções':
        return 'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?q=80&w=900&auto=format&fit=crop';
      case 'Bebidas':
        return 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?q=80&w=900&auto=format&fit=crop';
      case 'Sobremesas':
        return 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?q=80&w=900&auto=format&fit=crop';
      default:
        return '';
    }
  }

  bool _urlImagemEhValida(String valor) {
    final url = valor.trim();
    if (url.isEmpty) return true;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final esquemaValido = uri.scheme == 'http' || uri.scheme == 'https';
    return esquemaValido && uri.host.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    if (widget.produtoOriginal != null) {
      final p = widget.produtoOriginal!;
      _nome.text = p.nome;
      _descricao.text = p.descricao;
      _preco.text = p.preco.toStringAsFixed(2).replaceAll('.', ',');
      _imagemUrl.text = p.imagemUrl;
      _categoria = p.categoria;
      _estoque.text = p.estoqueAtual.toString();
    } else {
      _estoque.text = '50';
      _imagemUrl.text = _imagemPadraoCategoria(_categoria);
    }
    _imagemUrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _preco.dispose();
    _imagemUrl.dispose();
    _estoque.dispose();
    super.dispose();
  }

  void _usarImagemPadraoCategoria() {
    _imagemUrl.text = _imagemPadraoCategoria(_categoria);
  }

  void _salvarProduto() {
    if (_chaveForm.currentState!.validate()) {
      final precoLimpo = double.tryParse(_preco.text.replaceAll(',', '.')) ?? 0.0;
      final estoqueLimpo = int.tryParse(_estoque.text) ?? 0;
      final imagemFinal = _imagemUrl.text.trim().isEmpty
          ? _imagemPadraoCategoria(_categoria)
          : _imagemUrl.text.trim();

      if (widget.produtoOriginal != null) {
        final p = widget.produtoOriginal!;
        p.nome = _nome.text;
        p.descricao = _descricao.text;
        p.preco = precoLimpo;
        p.categoria = _categoria;
        p.imagemUrl = imagemFinal;
        p.estoqueAtual = estoqueLimpo;
      } else {
        final novoID = 'PROD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
        cardapio.add(
          Produto(
            idProduto: novoID,
            nome: _nome.text,
            descricao: _descricao.text,
            preco: precoLimpo,
            categoria: _categoria,
            imagemUrl: imagemFinal,
            estoqueAtual: estoqueLimpo,
          ),
        );
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagemPreview = _imagemUrl.text.trim().isEmpty
        ? _imagemPadraoCategoria(_categoria)
        : _imagemUrl.text.trim();

    return Scaffold(
      appBar: AppBar(title: Text(widget.produtoOriginal != null ? 'Editar Produto' : 'Novo Produto')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _chaveForm,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dados do Produto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _nome,
                          autofocus: true,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Nome do Produto *', hintText: 'Ex: X-Salada'),
                          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          initialValue: _categoria,
                          decoration: const InputDecoration(labelText: 'Categoria'),
                          items: ['Lanches', 'Porções', 'Bebidas', 'Sobremesas']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setState(() => _categoria = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descricao,
                    maxLines: 3,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Descrição (Aparece no Cardápio) *', hintText: 'Ex: Pão, carne, queijo...'),
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _imagemUrl,
                              decoration: const InputDecoration(labelText: 'Link da Imagem (URL)', hintText: 'https://...'),
                              validator: (v) => _urlImagemEhValida(v ?? '')
                                  ? null
                                  : 'Informe uma URL válida (http/https)',
                              onFieldSubmitted: (_) => _salvarProduto(),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: _usarImagemPadraoCategoria,
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text('Usar imagem padrão da categoria'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _preco,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Preço de Venda (R\$) *', hintText: 'Ex: 25,00'),
                              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _estoque,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Estoque Inicial *', hintText: 'Ex: 50'),
                              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Preview da Imagem', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: imagemPreview.isEmpty
                          ? Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.fastfood, size: 48, color: Colors.white),
                            )
                          : Image.network(
                              imagemPreview,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.fastfood, size: 48, color: Colors.white),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.cancel),
                        label: const Text('CANCELAR'),
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        onPressed: _salvarProduto,
                        icon: const Icon(Icons.save),
                        label: const Text('SALVAR PRODUTO'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// --- NOSSOS FORMATADORES CUSTOMIZADOS ---
// =============================================================================

class PrimeiraLetraMaiusculaFormatter extends TextInputFormatter { 
  @override TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) { 
    if (n.text.isEmpty) return n; 
    String formatado = n.text.split(' ').map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1).toLowerCase()).join(' ');
    return TextEditingValue(text: formatado, selection: n.selection); 
  } 
}

class TelefoneInputFormatter extends TextInputFormatter { 
  @override TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) { 
    var t = n.text; if (t.length > 11) t = t.substring(0, 11); 
    var f = ''; for (int i = 0; i < t.length; i++) { if (i == 0) f += '('; if (i == 2) f += ') '; if (i == 7) f += '-'; f += t[i]; } 
    return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length)); 
  } 
}

class CepInputFormatter extends TextInputFormatter { 
  @override TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) { 
    var t = n.text; if (t.length > 8) t = t.substring(0, 8); 
    var f = ''; for (int i = 0; i < t.length; i++) { if (i == 5) f += '-'; f += t[i]; } 
    return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length)); 
  } 
}

class NumeroEnderecoFormatter extends TextInputFormatter { 
  @override TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) { 
    String t = n.text.toUpperCase(); if (t.isEmpty) return n; 
    if (RegExp(r'^[0-9]+$').hasMatch(t) || t == 'S' || t == 'SN') return TextEditingValue(text: t, selection: n.selection); 
    return o; 
  } 
}

class UpperCaseTextFormatter extends TextInputFormatter { 
  @override TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) { 
    return TextEditingValue(text: n.text.toUpperCase(), selection: n.selection); 
  } 
}