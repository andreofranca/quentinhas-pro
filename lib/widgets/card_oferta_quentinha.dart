import 'package:flutter/material.dart';
import '../../models/models_quentinha.dart';
import '../../theme/app_theme.dart';

class CardOfertaQuentinha extends StatelessWidget {
  final OfertaQuentinha oferta;
  final Function(TamanhoOpcao) onAdicionar;

  const CardOfertaQuentinha({
    super.key,
    required this.oferta,
    required this.onAdicionar,
  });

  bool get _totalmenteEsgotado {
    return oferta.tamanhos.every((t) => !t.disponivel);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _totalmenteEsgotado ? AppTheme.textMuted : AppTheme.primaryColor,
              width: 6,
            ),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    oferta.nome,
                    style: AppTheme.themeData.textTheme.titleMedium?.copyWith(
                      color: _totalmenteEsgotado ? AppTheme.textMuted : AppTheme.textDark,
                      decoration: _totalmenteEsgotado ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (_totalmenteEsgotado)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withAlpha(26), // ~0.1 opacity
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ESGOTADO',
                      style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              oferta.descricao,
              style: AppTheme.themeData.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: oferta.tamanhos.map((tamanhoOpcao) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _BotaoTamanho(
                      opcao: tamanhoOpcao,
                      onPressed: tamanhoOpcao.disponivel
                          ? () => onAdicionar(tamanhoOpcao)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotaoTamanho extends StatelessWidget {
  final TamanhoOpcao opcao;
  final VoidCallback? onPressed;

  const _BotaoTamanho({
    required this.opcao,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool disponivel = onPressed != null;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: disponivel ? AppTheme.cardColor : AppTheme.backgroundLight,
        foregroundColor: disponivel ? AppTheme.primaryColor : AppTheme.textMuted,
        elevation: disponivel ? 2 : 0,
        side: BorderSide(
          color: disponivel ? AppTheme.primaryColor : AppTheme.textMuted.withAlpha(77), // ~0.3 opacity
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            opcao.tamanho.sigla,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            disponivel ? 'R\$ ${opcao.preco.toStringAsFixed(2)}' : 'Esgotado',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: disponivel ? AppTheme.textDark : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
