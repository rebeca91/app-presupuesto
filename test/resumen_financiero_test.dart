import 'package:app_presupuesto/models/movimiento.dart';
import 'package:app_presupuesto/models/resumen_financiero.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el pago de una tarjeta en efectivo reduce el efectivo disponible', () {
    final movimientos = [
      Movimiento(
        categoria: 'Compra con tarjeta',
        monto: 120,
        fecha: DateTime(2026, 8, 1),
        metodoPago: 'Visa',
      ),
      Movimiento(
        categoria: 'Pago de Visa',
        monto: 120,
        fecha: DateTime(2026, 8, 6),
        metodoPago: 'Efectivo',
      ),
    ];

    expect(
      ResumenFinanciero.efectivoDisponible(
        ingresos: 1000,
        reservaMensual: 100,
        movimientos: movimientos,
      ),
      780,
    );
  });

  test('una compra con tarjeta no descuenta efectivo hasta pagarla', () {
    final movimientos = [
      Movimiento(
        categoria: 'Compra con tarjeta',
        monto: 120,
        fecha: DateTime(2026, 8, 1),
        metodoPago: 'Visa',
      ),
    ];

    expect(
      ResumenFinanciero.efectivoDisponible(
        ingresos: 1000,
        reservaMensual: 100,
        movimientos: movimientos,
      ),
      900,
    );
  });
}
