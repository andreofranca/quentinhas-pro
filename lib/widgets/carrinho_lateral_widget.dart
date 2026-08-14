import 'package:flutter/material.dart';
import '../../models/models_quentinha.dart';
import '../../theme/app_theme.dart';

class CarrinhoLateralWidget extends StatelessWidget {
  final List<ItemCarrinhoQuentinha> itens;
  final Function(ItemCarrinhoQuentinha) onRemover;
  final Function(ItemCarrinhoQuentinha) onAdicionarQuantidade;
  final Function(ItemCarrinhoQuentinha) onReduzirQuantidade;
  final VoidCallback onFinalizar;

  const CarrinhoLateralWidget({
    super.key,
    required this.itens,
    required this.onRemover,
    required this.onAdicionarQuantidade,
    required this.onReduzirQuantidade,
    required this.onFinalizar,
  });

  double get total {
    return itens.fold(0, (sum, item) => sum + item.subtotal);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.backgroundLight,
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, color: AppTheme.textDark),
                const SizedBox(width: 8),
                Text(
                  'PEDIDO ATUAL',
                  style: AppTheme.themeData.textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${itens.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de Itens
          Expanded(
            child: itens.isEmpty
                ? const Center(
                    child: Text(
                      'O carrinho está vazio.\nAdicione pratos do cardápio.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: itens.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = itens[index];
                      return _CarrinhoItemTile(
                        item: item,
                        onAdd: () => onAdicionarQuantidade(item),
                        onRemove: () => onReduzirQuantidade(item),
                        onDelete: () => onRemover(item),
                      );
                    },
                  ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13), // ~0.05 opacity
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: AppTheme.themeData.textTheme.titleMedium),
                    Text(
                      'R\$ ${total.toStringAsFixed(2)}',
                      style: AppTheme.themeData.textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: itens.isEmpty ? null : onFinalizar,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: const Text('AVANÇAR PARA PAGAMENTO', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarrinhoItemTile extends StatelessWidget {
  final ItemCarrinhoQuentinha item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onDelete;

  const _CarrinhoItemTile({
    required this.item,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Quantidade Controls
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.backgroundLight),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: onAdd,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.add, size: 20, color: AppTheme.primaryColor),
                ),
              ),
              Text(
                '${item.quantidade}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              InkWell(
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    item.quantidade > 1 ? Icons.remove : Icons.delete_outline,
                    size: 20,
                    color: item.quantidade > 1 ? AppTheme.textDark : AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Detalhes do Produto
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.oferta.nome,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withAlpha(51), // ~0.2 opacity
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Tamanho ${item.tamanhoEscolhido.tamanho.nome}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Preço
        Text(
          'R\$ ${item.subtotal.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
