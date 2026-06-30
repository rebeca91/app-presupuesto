class TarjetaCredito {
  String nombre;
  double limite;
  double saldoActual;
  int diaCorte;
  int diaPago;

  TarjetaCredito({
    required this.nombre,
    required this.limite,
    required this.saldoActual,
    required this.diaCorte,
    required this.diaPago,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'limite': limite,
      'saldoActual': saldoActual,
      'diaCorte': diaCorte,
      'diaPago': diaPago,
    };
  }

  factory TarjetaCredito.fromMap(Map<String, dynamic> map) {
    return TarjetaCredito(
      nombre: map['nombre'],
      limite: (map['limite'] as num).toDouble(),
      saldoActual: (map['saldoActual'] as num).toDouble(),
      diaCorte: map['diaCorte'],
      diaPago: map['diaPago'],
    );
  }
}