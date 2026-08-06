class Ingreso {
  final double monto;
  final String nota;
  final DateTime fecha;

  Ingreso({required this.monto, required this.nota, required this.fecha});

  Map<String, dynamic> toMap() {
    return {'monto': monto, 'nota': nota, 'fecha': fecha.toIso8601String()};
  }

  factory Ingreso.fromMap(Map<String, dynamic> map) {
    return Ingreso(
      monto: (map['monto'] as num).toDouble(),
      nota: map['nota'] ?? '',
      fecha: DateTime.parse(map['fecha']),
    );
  }
}
