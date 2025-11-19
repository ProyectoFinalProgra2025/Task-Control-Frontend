/// Capacidades predefinidas para asignar a tareas
class Capacidades {
  static const List<String> todasLasCapacidades = [
    'Comunicación efectiva',
    'Trabajo en equipo',
    'Liderazgo',
    'Pensamiento analítico',
    'Resolución de problemas',
    'Gestión del tiempo',
    'Adaptabilidad',
    'Creatividad',
    'Atención al detalle',
    'Orientación a resultados',
  ];

  /// Obtener capacidades por categoría
  static const Map<String, List<String>> porCategoria = {
    'Habilidades Blandas': [
      'Comunicación efectiva',
      'Trabajo en equipo',
      'Liderazgo',
      'Adaptabilidad',
    ],
    'Habilidades Técnicas': [
      'Pensamiento analítico',
      'Resolución de problemas',
      'Atención al detalle',
    ],
    'Gestión': [
      'Gestión del tiempo',
      'Orientación a resultados',
      'Creatividad',
    ],
  };

  /// Validar si una capacidad existe
  static bool esValida(String capacidad) {
    return todasLasCapacidades.contains(capacidad);
  }

  /// Obtener capacidades filtradas por búsqueda
  static List<String> buscar(String query) {
    if (query.isEmpty) return todasLasCapacidades;
    
    final queryLower = query.toLowerCase();
    return todasLasCapacidades
        .where((cap) => cap.toLowerCase().contains(queryLower))
        .toList();
  }
}
