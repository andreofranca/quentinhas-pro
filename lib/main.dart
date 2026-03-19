import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';
import 'formatters.dart'; 

void main() => runApp(const AppLanchonete());

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
    this.statusPagamento = 'AGUARDANDO'
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

// --- 2. BANCOS DE DADOS TEMPORÁRIOS ---
List<Usuario> listaUsuarios = [
  Usuario(idUsuario: "ANDRE", senha: "123", nomeCompleto: "André Administrador", cargo: "ADMIN"),
  Usuario(idUsuario: "JOAO", senha: "123", nomeCompleto: "João Atendente", cargo: "FUNCIONARIO") 
];
List<ItemCarrinho> carrinhoAtual = [];
List<Pedido> listaPedidosGerais = []; 

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
      title: 'Lanchonete Pro',
      theme: ThemeData(
        useMaterial3: true, 
        primaryColor: corPrimaria, 
        scaffoldBackgroundColor: corFundoEsmaecido,
        appBarTheme: const AppBarTheme(backgroundColor: corPrimaria, foregroundColor: Colors.white),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: corPrimaria, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15))),
        inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(), floatingLabelBehavior: FloatingLabelBehavior.always),
      ),
      home: const TelaCardapioCliente(),
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
      
      String mensagemBase = "*NOVO PEDIDO: $numeroPedido*\n\n*Cliente:* ${_nome.text}\n*Contato:* ${_telefone.text}\n\n$cabecalhoLogistica\n*ITENS:*\n$textoItens\n\n---------------------------\n*SUBTOTAL:* R\$ ${subtotal.toStringAsFixed(2).replaceAll('.', ',')}\n*TOTAL A PAGAR: R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}*\n---------------------------\n\n$detalhesPagamento\n\n⏳ _Tempo estimado: 40 a 60 minutos._\nPor favor, confirmem o recebimento do pedido!";
      String msgCodificada = Uri.encodeComponent(mensagemBase); 
      Uri urlWhatsapp = Uri.parse("https://wa.me/$whatsappLanchonete?text=$msgCodificada");
      
      try { 
        await launchUrl(urlWhatsapp, mode: LaunchMode.externalApplication); 
      } catch (e) {
        debugPrint("WhatsApp bloqueado");
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
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text("Entrega"), value: 'ENTREGA', groupValue: _tipoEntrega, 
                                onChanged: (v) => setState(() => _tipoEntrega = v!),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text("Retirada na Loja"), value: 'RETIRADA', groupValue: _tipoEntrega, 
                                onChanged: (v) => setState(() => _tipoEntrega = v!),
                              ),
                            ),
                          ],
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
                                value: _formaPagamento, 
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
                                      title: const Text("Precisa de troco?"), activeColor: Colors.green, value: _precisaTroco, 
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
      case 0: return const TelaRelatoriosFinanceiros(); // NOVO: DASHBOARD
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

class TelaRelatoriosFinanceiros extends StatefulWidget { const TelaRelatoriosFinanceiros({super.key}); @override State<TelaRelatoriosFinanceiros> createState() => _TelaRelatoriosFinanceirosState(); }
class _TelaRelatoriosFinanceirosState extends State<TelaRelatoriosFinanceiros> {
  void _fecharCaixa() { showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Fechar Caixa do Dia?"), content: const Text("Esta ação arquiva todos os pedidos Concluídos e Cancelados."), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () { setState(() { listaPedidosGerais.removeWhere((p) => p.statusPagamento == 'PAGO' || p.statusLogistico == 'CANCELADO'); }); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Caixa Fechado!"), backgroundColor: Colors.green)); }, child: const Text("CONFIRMAR"))])); }
  @override Widget build(BuildContext context) {
    List<Pedido> pagos = listaPedidosGerais.where((p) => p.statusPagamento == 'PAGO').toList(); List<Pedido> cancelados = listaPedidosGerais.where((p) => p.statusLogistico == 'CANCELADO').toList();
    double faturamentoTotal = pagos.fold(0, (sum, item) => sum + item.total); double totalPix = pagos.where((p) => p.formaPagamento == 'PIX').fold(0, (sum, item) => sum + item.total); double totalDinheiro = pagos.where((p) => p.formaPagamento == 'DINHEIRO').fold(0, (sum, item) => sum + item.total); double totalCredito = pagos.where((p) => p.formaPagamento == 'CRÉDITO').fold(0, (sum, item) => sum + item.total); double totalDebito = pagos.where((p) => p.formaPagamento == 'DÉBITO').fold(0, (sum, item) => sum + item.total);
    return Padding(padding: const EdgeInsets.all(32.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Dashboard de Vendas", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepOrange)), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(20)), onPressed: _fecharCaixa, icon: const Icon(Icons.point_of_sale, size: 28), label: const Text("FECHAR CAIXA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))]), const SizedBox(height: 30), Row(children: [Expanded(child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: Row(children: [CircleAvatar(radius: 30, backgroundColor: Colors.green.withValues(alpha: 0.2), child: const Icon(Icons.monetization_on, size: 30, color: Colors.green)), const SizedBox(width: 20), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Faturamento Bruto", style: TextStyle(color: Colors.grey, fontSize: 16)), Text("R\$ ${faturamentoTotal.toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))])]))), const SizedBox(width: 20), Expanded(child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: Row(children: [CircleAvatar(radius: 30, backgroundColor: Colors.blue.withValues(alpha: 0.2), child: const Icon(Icons.check_circle, size: 30, color: Colors.blue)), const SizedBox(width: 20), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Pedidos Sucesso", style: TextStyle(color: Colors.grey, fontSize: 16)), Text("${pagos.length}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))])]))), const SizedBox(width: 20), Expanded(child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: Row(children: [CircleAvatar(radius: 30, backgroundColor: Colors.red.withValues(alpha: 0.2), child: const Icon(Icons.cancel, size: 30, color: Colors.red)), const SizedBox(width: 20), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Cancelamentos", style: TextStyle(color: Colors.grey, fontSize: 16)), Text("${cancelados.length}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))])]))) ]), const SizedBox(height: 30), const Text("Resumo por Forma de Pagamento", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)), const SizedBox(height: 15), Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: const Border(bottom: BorderSide(color: Colors.teal, width: 4))), child: Column(children: [const Text("PIX", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text("R\$ ${totalPix.toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(fontSize: 24, color: Colors.teal, fontWeight: FontWeight.bold))]))), const SizedBox(width: 15), Expanded(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: const Border(bottom: BorderSide(color: Colors.green, width: 4))), child: Column(children: [const Text("Dinheiro", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text("R\$ ${totalDinheiro.toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold))]))), const SizedBox(width: 15), Expanded(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: const Border(bottom: BorderSide(color: Colors.orange, width: 4))), child: Column(children: [const Text("Crédito", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text("R\$ ${totalCredito.toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(fontSize: 24, color: Colors.orange, fontWeight: FontWeight.bold))]))), const SizedBox(width: 15), Expanded(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: const Border(bottom: BorderSide(color: Colors.blue, width: 4))), child: Column(children: [const Text("Débito", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text("R\$ ${totalDebito.toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(fontSize: 24, color: Colors.blue, fontWeight: FontWeight.bold))])))]))]));
  }
}

class TelaControleEstoqueRapido extends StatefulWidget { const TelaControleEstoqueRapido({super.key}); @override State<TelaControleEstoqueRapido> createState() => _TelaControleEstoqueRapidoState(); }
class _TelaControleEstoqueRapidoState extends State<TelaControleEstoqueRapido> {

  // Determina o status visual de cada produto
  _StatusEstoque _getStatus(Produto p) {
    if (p.estoqueAtual == 0) return _StatusEstoque.esgotado;
    if (p.estoqueAtual <= p.estoqueMinimo) return _StatusEstoque.critico;
    return _StatusEstoque.saudavel;
  }

  Widget _buildHeader(List<Produto> lista) {
    final esgotados = lista.where((p) => _getStatus(p) == _StatusEstoque.esgotado).length;
    final criticos  = lista.where((p) => _getStatus(p) == _StatusEstoque.critico).length;
    final saudaveis = lista.where((p) => _getStatus(p) == _StatusEstoque.saudavel).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          const Icon(Icons.inventory_2, color: Colors.blueGrey, size: 28),
          const SizedBox(width: 16),
          const Text("Painel de Estoque", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          _buildChipResumo("Esgotados", esgotados, Colors.red, Icons.block),
          const SizedBox(width: 10),
          _buildChipResumo("Críticos", criticos, Colors.orange, Icons.warning_amber),
          const SizedBox(width: 10),
          _buildChipResumo("Saudáveis", saudaveis, Colors.green, Icons.check_circle_outline),
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
          borderRadius: BorderRadius.circular(12),
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
          leading: CircleAvatar(
            backgroundColor: Colors.blueGrey.withValues(alpha: 0.12),
            child: Icon(_getIconeCategoria(p.categoria), color: Colors.blueGrey),
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
            width: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: p.estoqueAtual <= 0 ? null : () => setState(() => p.estoqueAtual--),
                  icon: Icon(Icons.remove_circle, color: p.estoqueAtual <= 0 ? Colors.grey : Colors.red),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    "${p.estoqueAtual}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(listaOrdenada),
          Expanded(
            child: ListView.builder(
              itemCount: listaOrdenada.length,
              itemBuilder: (context, index) => _buildCardProduto(listaOrdenada[index]),
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
  @override Widget build(BuildContext context) { return Padding(padding: const EdgeInsets.all(32.0), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Equipe e Acessos (RH)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaCadastroUsuario())).then((_) => setState((){})), icon: const Icon(Icons.person_add), label: const Text("NOVO FUNCIONÁRIO"))]), const SizedBox(height: 20), Expanded(child: ListView.builder(itemCount: listaUsuarios.length, itemBuilder: (context, index) { final u = listaUsuarios[index]; return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: CircleAvatar(backgroundColor: u.situacaoConta ? Colors.blue : Colors.grey, child: const Icon(Icons.person, color: Colors.white)), title: Text(u.nomeCompleto, style: TextStyle(fontWeight: FontWeight.bold, decoration: u.situacaoConta ? null : TextDecoration.lineThrough)), subtitle: Text("Login: ${u.idUsuario} | Cargo: ${u.cargo}"), trailing: Row(mainAxisSize: MainAxisSize.min, children: [const Text("Ativo: ", style: TextStyle(color: Colors.grey)), Switch(value: u.situacaoConta, activeColor: Colors.green, onChanged: (bool valor) { if (u.idUsuario == 'ANDRE' && valor == false) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("O Admin Mestre não pode ser desativado!"), backgroundColor: Colors.red)); return; } setState(() => u.situacaoConta = valor); }), IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TelaCadastroUsuario(usuarioOriginal: u))).then((_) => setState((){})))]))); }))])); }
}

class TelaCadastroUsuario extends StatefulWidget { final Usuario? usuarioOriginal; const TelaCadastroUsuario({super.key, this.usuarioOriginal}); @override State<TelaCadastroUsuario> createState() => _TelaCadastroUsuarioState(); }
class _TelaCadastroUsuarioState extends State<TelaCadastroUsuario> {
  final _chaveForm = GlobalKey<FormState>(); final _idUsuario = TextEditingController(); final _nomeCompleto = TextEditingController(); final _senha = TextEditingController(); String _cargo = 'FUNCIONARIO';
  @override void initState() { super.initState(); if (widget.usuarioOriginal != null) { final u = widget.usuarioOriginal!; _idUsuario.text = u.idUsuario; _nomeCompleto.text = u.nomeCompleto; _senha.text = u.senha; _cargo = u.cargo; } }
  void _salvarUsuario() { if (_chaveForm.currentState!.validate()) { if (widget.usuarioOriginal != null) { Usuario u = widget.usuarioOriginal!; u.nomeCompleto = _nomeCompleto.text; u.senha = _senha.text; u.cargo = _cargo; } else { bool idJaExiste = listaUsuarios.any((u) => u.idUsuario == _idUsuario.text.toUpperCase()); if (idJaExiste) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Este Login já existe!"), backgroundColor: Colors.red)); return; } listaUsuarios.add(Usuario(idUsuario: _idUsuario.text.toUpperCase(), senha: _senha.text, nomeCompleto: _nomeCompleto.text, cargo: _cargo)); } Navigator.pop(context); } }
  @override Widget build(BuildContext context) { bool ehEdicao = widget.usuarioOriginal != null; return Scaffold(appBar: AppBar(title: Text(ehEdicao ? "Editar Funcionário" : "Novo Funcionário")), body: Center(child: Container(constraints: const BoxConstraints(maxWidth: 600), padding: const EdgeInsets.all(32), child: Form(key: _chaveForm, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Dados de Acesso", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)), const SizedBox(height: 15), TextFormField(controller: _nomeCompleto, autofocus: true, textInputAction: TextInputAction.next, inputFormatters: [PrimeiraLetraMaiusculaFormatter()], decoration: const InputDecoration(labelText: 'Nome Completo *', prefixIcon: Icon(Icons.badge)), validator: (v) => v!.isEmpty ? 'Obrigatório' : null), const SizedBox(height: 20), Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: TextFormField(controller: _idUsuario, enabled: !ehEdicao, inputFormatters: [UpperCaseTextFormatter()], decoration: const InputDecoration(labelText: 'Login (ID) *', hintText: 'Ex: MARCOS', prefixIcon: Icon(Icons.person)), validator: (v) => v!.isEmpty ? 'Obrigatório' : null)), const SizedBox(width: 15), Expanded(child: TextFormField(controller: _senha, obscureText: true, decoration: const InputDecoration(labelText: 'Senha Segura *', prefixIcon: Icon(Icons.lock)), validator: (v) => v!.isEmpty ? 'Obrigatório' : null))]), const SizedBox(height: 20), DropdownButtonFormField<String>(value: _cargo, decoration: const InputDecoration(labelText: 'Cargo / Permissão', prefixIcon: Icon(Icons.security)), items: ['ADMIN', 'FUNCIONARIO'].map((c) => DropdownMenuItem(value: c, child: Text(c == 'ADMIN' ? 'Administrador' : 'Atendente'))).toList(), onChanged: (v) => setState(() => _cargo = v!)), const SizedBox(height: 40), Row(mainAxisAlignment: MainAxisAlignment.end, children: [OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.cancel), label: const Text("CANCELAR")), const SizedBox(width: 15), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), onPressed: _salvarUsuario, icon: const Icon(Icons.save), label: const Text("SALVAR"))])])))))); }
}

// =============================================================================
// --- TELA DE GESTÃO DE PEDIDOS ---
// =============================================================================
class TelaGestaoPedidos extends StatefulWidget { const TelaGestaoPedidos({super.key}); @override State<TelaGestaoPedidos> createState() => _TelaGestaoPedidosState(); }
class _TelaGestaoPedidosState extends State<TelaGestaoPedidos> {
  Color _obterCorLogistica(String status) { switch (status) { case 'NOVO': return Colors.redAccent; case 'PREPARANDO': return Colors.amber; case 'DESPACHADO': return Colors.blueAccent; case 'ENTREGUE': return Colors.green; case 'CANCELADO': return Colors.grey; default: return Colors.black; } }
  IconData _obterIconeStatus(String status) { switch (status) { case 'NOVO': return Icons.schedule; case 'PREPARANDO': return Icons.local_fire_department; case 'DESPACHADO': return Icons.local_shipping; case 'ENTREGUE': return Icons.check_circle; case 'CANCELADO': return Icons.cancel; default: return Icons.help; } }

  Future<void> _enviarNotificacaoWhatsApp(Pedido pedido) async {
    try {
      String telefone = pedido.telefoneCliente.replaceAll(RegExp(r'[^\d]'), '');
      if (!telefone.startsWith('55')) { telefone = '55$telefone'; }
      String mensagem = 'Olá ${pedido.nomeCliente}! 🚚\n\nSeu pedido #${pedido.numeroPedido} saiu para entrega!\n\nTotal: R\$ ${pedido.total.toStringAsFixed(2).replaceAll('.', ',')}\n\nAcompanhe seu pedido e esteja pronto para receber. 😊';
      final Uri whatsappUri = Uri.parse('https://api.whatsapp.com/send?phone=$telefone&text=${Uri.encodeComponent(mensagem)}');
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        if(mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notificação WhatsApp enviada para ${pedido.nomeCliente}'), backgroundColor: Colors.green)); }
      } else {
        if(mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp não disponível.'), backgroundColor: Colors.orange)); }
      }
    } catch (e) {
      if(mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red)); }
    }
  }

  Future<bool> _solicitarAutorizacaoGerente() async { final loginCtrl = TextEditingController(); final senhaCtrl = TextEditingController(); bool autorizado = false; await showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(title: const Row(children: [Icon(Icons.security, color: Colors.red), SizedBox(width: 10), Text("Autorização de Gerente", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("O cancelamento de pedidos exige a assinatura de um Administrador."), const SizedBox(height: 15), TextField(controller: loginCtrl, inputFormatters: [UpperCaseTextFormatter()], decoration: const InputDecoration(labelText: "Usuário Admin", prefixIcon: Icon(Icons.person))), const SizedBox(height: 10), TextField(controller: senhaCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Senha", prefixIcon: Icon(Icons.lock)))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("VOLTAR")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { bool adminValido = listaUsuarios.any((u) => u.idUsuario == loginCtrl.text && u.senha == senhaCtrl.text && u.cargo == 'ADMIN'); if (adminValido) { autorizado = true; Navigator.pop(ctx); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Credenciais inválidas!"), backgroundColor: Colors.red)); } }, child: const Text("AUTORIZAR"))])); return autorizado; }
  void _verDetalhesPedido(Pedido pedido) { 
    bool isCancelado = pedido.statusLogistico == 'CANCELADO';
    Color corStatus = _obterCorLogistica(pedido.statusLogistico);
    
    showDialog(context: context, builder: (ctx) => AlertDialog(
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
        ]))
      ]))), 
      actions: [
        TextButton.icon(icon: const Icon(Icons.print, color: Colors.grey), label: const Text("IMPRIMIR COMANDA", style: TextStyle(color: Colors.grey)), onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enviando comando..."), backgroundColor: Colors.blueAccent)); }), 
        ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text("FECHAR"))
      ])); 
  }
  Widget _abaOperacao(List<Pedido> lista) { if (lista.isEmpty) return const Center(child: Text("Nenhum pedido na operação.", style: TextStyle(fontSize: 18, color: Colors.grey))); return ListView.builder(itemCount: lista.length, itemBuilder: (context, index) { final p = lista[index]; return Card(margin: const EdgeInsets.only(bottom: 15), child: Padding(padding: const EdgeInsets.all(16.0), child: Row(children: [Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.numeroPedido, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Row(children: [Icon(p.tipoEntrega == 'ENTREGA' ? Icons.moped : Icons.storefront, size: 16, color: Colors.grey), const SizedBox(width: 5), Text(p.tipoEntrega, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))])])), Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.nomeCliente, style: const TextStyle(fontWeight: FontWeight.bold)), Text("${p.itens.length} itens (R\$ ${p.total.toStringAsFixed(2).replaceAll('.', ',')})")])), Expanded(flex: 3, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(border: Border.all(color: _obterCorLogistica(p.statusLogistico)), borderRadius: BorderRadius.circular(8)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: p.statusLogistico, isExpanded: true, icon: Icon(Icons.arrow_drop_down, color: _obterCorLogistica(p.statusLogistico)), style: TextStyle(fontWeight: FontWeight.bold, color: _obterCorLogistica(p.statusLogistico)), items: ['NOVO', 'PREPARANDO', 'DESPACHADO', 'ENTREGUE', 'CANCELADO'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (novoStatus) async { if (novoStatus == 'CANCELADO') { bool autorizado = await _solicitarAutorizacaoGerente(); if (autorizado) { setState(() { p.statusLogistico = novoStatus!; p.statusPagamento = 'CANCELADO'; }); if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cancelado com sucesso."), backgroundColor: Colors.red)); } } else { setState(() => p.statusLogistico = novoStatus!); if (novoStatus == 'DESPACHADO') { Future.delayed(const Duration(milliseconds: 500), () { _enviarNotificacaoWhatsApp(p); }); } } })))), const SizedBox(width: 20), IconButton(icon: const Icon(Icons.visibility, color: Colors.blue), tooltip: "Ver Comanda", onPressed: () => _verDetalhesPedido(p))]))); }); }
  Widget _abaCaixa(List<Pedido> lista) { if (lista.isEmpty) return const Center(child: Text("Nenhum acerto pendente.", style: TextStyle(fontSize: 18, color: Colors.grey))); return ListView.builder(itemCount: lista.length, itemBuilder: (context, index) { final p = lista[index]; return Card(margin: const EdgeInsets.only(bottom: 15), child: Padding(padding: const EdgeInsets.all(16.0), child: Row(children: [Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.numeroPedido, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(p.formaPagamento, style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold))])), Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.nomeCliente, style: const TextStyle(fontWeight: FontWeight.bold)), Text("Total: R\$ ${p.total.toStringAsFixed(2).replaceAll('.', ',')}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))])), Expanded(flex: 3, child: Row(children: [Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () => setState(() => p.statusPagamento = 'PAGO'), icon: const Icon(Icons.check_circle), label: const Text("PAGO"))), const SizedBox(width: 5), IconButton(icon: const Icon(Icons.cancel, color: Colors.red), tooltip: "Cancelar Pedido Financeiro", onPressed: () async { bool autorizado = await _solicitarAutorizacaoGerente(); if (autorizado) { setState(() { p.statusLogistico = 'CANCELADO'; p.statusPagamento = 'CANCELADO'; }); } })])), const SizedBox(width: 20), IconButton(icon: const Icon(Icons.visibility, color: Colors.blue), tooltip: "Ver Comanda", onPressed: () => _verDetalhesPedido(p))]))); }); }
  Widget _abaListagemFinal(List<Pedido> lista, {required bool isCancelado}) { if (lista.isEmpty) return Center(child: Text(isCancelado ? "Nenhum pedido cancelado." : "Nenhum pedido concluído.", style: const TextStyle(fontSize: 18, color: Colors.grey))); return ListView.builder(itemCount: lista.length, itemBuilder: (context, index) { final p = lista[index]; return Card(color: isCancelado ? Colors.red[50] : Colors.green[50], margin: const EdgeInsets.only(bottom: 15), child: ListTile(leading: Icon(isCancelado ? Icons.cancel : Icons.check_circle, color: isCancelado ? Colors.red : Colors.green, size: 30), title: Text("${p.numeroPedido} - ${p.nomeCliente}", style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("Pagamento: ${p.formaPagamento} | Total: R\$ ${p.total.toStringAsFixed(2).replaceAll('.', ',')}"), trailing: IconButton(icon: const Icon(Icons.visibility, color: Colors.blue), onPressed: () => _verDetalhesPedido(p)))); }); }
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
  @override Widget build(BuildContext context) { return Padding(padding: const EdgeInsets.all(32.0), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Cadastro de Produtos", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaCadastroProduto())).then((_) => setState((){})), icon: const Icon(Icons.add), label: const Text("NOVO PRODUTO"))]), const SizedBox(height: 20), Expanded(child: ListView.builder(itemCount: cardapio.length, itemBuilder: (context, index) { final p = cardapio[index]; return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: CircleAvatar(backgroundImage: p.imagemUrl.isEmpty ? null : NetworkImage(p.imagemUrl), backgroundColor: Colors.grey[300], child: p.imagemUrl.isEmpty ? const Icon(Icons.fastfood, color: Colors.white) : null), title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("${p.categoria} | R\$ ${p.preco.toStringAsFixed(2).replaceAll('.', ',')}"), trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TelaCadastroProduto(produtoOriginal: p))).then((_) => setState((){}))))); }))])); }
}

class TelaCadastroProduto extends StatefulWidget { final Produto? produtoOriginal; const TelaCadastroProduto({super.key, this.produtoOriginal}); @override State<TelaCadastroProduto> createState() => _TelaCadastroProdutoState(); }
class _TelaCadastroProdutoState extends State<TelaCadastroProduto> {
  final _chaveForm = GlobalKey<FormState>(); final _nome = TextEditingController(); final _descricao = TextEditingController(); final _preco = TextEditingController(); final _imagemUrl = TextEditingController(); final _estoque = TextEditingController(); String _categoria = 'Lanches';
  @override void initState() { super.initState(); if (widget.produtoOriginal != null) { final p = widget.produtoOriginal!; _nome.text = p.nome; _descricao.text = p.descricao; _preco.text = p.preco.toStringAsFixed(2).replaceAll('.', ','); _imagemUrl.text = p.imagemUrl; _categoria = p.categoria; _estoque.text = p.estoqueAtual.toString(); } else { _estoque.text = "50"; } }
  void _salvarProduto() { if (_chaveForm.currentState!.validate()) { double precoLimpo = double.tryParse(_preco.text.replaceAll(',', '.')) ?? 0.0; int estoqueLimpo = int.tryParse(_estoque.text) ?? 0; if (widget.produtoOriginal != null) { Produto p = widget.produtoOriginal!; p.nome = _nome.text; p.descricao = _descricao.text; p.preco = precoLimpo; p.categoria = _categoria; p.imagemUrl = _imagemUrl.text; p.estoqueAtual = estoqueLimpo; } else { String novoID = "PROD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}"; cardapio.add(Produto(idProduto: novoID, nome: _nome.text, descricao: _descricao.text, preco: precoLimpo, categoria: _categoria, imagemUrl: _imagemUrl.text, estoqueAtual: estoqueLimpo)); } Navigator.pop(context); } }
  @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: Text(widget.produtoOriginal != null ? "Editar Produto" : "Novo Produto")), body: Center(child: Container(constraints: const BoxConstraints(maxWidth: 800), padding: const EdgeInsets.all(32), child: Form(key: _chaveForm, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Dados do Produto", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)), const SizedBox(height: 15), Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: TextFormField(controller: _nome, autofocus: true, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Nome do Produto *', hintText: 'Ex: X-Salada'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null)), const SizedBox(width: 15), Expanded(flex: 1, child: DropdownButtonFormField<String>(value: _categoria, decoration: const InputDecoration(labelText: 'Categoria'), items: ['Lanches', 'Porções', 'Bebidas', 'Sobremesas'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _categoria = v!)))]), const SizedBox(height: 20), TextFormField(controller: _descricao, maxLines: 3, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Descrição (Aparece no Cardápio) *', hintText: 'Ex: Pão, carne, queijo...'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null), const SizedBox(height: 20), Row(children: [Expanded(flex: 1, child: TextFormField(controller: _preco, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Preço de Venda (R\$) *', hintText: 'Ex: 25,00'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null)), const SizedBox(width: 15), Expanded(flex: 1, child: TextFormField(controller: _estoque, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Estoque Inicial *', hintText: 'Ex: 50'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null)), const SizedBox(width: 15), Expanded(flex: 3, child: TextFormField(controller: _imagemUrl, decoration: const InputDecoration(labelText: 'Link da Imagem (URL)', hintText: 'https://...'), onFieldSubmitted: (_) => _salvarProduto()))]), const SizedBox(height: 40), Row(mainAxisAlignment: MainAxisAlignment.end, children: [OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.cancel), label: const Text("CANCELAR")), const SizedBox(width: 15), ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), onPressed: _salvarProduto, icon: const Icon(Icons.save), label: const Text("SALVAR PRODUTO"))])])))))); }
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