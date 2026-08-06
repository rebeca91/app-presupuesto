class Movimiento {
  final String categoria;
  final double monto;
  final DateTime fecha;
  final String metodoPago;

  Movimiento({
    required this.categoria,
    required this.monto,
    required this.fecha,
    required this.metodoPago,
  });

  factory Movimiento.fromMap(Map<String, dynamic> map) {
    return Movimiento(
      categoria: map['categoria'] as String,
      monto: (map['monto'] as num).toDouble(),
      fecha: DateTime.parse(map['fecha'] as String),
      metodoPago: map['metodoPago'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoria': categoria,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'metodoPago': metodoPago,
    };
  }
}
