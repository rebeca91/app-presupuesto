import 'budget_item.dart';
import 'ingreso.dart';
import 'movimiento.dart';
import 'resumen_mensual.dart';
import 'tarjeta_credito.dart';

class AppData {
  final List<BudgetItem> items;
  final List<Ingreso> ingresos;
  final List<TarjetaCredito> tarjetas;
  final List<ResumenMensual> historial;
  final List<Movimiento> movimientos;

  /// Distingue un primer inicio de una lista de categorías que el usuario
  /// decidió dejar vacía.
  final bool tieneItemsGuardados;

  final double ingresoMensual;
  final double metaAhorro;

  const AppData({
    required this.items,
    required this.ingresos,
    required this.tarjetas,
    required this.historial,
    required this.movimientos,
    required this.tieneItemsGuardados,
    required this.ingresoMensual,
    required this.metaAhorro,
  });
}
