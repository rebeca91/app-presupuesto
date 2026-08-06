import 'package:flutter/material.dart';

import '../models/tarjeta_credito.dart';

class TarjetaCard extends StatelessWidget {
  const TarjetaCard({
    super.key,
    required this.tarjeta,
    required this.onAjustarSaldo,
    required this.onGenerarCorte,
    required this.onPagar,
    required this.onEliminar,
  });

  final TarjetaCredito tarjeta;
  final VoidCallback onAjustarSaldo;
  final VoidCallback onGenerarCorte;
  final VoidCallback onPagar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
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
                    tarjeta.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '\$${tarjeta.saldoActual.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: tarjeta.limite <= 0
                  ? 0
                  : (tarjeta.saldoActual / tarjeta.limite).clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 12),
            Text(
              'Credito disponible: \$${tarjeta.creditoDisponible.toStringAsFixed(2)} de \$${tarjeta.limite.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 4),
            Text('Saldo actual: \$${tarjeta.saldoActual.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            Text(
              'Saldo ultimo corte: \$${tarjeta.saldoUltimoCorte.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 4),
            Text('Consumo nuevo: \$${tarjeta.consumoNuevo.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            Text(
              'Corte: dia ${tarjeta.diaCorte}  Pago: dia ${tarjeta.diaPago}',
            ),
            const SizedBox(height: 8),
            Text(
              tarjeta.recordatoriosActivos
                  ? 'Recordatorio de pago: ${tarjeta.diasAnticipacionPago == 0 ? 'el mismo día' : '${tarjeta.diasAnticipacionPago} ${tarjeta.diasAnticipacionPago == 1 ? 'día' : 'días'} antes'} · 9:00 a. m.'
                  : 'Recordatorios desactivados',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: onAjustarSaldo,
                  child: const Text('Ajustar saldo'),
                ),
                TextButton(
                  onPressed: onGenerarCorte,
                  child: const Text('Generar corte'),
                ),
                TextButton(onPressed: onPagar, child: const Text('Pagar')),
                IconButton(
                  onPressed: onEliminar,
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
