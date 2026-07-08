import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/budget_item.dart';

class GraficaGastos extends StatelessWidget {
  const GraficaGastos({super.key, required this.items});

  final List<BudgetItem> items;

  static const _colores = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    final gastos = items.where((item) => item.real > 0).toList();

    if (gastos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: gastos.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    return PieChartSectionData(
                      value: item.real,
                      title: '\$${item.real.toStringAsFixed(0)}',
                      color: _colores[index % _colores.length],
                      radius: 75,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...gastos.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _colores[index % _colores.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.categoria)),
                    Text('\$${item.real.toStringAsFixed(2)}'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
