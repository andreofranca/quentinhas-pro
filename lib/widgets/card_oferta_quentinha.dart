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

  bool get _totalmenteEsgotado => oferta.estoqueAtual <= 0;
  bool get _poucasUnidades => oferta.estoqueAtual > 0 && oferta.estoqueAtual <= 5;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppTheme.radiusMd,
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        oferta.nome,
                        style: AppTheme.themeData.textTheme.titleMedium?.copyWith(
                          color: _totalmenteEsgotado ? AppTheme.textSecondary : AppTheme.textPrimary,
                          decoration: _totalmenteEsgotado ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        oferta.descricao,
                        style: AppTheme.themeData.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildEstoqueBadge(),
              ],
            ),
            const SizedBox(height: 16),
            const Spacer(),
            Row(
              children: oferta.tamanhos.map((tamanhoOpcao) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _BotaoTamanho(
                      opcao: tamanhoOpcao,
                      isEsgotadoGeral: _totalmenteEsgotado,
                      onPressed: (!_totalmenteEsgotado && tamanhoOpcao.disponivel)
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

  Widget _buildEstoqueBadge() {
    if (_totalmenteEsgotado) {
      return const _BadgeEstoque(label: 'Esgotado', color: AppTheme.error, icon: Icons.block);
    } else if (_poucasUnidades) {
      return const _BadgeEstoque(label: 'Poucas uni.', color: AppTheme.warning, icon: Icons.warning_amber_rounded);
    } else {
      return const _BadgeEstoque(label: 'Disponível', color: AppTheme.success, icon: Icons.check_circle_outline);
    }
  }
}

class _BadgeEstoque extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _BadgeEstoque({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // ~10%
        borderRadius: AppTheme.radiusSm,
        border: Border.all(color: color.withAlpha(77)), // ~30%
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BotaoTamanho extends StatelessWidget {
  final TamanhoOpcao opcao;
  final bool isEsgotadoGeral;
  final VoidCallback? onPressed;

  const _BotaoTamanho({
    required this.opcao,
    required this.isEsgotadoGeral,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAdicionar = opcao.tamanho.sigla == 'U';
    final bool disponivel = onPressed != null;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: disponivel ? AppTheme.surface : AppTheme.background,
        foregroundColor: disponivel ? AppTheme.primary : AppTheme.textSecondary,
        elevation: disponivel ? 2 : 0,
        side: BorderSide(
          color: disponivel ? AppTheme.primary : AppTheme.textSecondary.withAlpha(77),
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.radiusMd,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isAdicionar ? 'Adicionar' : opcao.tamanho.sigla,
            style: TextStyle(
              fontSize: isAdicionar ? 16 : 24, 
              fontWeight: FontWeight.w900
            ),
          ),
          const SizedBox(height: 2),
          Opacity(
            opacity: disponivel ? 1.0 : 0.4,
            child: Text(
              disponivel ? 'R\$ ${opcao.preco.toStringAsFixed(2).replaceAll('.', ',')}' : 'ESGOTADO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: disponivel ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
