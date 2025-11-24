enum Departamento {
  ninguno(0, 'Ninguno'),
  finanzas(1, 'Finanzas'),
  mantenimiento(2, 'Mantenimiento'),
  produccion(3, 'Producción'),
  marketing(4, 'Marketing'),
  logistica(5, 'Logística');

  final int value;
  final String label;

  const Departamento(this.value, this.label);
  
  // Lista de los 5 departamentos principales (sin Ninguno)
  static List<Departamento> get principales => [
    finanzas,
    mantenimiento,
    produccion,
    marketing,
    logistica,
  ];

  static Departamento fromValue(int value) {
    return Departamento.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Departamento.ninguno,
    );
  }

  static Departamento fromString(String str) {
    return Departamento.values.firstWhere(
      (e) => e.name.toLowerCase() == str.toLowerCase(),
      orElse: () => Departamento.ninguno,
    );
  }
}
