import 'movimiento.dart';

/// Calcula el dinero que realmente ha salido en efectivo o de una cuenta.
///
/// Una compra con tarjeta ocupa presupuesto, pero el efectivo solo sale al
/// momento de pagar esa tarjeta. Por eso se toman únicamente los movimientos
/// registrados como `Efectivo`; ahí se incluyen tanto gastos directos como
/// pagos de tarjeta en efectivo.
class ResumenFinanciero {
  const ResumenFinanciero._();

  static double gastosEnEfectivo(Iterable<Movimiento> movimientos) {
    return movimientos
        .where((movimiento) => movimiento.metodoPago == 'Efectivo')
        .fold<double>(0, (total, movimiento) => total + movimiento.monto);
  }

  static double efectivoDisponible({
    required double ingresos,
    required double reservaMensual,
    required Iterable<Movimiento> movimientos,
  }) {
    return ingresos - gastosEnEfectivo(movimientos) - reservaMensual;
  }
}
