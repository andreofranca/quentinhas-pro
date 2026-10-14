import 'package:flutter/material.dart';
import 'services/gestao_produtos_service.dart';
import 'services/gestao_estoque_service.dart';
import 'services/gestao_usuarios_service.dart';
import 'services/pedido_service.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/dashboard_pedido_service.dart';
import 'package:lanchonete_controle/services/api_client.dart';
import 'constants.dart';
import 'formatters.dart';
import 'models/dominio.dart';
export 'models/dominio.dart';
import 'theme/app_theme.dart';

import 'screens/shell_principal.dart';
import 'services/whatsapp_service.dart';

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

  try {
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    }
  } catch (e) {
    debugPrint('Aviso: Inicializacao Supabase contornada: $e');
  }

  try {
    await ApiClient.instance.init();
  } catch (e) {
    debugPrint('Aviso: Inicializacao ApiClient contornada: $e');
  }

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


// --- 2. BANCOS DE DADOS TEMPORÁRIOS ---

// =============================================================================
// 🍔 CARDÁPIO GIGANTE RESTAURADO (COM ESTOQUE)
// =============================================================================

class AppLanchonete extends StatelessWidget {
  final WhatsAppService? whatsappService;

  const AppLanchonete({super.key, this.whatsappService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quentinhas Pro',
      theme: AppTheme.themeData,
      home: const TelaLogin(),
    );
  }
}

// =============================================================================
// --- MÓDULO DO CLIENTE ---
// =============================================================================
// =============================================================================
// --- MÓDULO ERP (ADMINISTRAÇÃO E GESTÃO) ---
// =============================================================================
class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});
  @override State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _controleLogin = TextEditingController(text: 'admin@quentinhas.com.br');
  final _controleSenha = TextEditingController(text: 'admin');
  bool _carregando = false;
  bool _ocultarSenha = true;

  void _tentarLogin() async {
    final email = _controleLogin.text.trim().toLowerCase();
    final senha = _controleSenha.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, preencha o e-mail e a senha."), backgroundColor: Colors.red)
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      final response = await ApiClient.instance.post('/api/auth/login', body: {
        'email': email,
        'senha': senha,
      });

      await ApiClient.instance.saveToken(response['token']);
      final userData = response['usuario'];

      Usuario user = Usuario(
        idUsuario: userData['id']?.toString() ?? '',
        senha: '',
        nomeCompleto: userData['nome'] ?? '',
        cargo: userData['role'] ?? 'ATENDENTE',
        cpf: '', telefone: '', email: userData['email'] ?? '',
        cep: '', logradouro: '', numero: '', complemento: '', bairro: '', cidade: '', uf: '',
        situacaoConta: true,
      );

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ShellPrincipal(usuarioLogado: user)));
    } catch (e) {
      if (!mounted) return;
      String erro = "Não foi possível conectar ao servidor (http://localhost:8080). Verifique se o backend está ativo.";
      if (e is ApiException) {
        if (e.statusCode == 401) {
          erro = "Credenciais inválidas. Verifique seu e-mail e senha e tente novamente.";
        } else if (e.statusCode == 400) {
          erro = e.message.isNotEmpty ? e.message : "Dados inválidos para autenticação.";
        } else if (e.statusCode == 403) {
          erro = "Acesso negado. Usuário sem permissão de acesso.";
        } else {
          erro = "Erro ao tentar conectar: ${e.statusCode} - ${e.message}";
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Center(
        child: SingleChildScrollView(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (MediaQuery.of(context).size.width > 800)
                Container(
                  width: 400,
                  constraints: const BoxConstraints(minHeight: 520),
                  decoration: const BoxDecoration(
                    color: corPrimaria,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restaurant, size: 52, color: Colors.white),
                      const SizedBox(height: 16),
                      const Text(
                        "Quentinhas Pro",
                        style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Gestão inteligente para o seu negócio de alimentação.",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      _buildDiferencial(Icons.receipt_long, "Pedidos rápidos"),
                      _buildDiferencial(Icons.inventory, "Controle de estoque"),
                      _buildDiferencial(Icons.kitchen, "Monitor de produção (KDS)"),
                      _buildDiferencial(Icons.point_of_sale, "Gestão de caixa"),
                    ],
                  ),
                ),
              Container(
                width: 400,
                constraints: const BoxConstraints(minHeight: 520),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: MediaQuery.of(context).size.width > 800 
                      ? const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16))
                      : BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))
                  ]
                ),
                padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (MediaQuery.of(context).size.width <= 800) ...[
                      const Icon(Icons.restaurant, size: 48, color: corPrimaria),
                      const SizedBox(height: 16),
                      const Text(
                        "Quentinhas Pro",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: corPrimaria, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const Text(
                      "Entrar no sistema",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _controleLogin, 
                      autofocus: true, 
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'E-mail', 
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      )
                    ), 
                    const SizedBox(height: 20),
                    TextField(
                      controller: _controleSenha, 
                      obscureText: _ocultarSenha, 
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _tentarLogin(), 
                      decoration: InputDecoration(
                        labelText: 'Senha', 
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_ocultarSenha ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      )
                    ), 
                    const SizedBox(height: 30),
                    SizedBox(
                      height: 50, 
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: corPrimaria,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                        onPressed: _carregando ? null : _tentarLogin, 
                        child: _carregando 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Text("Entrar no sistema", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                      )
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      icon: const Icon(Icons.vpn_key_outlined, size: 18, color: corPrimaria),
                      label: const Text(
                        "Preencher credenciais padrão (Admin)",
                        style: TextStyle(color: corPrimaria, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      onPressed: () {
                        setState(() {
                          _controleLogin.text = 'admin@quentinhas.com.br';
                          _controleSenha.text = 'admin';
                        });
                      },
                    ),
                  ]
                )
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiferencial(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 16))),
        ],
      ),
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
                ListTile(leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text("Sair do ERP", style: TextStyle(color: Colors.redAccent)), onTap: () async { await ApiClient.instance.clearToken(); if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TelaLogin())); })
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
  bool _fechandoCaixa = false;
  
  bool _isLoading = true;
  String? _erro;
  List<Pedido> _pedidosReais = [];
  final DashboardPedidoService _pedidoService = DashboardPedidoService();

  @override
  void initState() {
    _carregarDados();
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });
    try {
      final pedidos = await _pedidoService.obterPedidos();
      if (!mounted) return;
      setState(() {
        _pedidosReais = pedidos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _valorContadoController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  void _executarFechamento(double valorContado) async {
    setState(() => _fechandoCaixa = true);
    try {
      final res = await CaixaService().fecharCaixa(valorContado);
      if (!mounted) return;

      final faturamento = (res['faturamentoSistema'] as num).toDouble();
      final diferenca = (res['diferenca'] as num).toDouble();

      setState(() {
        _valorContadoController.clear();
        _observacaoController.clear();
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Caixa Fechado com Sucesso"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Faturamento sistema: R\$ ${faturamento.toStringAsFixed(2).replaceAll('.', ',')}"),
              Text("Valor contado: R\$ ${valorContado.toStringAsFixed(2).replaceAll('.', ',')}"),
              Text("Diferença: R\$ ${diferenca.toStringAsFixed(2).replaceAll('.', ',')}", style: TextStyle(color: diferenca < 0 ? Colors.red : (diferenca > 0 ? Colors.orange : Colors.green), fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text("Os dados foram salvos no servidor.", style: TextStyle(color: Colors.green)),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _fechandoCaixa = false);
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
    final aguardandoPgto = _pedidosReais.where((p) => p.statusPagamento == 'AGUARDANDO').length;
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

  Widget _buildAbaFechamento() {
    final valorContadoStr = _valorContadoController.text.trim().replaceAll(',', '.');
    final valorContado = double.tryParse(valorContadoStr) ?? -1.0;
    final inputValido = valorContado >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Fechamento de Caixa", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
        const SizedBox(height: 4),
        const Text("Informe o valor total contado na gaveta para encerrar o caixa.", style: TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Lançamento do Caixa", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 14),
            TextField(
              controller: _valorContadoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
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
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: inputValido ? Colors.green : Colors.grey, padding: const EdgeInsets.all(18)),
            icon: _fechandoCaixa ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.point_of_sale, size: 26),
            label: const Text("FECHAR CAIXA DO DIA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            onPressed: inputValido && !_fechandoCaixa ? () => _executarFechamento(valorContado) : null,
          ),
        ),
        const SizedBox(height: 8),
        if (!inputValido)
          const Text("Informe o valor contado para habilitar o fechamento.", style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
    }
    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text("Erro ao carregar relatórios: $_erro", style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _carregarDados,
              icon: const Icon(Icons.refresh),
              label: const Text("Tentar Novamente"),
            )
          ],
        ),
      );
    }

    final pagos = _pedidosReais.where((p) => p.statusPagamento == 'PAGO').toList();
    final cancelados = _pedidosReais.where((p) => p.statusLogistico == 'CANCELADO').toList();
    
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Fechamento & Relatórios", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.deepOrange),
                  tooltip: 'Atualizar Dados',
                  onPressed: _carregarDados,
                ),
                const SizedBox(width: 16),
                Text("Operador: ${widget.usuarioLogado.nomeCompleto}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
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
            _buildAbaFechamento(),
          ],
        ),
      ),
    ]);
  }
}

class TelaControleEstoqueRapido extends StatefulWidget { const TelaControleEstoqueRapido({super.key}); @override State<TelaControleEstoqueRapido> createState() => _TelaControleEstoqueRapidoState(); }
class _TelaControleEstoqueRapidoState extends State<TelaControleEstoqueRapido> {
  final TextEditingController _buscaController = TextEditingController();
  final _service = GestaoEstoqueService();
  String _filtroCategoria = 'Todas';
  bool _mostrarApenasAlertas = false;
  bool _simulacaoReajusteAtiva = false;
  double _reajustePercentual = 0;
  
  List<Produto> _estoque = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregarEstoque();
  }

  Future<void> _carregarEstoque() async {
    setState(() => _loading = true);
    try {
      final res = await _service.listarEstoque();
      setState(() {
        _estoque = res;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar estoque: $e')));
      }
    }
  }

  Future<void> _atualizar(Produto p, int novoAtual) async {
    try {
      await _service.atualizarEstoque(p.idProduto, novoAtual, p.estoqueMinimo);
      setState(() {
        p.estoqueAtual = novoAtual;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar estoque: $e')));
      }
    }
  }

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
    final categorias = _estoque.map((p) => p.categoria).toSet().toList()..sort();
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
                  onPressed: p.estoqueAtual <= 0 ? null : () => _atualizar(p, p.estoqueAtual - 1),
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
                  onPressed: () => _atualizar(p, p.estoqueAtual + 1),
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    final listaOrdenada = [..._estoque]..sort((a, b) => a.estoqueAtual.compareTo(b.estoqueAtual));
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

class TelaGestaoEquipe extends StatefulWidget { const TelaGestaoEquipe({super.key}); @override State<TelaGestaoEquipe> createState()=>_TelaGestaoEquipeState(); }
class _TelaGestaoEquipeState extends State<TelaGestaoEquipe> { final _service=GestaoUsuariosService(); late Future<List<UsuarioEquipe>> _usuarios; @override void initState(){super.initState();_usuarios=_service.listar();} void _recarregar()=>setState(()=>_usuarios=_service.listar()); @override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.all(32),child:Column(children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Equipe e Acessos (RH)',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),ElevatedButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const TelaCadastroUsuario())).then((_)=>_recarregar()),icon:const Icon(Icons.person_add),label:const Text('NOVO FUNCIONÁRIO'))]),const SizedBox(height:20),Expanded(child:FutureBuilder<List<UsuarioEquipe>>(future:_usuarios,builder:(c,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('Erro ao carregar equipe: ${s.error}'));final us=s.data??[];return ListView.builder(itemCount:us.length,itemBuilder:(c,i){final u=us[i];return ListTile(title:Text(u.nome),subtitle:Text('${u.email} | ${u.role}'),trailing:Row(mainAxisSize:MainAxisSize.min,children:[Switch(value:u.ativo,onChanged:(v)async{await _service.atualizar(u.id,{'nome':u.nome,'email':u.email,'role':u.role,'ativo':v});_recarregar();}),IconButton(icon:const Icon(Icons.edit),onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>TelaCadastroUsuario(usuario:u))).then((_)=>_recarregar()))]));});}))])); }
class TelaCadastroUsuario extends StatefulWidget { final UsuarioEquipe? usuario; const TelaCadastroUsuario({super.key,this.usuario}); @override State<TelaCadastroUsuario> createState()=>_TelaCadastroUsuarioState(); }
class _TelaCadastroUsuarioState extends State<TelaCadastroUsuario>{final _f=GlobalKey<FormState>();final _nome=TextEditingController(),_email=TextEditingController(),_senha=TextEditingController();String _role='ATENDENTE';@override void initState(){super.initState();final u=widget.usuario;if(u!=null){_nome.text=u.nome;_email.text=u.email;_role=u.role;}}Future<void> _salvar()async{if(!_f.currentState!.validate())return;final d={'nome':_nome.text,'email':_email.text,'role':_role,'ativo':widget.usuario?.ativo??true};if(_senha.text.isNotEmpty)d['senha']=_senha.text;if(widget.usuario==null){if(_senha.text.isEmpty)return;await GestaoUsuariosService().criar(d);}else{await GestaoUsuariosService().atualizar(widget.usuario!.id,d);}if(mounted)Navigator.pop(context);}@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.usuario==null?'Novo Funcionário':'Editar Funcionário')),body:Form(key:_f,child:Column(children:[TextFormField(controller:_nome,validator:(v)=>v!.isEmpty?'Obrigatório':null),TextFormField(controller:_email,validator:(v)=>v!.isEmpty?'Obrigatório':null),TextFormField(controller:_senha,obscureText:true,decoration:const InputDecoration(labelText:'Nova senha (opcional)'),validator:(v)=>widget.usuario==null&&v!.isEmpty?'Obrigatório':null),DropdownButton<String>(value:_role,items:['ADMIN','GERENTE','ATENDENTE','COZINHA','CAIXA'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>_role=v!)),ElevatedButton(onPressed:_salvar,child:const Text('SALVAR'))])));}

// =============================================================================
// --- TELA DE GESTÃO DE PEDIDOS ---
// =============================================================================
class TelaGestaoPedidos extends StatefulWidget { const TelaGestaoPedidos({super.key}); @override State<TelaGestaoPedidos> createState() => _TelaGestaoPedidosState(); }
class _TelaGestaoPedidosState extends State<TelaGestaoPedidos> {
  bool _isLoading = true;
  String? _erroLog;
  final DashboardPedidoService _dashboardService = DashboardPedidoService();
  final List<Pedido> _pedidos = [];

  @override
  void initState() {
    super.initState();
    _carregarPedidos();
  }

  Future<void> _carregarPedidos() async {
    setState(() {
      _isLoading = true;
      _erroLog = null;
    });
    try {
      final pedidosApi = await _dashboardService.obterPedidos();
      setState(() {
        _pedidos.clear();
        _pedidos.addAll(pedidosApi);
      });
    } catch (e) {
      setState(() {
        _erroLog = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _obterCorLogistica(String status) { switch (status) { case 'CONFIRMADO': return Colors.redAccent; case 'EM_PRODUCAO': return Colors.amber; case 'SAIU_ENTREGA': return Colors.blueAccent; case 'ENTREGUE': return Colors.green; case 'CANCELADO': return Colors.grey; default: return Colors.black; } }
  IconData _obterIconeStatus(String status) { switch (status) { case 'CONFIRMADO': return Icons.schedule; case 'EM_PRODUCAO': return Icons.local_fire_department; case 'SAIU_ENTREGA': return Icons.local_shipping; case 'ENTREGUE': return Icons.check_circle; case 'CANCELADO': return Icons.cancel; default: return Icons.help; } }

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
    return pedido.statusLogistico == 'SAIU_ENTREGA' || pedido.statusLogistico == 'ENTREGUE'
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

  Future<bool> _solicitarAutorizacaoGerente() async {
    final loginCtrl = TextEditingController();
    final senhaCtrl = TextEditingController();
    bool autorizado = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.security, color: Colors.red),
          SizedBox(width: 10),
          Text("Autorização de Gerente", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("O cancelamento de pedidos exige a assinatura de um Administrador ou Gerente."),
            const SizedBox(height: 15),
            TextField(
              controller: loginCtrl,
              inputFormatters: [UpperCaseTextFormatter()],
              decoration: const InputDecoration(labelText: "Usuário Admin", prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: senhaCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Senha", prefixIcon: Icon(Icons.lock)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("VOLTAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final usuario = await GestaoUsuariosService().autenticarAdmin(loginCtrl.text, senhaCtrl.text);
                if (usuario.role == 'ADMIN' || usuario.role == 'GERENTE') {
                  autorizado = true;
                  if (ctx.mounted) Navigator.pop(ctx);
                } else {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text("Credenciais inválidas!"), backgroundColor: Colors.red),
                    );
                  }
                }
              } catch (_) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text("Credenciais inválidas!"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("AUTORIZAR"),
          ),
        ],
      ),
    );

    return autorizado;
  }
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
            if (pedido.statusLogistico == 'SAIU_ENTREGA' || pedido.statusLogistico == 'ENTREGUE')
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
                        items: ['CONFIRMADO', 'EM_PRODUCAO', 'SAIU_ENTREGA', 'ENTREGUE', 'CANCELADO']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (novoStatus) async {
                          if (novoStatus == null) return;
                          final statusAnterior = p.statusLogistico;
                          final messenger = ScaffoldMessenger.of(context);

                          if (novoStatus == 'CANCELADO') {
                            final autorizado = await _solicitarAutorizacaoGerente();
                            if (!mounted) return;
                            if (!autorizado) return;
                          }

                          try {
                            setState(() { _isLoading = true; });
                            await _dashboardService.atualizarStatus(p.numeroPedido, novoStatus);
                            await _carregarPedidos();

                            if (novoStatus == 'CANCELADO') {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text("Cancelado com sucesso."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (novoStatus == 'SAIU_ENTREGA' && statusAnterior != 'SAIU_ENTREGA') {
                              Future.delayed(const Duration(milliseconds: 500), () {
                                _notificarDespachoAutomaticamente(p);
                              });
                            }
                          } catch (e) {
                            messenger.showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
                            setState(() { _isLoading = false; });
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erroLog != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 15),
            Text('Erro: $_erroLog', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 15),
            ElevatedButton(onPressed: _carregarPedidos, child: const Text('Tentar Novamente')),
          ],
        ),
      );
    }
    List<Pedido> opAtivas = _pedidos.where((p) => p.statusLogistico != 'ENTREGUE' && p.statusLogistico != 'CANCELADO').toList()..sort((a, b) => b.dataHora.compareTo(a.dataHora)); List<Pedido> aguardandoPagamento = _pedidos.where((p) => p.statusPagamento == 'AGUARDANDO' && p.statusLogistico != 'CANCELADO').toList()..sort((a, b) => b.dataHora.compareTo(a.dataHora)); List<Pedido> concluidos = _pedidos.where((p) => p.statusLogistico == 'ENTREGUE' && p.statusPagamento == 'PAGO').toList()..sort((a, b) => b.dataHora.compareTo(a.dataHora)); List<Pedido> cancelados = _pedidos.where((p) => p.statusLogistico == 'CANCELADO').toList()..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    return DefaultTabController(length: 4, child: Padding(padding: const EdgeInsets.all(32.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Controle de Pedidos e Caixa", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarPedidos)]), const SizedBox(height: 20), const TabBar(labelColor: corPrimaria, unselectedLabelColor: Colors.grey, indicatorColor: corPrimaria, isScrollable: true, tabs: [Tab(text: "1. COZINHA (Operação)"), Tab(text: "2. CAIXA (Pendentes)"), Tab(text: "3. CONCLUÍDOS (Sucesso)"), Tab(text: "4. CANCELADOS (Estornos)")]), const SizedBox(height: 20), Expanded(child: TabBarView(children: [_abaOperacao(opAtivas), _abaCaixa(aguardandoPagamento), _abaListagemFinal(concluidos, isCancelado: false), _abaListagemFinal(cancelados, isCancelado: true)]))])));
  }
}

// =============================================================================
// --- TELA DE CADASTRO DE PRODUTOS ---
// =============================================================================
class TelaGestaoProdutos extends StatefulWidget { const TelaGestaoProdutos({super.key}); @override State<TelaGestaoProdutos> createState() => _TelaGestaoProdutosState(); }
class _TelaGestaoProdutosState extends State<TelaGestaoProdutos> {
  final TextEditingController _buscaController = TextEditingController();
  String _categoriaFiltro = 'Todas';
  bool _isLoading = true;
  String? _erro;
  List<Produto> _produtos = [];
  final GestaoProdutosService _service = GestaoProdutosService();

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    setState(() { _isLoading = true; _erro = null; });
    try {
      final res = await _service.listarProdutos();
      if (mounted) {
        setState(() { _produtos = res; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _erro = e.toString(); _isLoading = false; });
      }
    }
  }



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
    for (final produto in _produtos) {
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
    final categorias = _produtos.map((p) => p.categoria).toSet().toList()..sort();
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_erro != null) return Center(child: Text(_erro!));
    final lista = _produtos.where(_atendeFiltros).toList();

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
                    ).then((_) => _carregarProdutos()),
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
                      ).then((_) => _carregarProdutos()),
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

  final GestaoProdutosService _service = GestaoProdutosService();
  bool _salvando = false;

  void _usarImagemPadraoCategoria() {
    _imagemUrl.text = _imagemPadraoCategoria(_categoria);
  }

  Future<void> _salvarProduto() async {
    if (_chaveForm.currentState!.validate()) {
      setState(() => _salvando = true);
      try {
        final precoLimpo = double.tryParse(_preco.text.replaceAll(',', '.')) ?? 0.0;
        final estoqueLimpo = int.tryParse(_estoque.text) ?? 0;
        final imagemFinal = _imagemUrl.text.trim().isEmpty
            ? _imagemPadraoCategoria(_categoria)
            : _imagemUrl.text.trim();

        final data = {
          'nome': _nome.text,
          'descricao': _descricao.text,
          'precoBase': precoLimpo,
          'categoria': _categoria,
          'imagemUrl': imagemFinal,
          'estoqueAtual': estoqueLimpo,
          'estoqueMinimo': 8,
          'ativo': true,
        };

        if (widget.produtoOriginal != null) {
          await _service.atualizarProduto(widget.produtoOriginal!.idProduto, data);
        } else {
          await _service.criarProduto(data);
        }
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
        }
      } finally {
        if (mounted) setState(() => _salvando = false);
      }
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
                        onPressed: _salvando ? null : _salvarProduto,
                        icon: _salvando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                        label: Text(_salvando ? 'SALVANDO...' : 'SALVAR PRODUTO'),
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




