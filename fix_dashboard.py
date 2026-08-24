import re

with open('lib/screens/dashboard/tela_dashboard_quentinhas.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports
import_str = "import '../../services/catalogo_service.dart';\n"
if "catalogo_service" not in content:
    content = import_str + content

# 2. Add future to state
state_match = re.search(r'class _TelaDashboardQuentinhasState extends State<TelaDashboardQuentinhas> \{\n\s*// Estado Local: Carrinho\n\s*final List<ItemCarrinhoQuentinha> _carrinho = \[\];', content)

if state_match:
    future_decl = "\n  late Future<List<OfertaQuentinha>> _futureCatalogo;\n  final CatalogoService _catalogoService = CatalogoService();\n\n  @override\n  void initState() {\n    super.initState();\n    _futureCatalogo = _catalogoService.buscarCatalogo();\n  }\n"
    content = content[:state_match.end()] + future_decl + content[state_match.end():]

# 3. Wrap mockCardapioHoje rendering with FutureBuilder
# Find the start of "if (isDesktopOrTablet)"
start_idx = content.find('// Grid para desktop, Lista para mobile')
end_idx = content.find('],', start_idx) + 1  # end of children array inside ListView

replacement = """// Grid para desktop, Lista para mobile
                        FutureBuilder<List<OfertaQuentinha>>(
                          future: _futureCatalogo,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                            }
                            if (snapshot.hasError) {
                              return Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Erro ao carregar cardápio. \\n${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: Colors.red))));
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
                                  childAspectRatio: 1.5,
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
"""

content = content[:start_idx] + replacement + content[end_idx:]

with open('lib/screens/dashboard/tela_dashboard_quentinhas.dart', 'w', encoding='utf-8') as f:
    f.write(content)

