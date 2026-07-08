import 'package:flutter/material.dart';

import '../models/budget_item.dart';

class CategoriaCard extends StatelessWidget {
  const CategoriaCard({
    super.key,
    required this.item,
    required this.onEditar,
    required this.onEliminar,
  });

  final BudgetItem item;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.categoria,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '\$${item.real.toStringAsFixed(2)} / \$${item.presupuesto.toStringAsFixed(2)}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: item.presupuesto <= 0
                  ? 0
                  : (item.real / item.presupuesto).clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Restante: \$${(item.presupuesto - item.real).toStringAsFixed(2)}',
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: onEditar,
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: onEliminar,
                      icon: const Icon(Icons.delete),
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
