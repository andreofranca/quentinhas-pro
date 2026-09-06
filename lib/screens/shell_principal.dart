import 'package:flutter/material.dart';
import 'package:lanchonete_controle/theme/app_theme.dart';

import 'dashboard/tela_dashboard_quentinhas.dart';
import 'dashboard/tela_dashboard_real.dart';
import '../main.dart';
import '../models/dominio.dart';
import 'gestao/tela_kds.dart';
import 'gestao/tela_lista_pedidos.dart';
import 'gestao/tela_caixa.dart'; // To access legacy screens like TelaGestaoPedidos, etc
import 'gestao/tela_gestao_cardapio.dart';

class ShellPrincipal extends StatefulWidget {
  final Usuario usuarioLogado;
  
  const ShellPrincipal({super.key, required this.usuarioLogado});

  @override
  State<ShellPrincipal> createState() => _ShellPrincipalState();
}

class _ShellPrincipalState extends State<ShellPrincipal> {
  int _selectedIndex = 0;
  
  // Mapping of indices to Screens
  late List<Widget> _telas;

  @override
  void initState() {
    super.initState();
    _telas = [
      // 0: Novo Pedido (Dashboard Operacional atual - PDV)
      TelaDashboardQuentinhas(usuarioLogado: widget.usuarioLogado),
      // 1: Pedidos
      const TelaListaPedidos(), // We need to build this or reuse
      // 2: Cozinha / KDS
      const TelaKDS(),
      // 3: Cardápio
      const TelaGestaoCardapio(),
      // 4: Produtos
      const TelaGestaoProdutos(),
      // 5: Estoque
      const TelaControleEstoqueRapido(),
      // 6: Caixa
      const TelaCaixa(),
      // 7: Clientes
      const Center(child: Text('Clientes - Em Breve')),
      // 8: Equipe
      const TelaGestaoEquipe(),
      // 9: Dashboard Análises
      const TelaDashboardReal(),
      // 10: Relatórios
      TelaRelatoriosFinanceiros(usuarioLogado: widget.usuarioLogado),
      // 11: Configurações
      const Center(child: Text('Configurações - Em Breve')),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 800;
    
    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                if (!isDesktop)
                  AppBar(
                    title: const Text('QUENTINHAS PRO'),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                Expanded(
                  child: _telas[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: isDesktop ? null : Drawer(
        child: _buildSidebarContent(),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: AppTheme.primaryColor,
      child: _buildSidebarContent(),
    );
  }

  Widget _buildSidebarContent() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: AppTheme.primaryColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.restaurant, color: Colors.white, size: 40),
              const SizedBox(height: 10),
              const Text('QUENTINHAS PRO', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(widget.usuarioLogado.nomeCompleto, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
        _buildSectionHeader('OPERAÇÃO'),
        _buildMenuItem(0, Icons.point_of_sale, 'Novo Pedido (PDV)'),
        _buildMenuItem(1, Icons.receipt_long, 'Pedidos'),
        _buildMenuItem(2, Icons.kitchen, 'Cozinha / KDS'),
        
        _buildSectionHeader('VENDAS'),
        _buildMenuItem(3, Icons.menu_book, 'Cardápio'),
        _buildMenuItem(4, Icons.fastfood, 'Produtos'),
        
        _buildSectionHeader('GESTÃO'),
        _buildMenuItem(5, Icons.inventory, 'Estoque'),
        _buildMenuItem(6, Icons.attach_money, 'Caixa'),
        _buildMenuItem(7, Icons.people, 'Clientes'),
        _buildMenuItem(8, Icons.badge, 'Equipe'),
        
        _buildSectionHeader('ANÁLISES'),
        _buildMenuItem(9, Icons.dashboard, 'Dashboard'),
        _buildMenuItem(10, Icons.bar_chart, 'Relatórios'),
        
        _buildSectionHeader('CONFIGURAÇÕES'),
        _buildMenuItem(11, Icons.settings, 'Configurações'),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.black12,
      onTap: () {
        _onItemTapped(index);
        if (MediaQuery.of(context).size.width < 800 && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
    );
  }
}
