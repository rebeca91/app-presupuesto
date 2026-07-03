import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/budget_item.dart';
import '../models/ingreso.dart';
import '../models/tarjeta_credito.dart';
import '../models/resumen_mensual.dart';


class StorageService {
  static const _itemsStorageKey = 'items';
  static const _historialStorageKey = 'historial';
  static const _ingresoStorageKey = 'ingresoMensual';
  static const _metaAhorroStorageKey = 'metaAhorro';
  static const _tarjetasStorageKey = 'tarjetas';
  static const _ingresosStorageKey = 'ingresos';


Future<void> guardarDatos({
  required List<BudgetItem> items,
  required List<Ingreso> ingresos,
  required List<TarjetaCredito> tarjetas,
  required List<ResumenMensual> historial,
  required double ingresoMensual,
  required double metaAhorro,
}) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(
    _itemsStorageKey,
    jsonEncode(items.map((item) => item.toMap()).toList()),
  );

  await prefs.setDouble(
    _ingresoStorageKey,
    ingresoMensual,
  );

  await prefs.setString(
    _ingresosStorageKey,
    jsonEncode(ingresos.map((ingreso) => ingreso.toMap()).toList()),
  );

  await prefs.setString(
    _tarjetasStorageKey,
    jsonEncode(tarjetas.map((tarjeta) => tarjeta.toMap()).toList()),
  );

  await prefs.setDouble(
    _metaAhorroStorageKey,
    metaAhorro,
  );

  await prefs.setString(
    _historialStorageKey,
    jsonEncode(historial.map((item) => item.toMap()).toList()),
  );
}
}





