import 'package:flutter/material.dart';
import '../models/models_quentinha.dart';
import '../theme/app_theme.dart';

class DialogAdicionaisWidget extends StatefulWidget {
  final List<AdicionalQuentinha> adicionaisDisponiveis;
  
  const DialogAdicionaisWidget({
    super.key,
    required this.adicionaisDisponiveis,
  });

  @override
  State<DialogAdicionaisWidget> createState() => _DialogAdicionaisWidgetState();
}

class _DialogAdicionaisWidgetState extends State<DialogAdicionaisWidget> {
  final List<AdicionalQuentinha> _selecionados = [];

  double get _totalAdicionais => _selecionados.fold(0, (sum, ad) => sum + ad.preco);

  @override
  Widget build(BuildContext context) {
    if (widget.adicionaisDisponiveis.isEmpty) {
      return AlertDialog(
        title: const Text('Adicionais'),
        content: const Text('Nenhum adicional disponível para este produto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, <AdicionalQuentinha>[]),
            child: const Text('OK'),
          )
        ],
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ADICIONAIS', style: AppTheme.themeData.textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              'Escolha os complementos para sua quentinha',
              style: AppTheme.themeData.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.adicionaisDisponiveis.length,
                itemBuilder: (context, index) {
                  final adicional = widget.adicionaisDisponiveis[index];
                  final isSelected = _selecionados.contains(adicional);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : AppTheme.border,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: AppTheme.radiusMd,
                      color: isSelected ? AppTheme.primary.withAlpha(13) : AppTheme.surface,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        adicional.nome,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '+ R\$ ',
                        style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          isSelected ? Icons.check_circle : Icons.add_circle_outline,
                          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            if (isSelected) {
                              _selecionados.remove(adicional);
                            } else {
                              _selecionados.add(adicional);
                            }
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selecionados.remove(adicional);
                          } else {
                            _selecionados.add(adicional);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Adicionais', style: TextStyle(color: AppTheme.textSecondary)),
                    Text(
                      'R\$ ',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, <AdicionalQuentinha>[]),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, _selecionados),
                      child: const Text('Adicionar'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
