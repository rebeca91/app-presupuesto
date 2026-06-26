class BudgetItem {
  String categoria;
  double presupuesto;
  double real;
  final String nota;

  BudgetItem({
    required this.categoria,
    required this.presupuesto,
    this.real = 0,
    this.nota = '',
  });

  factory BudgetItem.fromMap(Map<String, dynamic> map) {
    return BudgetItem(
      categoria: map['categoria'] as String,
      presupuesto: (map['presupuesto'] as num).toDouble(),
      real: (map['real'] as num).toDouble(),
      nota: map['nota'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoria': categoria,
      'presupuesto': presupuesto,
      'real': real,
      'nota': nota,
    };
  }
}