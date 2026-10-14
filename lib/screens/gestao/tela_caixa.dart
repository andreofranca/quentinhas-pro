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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caixa aberto com sucesso!'), backgroundColor: Colors.green));
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao abrir caixa: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red));
    }
  }

  Future<void> _fecharCaixa() async {
    try {
      await _service.fecharCaixa(0.0);
      _verificarCaixa();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caixa fechado com sucesso!'), backgroundColor: Colors.green));
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao fechar caixa: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red));
    }
  }

  @override Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final bool isAberto = _caixaAbertoId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Gestão de Caixa', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isAberto ? AppTheme.success.withAlpha(26) : Colors.grey.withAlpha(26),
                      shape: BoxShape.circle
                    ),
                    child: Icon(isAberto ? Icons.point_of_sale : Icons.lock, size: 80, color: isAberto ? AppTheme.success : Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  Text('STATUS DO CAIXA', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text(isAberto ? 'ABERTO' : 'FECHADO', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: isAberto ? AppTheme.success : Colors.grey.shade700)),
                  const SizedBox(height: 40),
                  
                  if (isAberto) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Valores das vendas deste caixa estarão disponíveis no relatório de fechamento.', style: TextStyle(color: Colors.blue.shade800))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(icon: const Icon(Icons.lock_outline), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _fecharCaixa, label: const Text('FECHAR CAIXA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                  ] else ...[
                    SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(icon: const Icon(Icons.lock_open), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _abrirCaixa, label: const Text('ABRIR CAIXA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

