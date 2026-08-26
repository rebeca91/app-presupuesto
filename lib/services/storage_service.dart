import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/budget_item.dart';
import '../models/ingreso.dart';
import '../models/movimiento.dart';
import '../models/tarjeta_credito.dart';
import '../models/resumen_mensual.dart';
import '../models/app_data.dart';

class StorageService {
  static const _itemsStorageKey = 'items';
  static const _historialStorageKey = 'historial';
  static const _ingresoStorageKey = 'ingresoMensualManual';
  static const _metaAhorroStorageKey = 'metaAhorro';
  static const _tarjetasStorageKey = 'tarjetas';
  static const _ingresosStorageKey = 'ingresos';
  static const _movimientosStorageKey = 'movimientos';
  static const _legacyIngresoStorageKey = 'ingresoMensual';

  Future<void> reiniciarTodosLosDatos() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_itemsStorageKey);
    await prefs.remove(_historialStorageKey);
    await prefs.remove(_ingresoStorageKey);
    await prefs.remove(_ingresosStorageKey);
    await prefs.remove(_movimientosStorageKey);
    await prefs.remove(_tarjetasStorageKey);
    await prefs.remove(_metaAhorroStorageKey);
    await prefs.remove(_legacyIngresoStorageKey);
  }

  Future<void> guardarDatos({
    required List<BudgetItem> items,
    required List<Ingreso> ingresos,
    required List<TarjetaCredito> tarjetas,
    required List<ResumenMensual> historial,
    required double ingresoMensual,
    required double metaAhorro,
    List<Movimiento>? movimientos,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _itemsStorageKey,
      jsonEncode(items.map((item) => item.toMap()).toList()),
    );

    await prefs.setDouble(_ingresoStorageKey, ingresoMensual);

    await prefs.setString(
      _ingresosStorageKey,
      jsonEncode(ingresos.map((ingreso) => ingreso.toMap()).toList()),
    );

    if (movimientos != null) {
      await prefs.setString(
        _movimientosStorageKey,
        jsonEncode(
          movimientos.map((movimiento) => movimiento.toMap()).toList(),
        ),
      );
    }

    await prefs.setString(
      _tarjetasStorageKey,
      jsonEncode(tarjetas.map((tarjeta) => tarjeta.toMap()).toList()),
    );

    await prefs.setDouble(_metaAhorroStorageKey, metaAhorro);

    await prefs.setString(
      _historialStorageKey,
      jsonEncode(historial.map((item) => item.toMap()).toList()),
    );
  }

  Future<AppData> cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();

    final ingresoMensual =
        prefs.getDouble(_ingresoStorageKey) ??
        prefs.getDouble(_legacyIngresoStorageKey) ??
        0;

    final metaAhorro = prefs.getDouble(_metaAhorroStorageKey) ?? 0;

    final itemsTexto = prefs.getString(_itemsStorageKey);
    final historialTexto = prefs.getString(_historialStorageKey);
    final ingresosTexto = prefs.getString(_ingresosStorageKey);
    final movimientosTexto = prefs.getString(_movimientosStorageKey);
    final tarjetasTexto = prefs.getString(_tarjetasStorageKey);

    final List<BudgetItem> items = [];

    if (itemsTexto != null) {
      items.addAll(
        (jsonDecode(itemsTexto) as List).map(
          (item) => BudgetItem.fromMap(Map<String, dynamic>.from(item)),
        ),
      );
    }

    final List<ResumenMensual> historial = [];

    if (historialTexto != null) {
      historial.addAll(
        (jsonDecode(historialTexto) as List).map(
          (item) => ResumenMensual.fromMap(Map<String, dynamic>.from(item)),
        ),
      );
    }

    final List<Ingreso> ingresos = [];

    if (ingresosTexto != null) {
      ingresos.addAll(
        (jsonDecode(ingresosTexto) as List).map(
          (item) => Ingreso.fromMap(Map<String, dynamic>.from(item)),
        ),
      );
    }

    final List<Movimiento> movimientos = [];

    if (movimientosTexto != null) {
      movimientos.addAll(
        (jsonDecode(movimientosTexto) as List).map(
          (movimiento) =>
              Movimiento.fromMap(Map<String, dynamic>.from(movimiento)),
        ),
      );
    }

    final List<TarjetaCredito> tarjetas = [];

    if (tarjetasTexto != null) {
      tarjetas.addAll(
        (jsonDecode(tarjetasTexto) as List).map(
          (item) => TarjetaCredito.fromMap(Map<String, dynamic>.from(item)),
        ),
      );
    }

    return AppData(
      items: items,
      historial: historial,
      movimientos: movimientos,
      tieneItemsGuardados: itemsTexto != null,
      ingresos: ingresos,
      tarjetas: tarjetas,
      ingresoMensual: ingresoMensual,
      metaAhorro: metaAhorro,
    );
  }
}
