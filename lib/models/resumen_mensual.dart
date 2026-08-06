class ResumenMensual {
  final String mes;
  final double gastado;
  final double disponible;

  ResumenMensual({
    required this.mes,
    required this.gastado,
    required this.disponible,
  });

  factory ResumenMensual.fromMap(Map<String, dynamic> map) {
    return ResumenMensual(
      mes: map['mes'] as String,
      gastado: (map['gastado'] as num).toDouble(),
      disponible: (map['disponible'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'mes': mes, 'gastado': gastado, 'disponible': disponible};
  }
}
