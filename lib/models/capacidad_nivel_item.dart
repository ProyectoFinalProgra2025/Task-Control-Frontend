class CapacidadNivelItem {
  final String nombre;
  final int nivel;

  CapacidadNivelItem({
    required this.nombre,
    required this.nivel,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'nivel': nivel,
    };
  }

  factory CapacidadNivelItem.fromJson(Map<String, dynamic> json) {
    return CapacidadNivelItem(
      nombre: json['nombre'] ?? '',
      nivel: json['nivel'] ?? 1,
    );
  }
}
