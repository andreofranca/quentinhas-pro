import 'package:flutter/material.dart';
import '../../services/gestao_cardapio_service.dart';

class TelaGestaoCardapio extends StatefulWidget {
  const TelaGestaoCardapio({super.key});

  @override
  State<TelaGestaoCardapio> createState() => _TelaGestaoCardapioState();
}

class _TelaGestaoCardapioState extends State<TelaGestaoCardapio> {
  final GestaoCardapioService _service = GestaoCardapioService();
  List<Map<String, dynamic>> _ofertas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarOfertas();
  }

  Future<void> _carregarOfertas() async {
    setState(() => _isLoading = true);
    try {
      final ofertas = await _service.listarOfertas();
      setState(() => _ofertas = ofertas);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _atualizarOferta(Map<String, dynamic> oferta, {double? preco, int? limite, bool? ativo}) async {
    try {
      final request = {
        'produtoId': oferta['produtoId'],
        'tamanho': oferta['tamanho'],
        'precoVigente': preco ?? oferta['precoVigente'],
        'limiteProducao': limite ?? oferta['limiteProducao'],
        'ativo': ativo ?? oferta['ativo'],
      };
      await _service.editarOferta(oferta['id'], request);
      await _carregarOfertas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oferta atualizada com sucesso.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  void _mostrarModalEdicao(Map<String, dynamic> oferta) {
    final precoCtrl = TextEditingController(text: oferta['precoVigente'].toString());
    final limiteCtrl = TextEditingController(text: oferta['limiteProducao']?.toString() ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar ${oferta['produtoNome']} - ${oferta['tamanho']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: precoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Preço Vigente'),
            ),
            TextField(
              controller: limiteCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Limite Produção (vazio = sem limite)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final limiteStr = limiteCtrl.text.trim();
              _atualizarOferta(
                oferta,
                preco: double.tryParse(precoCtrl.text),
                limite: limiteStr.isEmpty ? null : int.tryParse(limiteStr),
              );
            },
            child: const Text('SALVAR'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Cardápio'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarOfertas),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _ofertas.length,
              itemBuilder: (context, index) {
                final oferta = _ofertas[index];
                return ListTile(
                  title: Text('${oferta['produtoNome']} (${oferta['tamanho']})'),
                  subtitle: Text('Preço: R\$ ${oferta['precoVigente']} | Limite: ${oferta['limiteProducao'] ?? 'Sem limite'} | Reservado: ${oferta['reservadoAtual'] ?? 0}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: oferta['ativo'] == true,
                        onChanged: (val) => _atualizarOferta(oferta, ativo: val),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _mostrarModalEdicao(oferta),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
