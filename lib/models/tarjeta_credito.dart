class TarjetaCredito {
  String nombre;
  double limite;
  double saldoActual;
  double saldoUltimoCorte;
  int diaCorte;
  int diaPago;
  bool recordatoriosActivos;
  int diasAnticipacionPago;
  DateTime? ultimoCorteGenerado;

  TarjetaCredito({
    required this.nombre,
    required this.limite,
    required this.saldoActual,
    required this.saldoUltimoCorte,
    required this.diaCorte,
    required this.diaPago,
    this.recordatoriosActivos = true,
    this.diasAnticipacionPago = 0,
    this.ultimoCorteGenerado,
  });

  double get creditoDisponible => limite - saldoActual;

  double get consumoNuevo {
    final consumo = saldoActual - saldoUltimoCorte;
    return consumo < 0 ? 0 : consumo;
  }

  void generarCorte({DateTime? fecha}) {
    saldoUltimoCorte = saldoActual;
    ultimoCorteGenerado = fecha ?? DateTime.now();
  }

  bool debeGenerarCorteAutomatico(DateTime fecha) {
    final ultimoDiaDelMes = DateTime(fecha.year, fecha.month + 1, 0).day;
    final diaDeCorte = diaCorte.clamp(1, ultimoDiaDelMes);
    final fechaDeCorte = DateTime(fecha.year, fecha.month, diaDeCorte);

    if (fecha.isBefore(fechaDeCorte)) return false;

    return ultimoCorteGenerado == null ||
        ultimoCorteGenerado!.year != fecha.year ||
        ultimoCorteGenerado!.month != fecha.month;
  }

  void registrarPago(double monto) {
    if (monto <= 0) return;

    saldoUltimoCorte -= monto;
    if (saldoUltimoCorte < 0) {
      saldoUltimoCorte = 0;
    }

    saldoActual -= monto;
    if (saldoActual < 0) {
      saldoActual = 0;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'limite': limite,
      'saldoActual': saldoActual,
      'saldoUltimoCorte': saldoUltimoCorte,
      'diaCorte': diaCorte,
      'diaPago': diaPago,
      'recordatoriosActivos': recordatoriosActivos,
      'diasAnticipacionPago': diasAnticipacionPago,
      'ultimoCorteGenerado': ultimoCorteGenerado?.toIso8601String(),
    };
  }

  factory TarjetaCredito.fromMap(Map<String, dynamic> map) {
    final saldoActual = (map['saldoActual'] as num).toDouble();

    return TarjetaCredito(
      nombre: map['nombre'],
      limite: (map['limite'] as num).toDouble(),
      saldoActual: saldoActual,
      saldoUltimoCorte: _leerSaldoUltimoCorte(map, saldoActual),
      diaCorte: map['diaCorte'],
      diaPago: map['diaPago'],
      recordatoriosActivos: map['recordatoriosActivos'] as bool? ?? true,
      diasAnticipacionPago: _leerDiasAnticipacionPago(map),
      ultimoCorteGenerado: _leerUltimoCorteGenerado(map),
    );
  }

  static double _leerSaldoUltimoCorte(
    Map<String, dynamic> map,
    double saldoActual,
  ) {
    final saldoUltimoCorte = map['saldoUltimoCorte'];
    if (saldoUltimoCorte is num) {
      return saldoUltimoCorte.toDouble();
    }

    final cortes = map['cortes'];
    if (cortes is List) {
      return cortes.fold<double>(0, (total, item) {
        final corte = Map<String, dynamic>.from(item);
        final pendiente = corte['montoPendiente'];
        if (pendiente is! num || pendiente <= 0) return total;
        return total + pendiente.toDouble();
      });
    }

    return saldoActual;
  }

  static int _leerDiasAnticipacionPago(Map<String, dynamic> map) {
    final dias = map['diasAnticipacionPago'];
    return dias is num && dias >= 0 ? dias.toInt() : 0;
  }

  static DateTime? _leerUltimoCorteGenerado(Map<String, dynamic> map) {
    final fecha = map['ultimoCorteGenerado'];
    return fecha is String ? DateTime.tryParse(fecha) : null;
  }
}
