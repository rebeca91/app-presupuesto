import 'package:flutter/material.dart';

import '../models/budget_item.dart';
import '../models/tarjeta_credito.dart';

class GastoDialogResult {
  const GastoDialogResult({
    required this.categoria,
    required this.monto,
    this.tarjeta,
  });

  final BudgetItem categoria;
  final double monto;
  final TarjetaCredito? tarjeta;

  String get metodoPago => tarjeta?.nombre ?? 'Efectivo';
}

Future<GastoDialogResult?> showGastoDialog({
  required BuildContext context,
  required List<BudgetItem> categorias,
  required List<TarjetaCredito> tarjetas,
  bool permitirTarjeta = true,
}) {
  final montoController = TextEditingController();
  BudgetItem categoriaSeleccionada = categorias.first;
  String metodoPagoSeleccionado = 'Efectivo';
  TarjetaCredito? tarjetaSeleccionada = tarjetas.isNotEmpty
      ? tarjetas.first
      : null;

  return showDialog<GastoDialogResult>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Agregar gasto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<BudgetItem>(
                    initialValue: categoriaSeleccionada,
                    items: categorias.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item.categoria),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        categoriaSeleccionada = value;
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Categoria'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: montoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Monto'),
                  ),
                  if (permitirTarjeta) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: metodoPagoSeleccionado,
                      items: const [
                        DropdownMenuItem(
                          value: 'Efectivo',
                          child: Text('Efectivo'),
                        ),
                        DropdownMenuItem(
                          value: 'Tarjeta',
                          child: Text('Tarjeta de credito'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          metodoPagoSeleccionado = value;
                          if (metodoPagoSeleccionado == 'Tarjeta' &&
                              tarjetas.isNotEmpty) {
                            tarjetaSeleccionada ??= tarjetas.first;
                          }
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Metodo de pago',
                      ),
                    ),
                    if (metodoPagoSeleccionado == 'Tarjeta') ...[
                      const SizedBox(height: 12),
                      if (tarjetas.isEmpty)
                        const Text(
                          'Agrega una tarjeta antes de registrar compras con credito.',
                          style: TextStyle(color: Colors.white70),
                        )
                      else
                        DropdownButtonFormField<TarjetaCredito>(
                          initialValue: tarjetaSeleccionada,
                          items: tarjetas.map((tarjeta) {
                            return DropdownMenuItem(
                              value: tarjeta,
                              child: Text(tarjeta.nombre),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                tarjetaSeleccionada = value;
                              });
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Tarjeta',
                          ),
                        ),
                    ],
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final monto = double.tryParse(montoController.text);

                  if (monto == null || monto <= 0) {
                    return;
                  }

                  TarjetaCredito? tarjeta;
                  if (permitirTarjeta && metodoPagoSeleccionado == 'Tarjeta') {
                    tarjeta = tarjetaSeleccionada;

                    if (tarjeta == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecciona una tarjeta valida.'),
                        ),
                      );
                      return;
                    }

                    if (tarjeta.saldoActual + monto > tarjeta.limite) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'La compra supera el limite de la tarjeta.',
                          ),
                        ),
                      );
                      return;
                    }
                  }

                  Navigator.pop(
                    context,
                    GastoDialogResult(
                      categoria: categoriaSeleccionada,
                      monto: monto,
                      tarjeta: tarjeta,
                    ),
                  );
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
}
