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
        width: 500,
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 620),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ADICIONAIS', style: AppTheme.themeData.textTheme.labelLarge),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context, <AdicionalQuentinha>[]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha os complementos para sua quentinha',
              style: AppTheme.themeData.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.adicionaisDisponiveis.length,
                itemBuilder: (context, index) {
                  final adicional = widget.adicionaisDisponiveis[index];
                  final isSelected = _selecionados.contains(adicional);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : AppTheme.border,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: AppTheme.radiusMd,
                      color: isSelected ? AppTheme.primary.withAlpha(13) : AppTheme.surface,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      title: Text(
                        adicional.nome,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '+ R\$ ${adicional.preco.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600),
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        activeColor: AppTheme.primary,
                        onChanged: (bool? checked) {
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
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total Adicionais', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      Text(
                        'R\$ ${_totalAdicionais.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, <AdicionalQuentinha>[]),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(context, _selecionados),
                  child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
