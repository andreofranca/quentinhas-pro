import 'package:flutter/material.dart';
import '../../services/pedido_service.dart';
import '../../theme/app_theme.dart';

class TelaCaixa extends StatefulWidget {
  const TelaCaixa({super.key});
  @override State<TelaCaixa> createState() => _TelaCaixaState();
}

class _TelaCaixaState extends State<TelaCaixa> {
  final CaixaService _service = CaixaService();
  bool _isLoading = true;
  String? _caixaAbertoId;

  @override void initState() {
    super.initState();
    _verificarCaixa();
  }

  Future<void> _verificarCaixa() async {
    setState(() => _isLoading = true);
    try {
      _caixaAbertoId = await _service.getCaixaAtivoId();
    } catch (e) {
      _caixaAbertoId = null;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _abrirCaixa() async {
    try {
      await _service.abrirCaixa(0.0); // Abriremos com saldo zero default por simplificação
      _verificarCaixa();
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ')));
    }
  }

  Future<void> _fecharCaixa() async {
    try {
      await _service.fecharCaixa(0.0);
      _verificarCaixa();
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ')));
    }
  }

    @override Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final bool isAberto = _caixaAbertoId != null;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isAberto ? Icons.point_of_sale : Icons.lock, size: 64, color: isAberto ? AppTheme.successColor : Colors.grey),
                const SizedBox(height: 24),
                Text('STATUS DO CAIXA', style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(isAberto ? 'ABERTO' : 'FECHADO', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isAberto ? AppTheme.successColor : Colors.grey)),
                const SizedBox(height: 32),
                
                if (isAberto) ...[
                  const Text('Valores das vendas deste caixa estarão disponíveis no relatório de fechamento.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 32),
                  SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 20)), onPressed: _fecharCaixa, child: const Text('FECHAR CAIXA', style: TextStyle(fontSize: 16)))),
                ] else ...[
                  SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor, padding: const EdgeInsets.symmetric(vertical: 20)), onPressed: _abrirCaixa, child: const Text('ABRIR CAIXA', style: TextStyle(fontSize: 16)))),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
