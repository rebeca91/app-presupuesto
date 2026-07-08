import 'package:flutter/material.dart';

import '../models/budget_item.dart';

class CategoriaDialogResult {
  const CategoriaDialogResult({
    required this.nombre,
    required this.presupuesto,
  });

  final String nombre;
  final double presupuesto;
}

Future<CategoriaDialogResult?> showCategoriaDialog({
  required BuildContext context,
  BudgetItem? item,
  required bool Function(String nombre) esNombreReservado,
}) {
  final nombreController = TextEditingController(text: item?.categoria ?? '');
  final montoController = TextEditingController(
    text: item?.presupuesto.toStringAsFixed(2) ?? '',
  );

  return showDialog<CategoriaDialogResult>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(item == null ? 'Nueva categoría' : 'Editar categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: montoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Presupuesto'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final nombre = nombreController.text.trim();
              final monto = double.tryParse(montoController.text);

              if (nombre.isEmpty || monto == null) return;
              if (esNombreReservado(nombre)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Ese nombre se usa para la reserva mensual. Usa otro nombre para la categoria.',
                    ),
                  ),
                );
                return;
              }

              Navigator.pop(
                context,
                CategoriaDialogResult(nombre: nombre, presupuesto: monto),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}
