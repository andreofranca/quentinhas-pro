import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. State addition
state_target = """  bool _fechandoCaixa = false;

  @override
  void initState() {"""

state_new = """  bool _fechandoCaixa = false;
  
  bool _isLoading = true;
  String? _erro;
  List<Pedido> _pedidosReais = [];
  final DashboardPedidoService _pedidoService = DashboardPedidoService();

  @override
  void initState() {
    _carregarDados();"""

content = content.replace(state_target, state_new)

# Add _carregarDados
carregar_target = """  void initState() {
    _carregarDados();
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }"""

carregar_new = """  void initState() {
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
  }"""

content = content.replace(carregar_target, carregar_new)

# 2. Fix _buildAbaRelatorioSintetico inside TelaRelatoriosFinanceiros
content = content.replace(
    "final aguardandoPgto = listaPedidosGerais.where((p) => p.statusPagamento == 'AGUARDANDO').length;",
    "final aguardandoPgto = _pedidosReais.where((p) => p.statusPagamento == 'AGUARDANDO').length;"
)

# 3. Replace the specific build method of _TelaRelatoriosFinanceirosState
build_start_str = "  @override\n  Widget build(BuildContext context) {\n    final pagos = listaPedidosGerais"
idx_build = content.find(build_start_str)
if idx_build != -1:
    idx_end = content.find("    ]);\n  }", idx_build) + 11
    
    new_build = """  @override
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
  }"""
    content = content[:idx_build] + new_build + content[idx_end:]


# 4. Remove listaPedidosGerais entirely
content = content.replace("List<Pedido> listaPedidosGerais = [];\n", "")

# 5. Remove globals
content = content.replace("List<ItemCarrinho> carrinhoAtual = [];\n", "")

# 6. Remove Dead Code Safely using Regex class matcher
def remove_class(cls_name):
    global content
    match = re.search(r'class ' + cls_name + r' extends StatefulWidget \{.*?\n\}\n\n', content, re.DOTALL)
    if match:
        content = content.replace(match.group(0), "")
    
    match_state = re.search(r'class _' + cls_name + r'State extends State<' + cls_name + r'> \{.*?\n\}\n\n', content, re.DOTALL)
    if match_state:
        content = content.replace(match_state.group(0), "")

remove_class("TelaCardapioCliente")
remove_class("TelaCheckoutExpresso")
remove_class("PainelTesteCompleto")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
