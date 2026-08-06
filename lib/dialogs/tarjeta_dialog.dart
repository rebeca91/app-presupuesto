import 'package:flutter/material.dart';

import '../models/tarjeta_credito.dart';

Future<TarjetaCredito?> showNuevaTarjetaDialog(BuildContext context) {
  final nombreController = TextEditingController();
  final limiteController = TextEditingController();
  final saldoController = TextEditingController();
  final diaCorteController = TextEditingController();
  final diaPagoController = TextEditingController();
  final saldoUltimoCorteController = TextEditingController();
  var recordatoriosActivos = true;
  var diasAnticipacionPago = 1;

  return showDialog<TarjetaCredito>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                    labelText: 'Saldo real actual',
                  ),
                ),

                TextField(
                  controller: saldoUltimoCorteController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Saldo ultimo corte',
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
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: recordatoriosActivos,
                  onChanged: (value) {
                    setDialogState(() => recordatoriosActivos = value ?? false);
                  },
                  title: const Text('Activar recordatorios automáticos'),
                  subtitle: const Text('Corte y pago a las 9:00 a. m.'),
                ),
                if (recordatoriosActivos)
                  DropdownButtonFormField<int>(
                    initialValue: diasAnticipacionPago,
                    decoration: const InputDecoration(
                      labelText: 'Recordar pago con anticipación',
                    ),
                    items: const [0, 1, 2, 3, 5, 7]
                        .map(
                          (dias) => DropdownMenuItem(
                            value: dias,
                            child: Text(
                              dias == 0
                                  ? 'El mismo día'
                                  : '$dias ${dias == 1 ? 'día' : 'días'} antes',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => diasAnticipacionPago = value);
                      }
                    },
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
                final saldoUltimoCorte =
                    double.tryParse(saldoUltimoCorteController.text) ?? 0;
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
                    saldoUltimoCorte: saldoUltimoCorte,
                    diaCorte: diaCorte,
                    diaPago: diaPago,
                    recordatoriosActivos: recordatoriosActivos,
                    diasAnticipacionPago: diasAnticipacionPago,
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
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

class PagoTarjetaResult {
  const PagoTarjetaResult({required this.monto, this.tarjetaPago});

  final double monto;
  final TarjetaCredito? tarjetaPago;
}

Future<PagoTarjetaResult?> showRegistrarPagoTarjetaDialog({
  required BuildContext context,
  required TarjetaCredito tarjeta,
  required List<TarjetaCredito> tarjetas,
}) {
  final montoSugerido = tarjeta.saldoUltimoCorte > 0
      ? tarjeta.saldoUltimoCorte
      : tarjeta.saldoActual;
  final montoController = TextEditingController(
    text: montoSugerido.toStringAsFixed(2),
  );

  final tarjetasDisponibles = tarjetas
      .where((tarjetaDisponible) => tarjetaDisponible != tarjeta)
      .toList();
  var metodoPagoSeleccionado = 'Efectivo';
  TarjetaCredito? tarjetaPagoSeleccionada = tarjetasDisponibles.isNotEmpty
      ? tarjetasDisponibles.first
      : null;

  return showDialog<PagoTarjetaResult>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Pagar ${tarjeta.nombre}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: montoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monto a pagar'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: metodoPagoSeleccionado,
                  decoration: const InputDecoration(labelText: 'Forma de pago'),
                  items: [
                    const DropdownMenuItem(
                      value: 'Efectivo',
                      child: Text('Efectivo'),
                    ),
                    if (tarjetasDisponibles.isNotEmpty)
                      const DropdownMenuItem(
                        value: 'Tarjeta',
                        child: Text('Otra tarjeta de credito'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => metodoPagoSeleccionado = value);
                  },
                ),
                if (metodoPagoSeleccionado == 'Tarjeta') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TarjetaCredito>(
                    initialValue: tarjetaPagoSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Tarjeta para pagar',
                    ),
                    items: tarjetasDisponibles
                        .map(
                          (tarjetaDisponible) => DropdownMenuItem(
                            value: tarjetaDisponible,
                            child: Text(tarjetaDisponible.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => tarjetaPagoSeleccionada = value);
                      }
                    },
                  ),
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

                if (monto == null ||
                    monto <= 0 ||
                    monto > tarjeta.saldoActual) {
                  return;
                }

                final tarjetaPago = metodoPagoSeleccionado == 'Tarjeta'
                    ? tarjetaPagoSeleccionada
                    : null;
                if (metodoPagoSeleccionado == 'Tarjeta' &&
                    (tarjetaPago == null ||
                        tarjetaPago.saldoActual + monto > tarjetaPago.limite)) {
                  return;
                }

                Navigator.pop(
                  context,
                  PagoTarjetaResult(monto: monto, tarjetaPago: tarjetaPago),
                );
              },
              child: const Text('Registrar pago'),
            ),
          ],
        ),
      );
    },
  );
}
