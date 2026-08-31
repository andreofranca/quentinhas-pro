import re

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add state to _TelaRelatoriosFinanceirosState
state_add = """  bool _fechandoCaixa = false;
  
  bool _isLoading = true;
  String? _erro;
  List<Pedido> _pedidosReais = [];
  final DashboardPedidoService _pedidoService = DashboardPedidoService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarDados();
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

"""
content = re.sub(
    r'  bool _fechandoCaixa = false;\n\n  @override\n  void initState\(\) \{\n    super.initState\(\);\n    _tabController = TabController\(length: 3, vsync: this\);\n  \}',
    state_add,
    content
)

# 2. Fix `build` method in TelaRelatoriosFinanceiros
start_build = content.find("  @override\n  Widget build(BuildContext context) {")
end_build = content.find("    ]);\n  }", start_build)

old_build = content[start_build:end_build]

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
      ),"""

content = content.replace(old_build, new_build)

# 3. Fix aguardandoPgto inside _buildAbaRelatorioSintetico
content = content.replace(
    "final aguardandoPgto = listaPedidosGerais.where((p) => p.statusPagamento == 'AGUARDANDO').length;",
    "final aguardandoPgto = _pedidosReais.where((p) => p.statusPagamento == 'AGUARDANDO').length;"
)

# 4. Remove listaPedidosGerais
content = content.replace("List<Pedido> listaPedidosGerais = [];\n", "")

# 5. Remove unused globals from main.dart
content = content.replace("List<ItemCarrinho> carrinhoAtual = [];\n", "")

# 6. Remove Dead Screens
def remove_class(cls_name):
    global content
    match = re.search(r'class ' + cls_name + r' extends StatefulWidget \{.*?\n\}', content, re.DOTALL)
    if match:
        content = content.replace(match.group(0), "")
    
    match_state = re.search(r'class _' + cls_name + r'State extends State<' + cls_name + r'> \{.*?\n\}\n', content, re.DOTALL)
    if match_state:
        content = content.replace(match_state.group(0), "")

remove_class("TelaCardapioCliente")
remove_class("TelaCheckoutExpresso")
remove_class("PainelTesteCompleto")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
