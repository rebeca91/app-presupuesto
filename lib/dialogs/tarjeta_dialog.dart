import 'package:flutter/material.dart';

import '../models/tarjeta_credito.dart';

Future<TarjetaCredito?> showNuevaTarjetaDialog(BuildContext context) {
  final nombreController = TextEditingController();
  final limiteController = TextEditingController();
  final saldoController = TextEditingController();
  final diaCorteController = TextEditingController();
  final diaPagoController = TextEditingController();

  return showDialog<TarjetaCredito>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Nueva tarjeta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: limiteController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Limite'),
              ),
              TextField(
                controller: saldoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Saldo pendiente inicial',
                ),
              ),
              TextField(
                controller: diaCorteController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Dia de corte'),
              ),
              TextField(
                controller: diaPagoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Dia de pago'),
              ),
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
              final nombre = nombreController.text.trim();
              final limite = double.tryParse(limiteController.text);
              final saldoInicial = double.tryParse(saldoController.text) ?? 0;
              final diaCorte = int.tryParse(diaCorteController.text);
              final diaPago = int.tryParse(diaPagoController.text);

              if (nombre.isEmpty ||
                  limite == null ||
                  limite <= 0 ||
                  saldoInicial < 0 ||
                  saldoInicial > limite ||
                  diaCorte == null ||
                  diaPago == null ||
                  diaCorte < 1 ||
                  diaCorte > 31 ||
                  diaPago < 1 ||
                  diaPago > 31) {
                return;
              }

              Navigator.pop(
                context,
                TarjetaCredito(
                  nombre: nombre,
                  limite: limite,
                  saldoActual: saldoInicial,
                  diaCorte: diaCorte,
                  diaPago: diaPago,
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}

Future<double?> showAjustarSaldoTarjetaDialog({
  required BuildContext context,
  required TarjetaCredito tarjeta,
}) {
  final saldoController = TextEditingController(
    text: tarjeta.saldoActual.toStringAsFixed(2),
  );

  return showDialog<double>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Ajustar saldo de ${tarjeta.nombre}'),
        content: TextField(
          controller: saldoController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Saldo pendiente'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final nuevoSaldo = double.tryParse(saldoController.text);

              if (nuevoSaldo == null ||
                  nuevoSaldo < 0 ||
                  nuevoSaldo > tarjeta.limite) {
                return;
              }

              Navigator.pop(context, nuevoSaldo);
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}

Future<double?> showRegistrarPagoTarjetaDialog({
  required BuildContext context,
  required TarjetaCredito tarjeta,
}) {
  final montoController = TextEditingController(
    text: tarjeta.saldoActual.toStringAsFixed(2),
  );

  return showDialog<double>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Pagar ${tarjeta.nombre}'),
        content: TextField(
          controller: montoController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monto a pagar'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final monto = double.tryParse(montoController.text);

              if (monto == null || monto <= 0 || monto > tarjeta.saldoActual) {
                return;
              }

              Navigator.pop(context, monto);
            },
            child: const Text('Registrar pago'),
          ),
        ],
      );
    },
  );
}
