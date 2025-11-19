class Usuario {
  final int id;
  final String email;
  final String nombreCompleto;
  final String? telefono;
  final String rol;
  final int? empresaId;
  final String? departamento;
  final int? nivelHabilidad;
  final bool isActive;
  final List<CapacidadUsuario> capacidades;

  Usuario({
    required this.id,
    required this.email,
    required this.nombreCompleto,
    this.telefono,
    required this.rol,
    this.empresaId,
    this.departamento,
    this.nivelHabilidad,
    required this.isActive,
    this.capacidades = const [],
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      telefono: json['telefono'],
      rol: json['rol'] ?? 'Usuario',
      empresaId: json['empresaId'],
      departamento: json['departamento'],
      nivelHabilidad: json['nivelHabilidad'],
      isActive: json['isActive'] ?? true,
      capacidades: json['capacidades'] != null
          ? (json['capacidades'] as List)
              .map((c) => CapacidadUsuario.fromJson(c))
              .toList()
          : [],
    );
  }
}

class CapacidadUsuario {
  final String nombre;
  final int nivel;

  CapacidadUsuario({
    required this.nombre,
    required this.nivel,
  });

  factory CapacidadUsuario.fromJson(Map<String, dynamic> json) {
    return CapacidadUsuario(
      nombre: json['nombre'] ?? '',
      nivel: json['nivel'] ?? 1,
    );
  }
}

class EmpresaEstadisticas {
  final int empresaId;
  final String nombreEmpresa;
  final int totalTrabajadores;
  final int trabajadoresActivos;
  final int totalTareas;
  final int tareasPendientes;
  final int tareasAsignadas;
  final int tareasAceptadas;
  final int tareasFinalizadas;
  final int tareasCanceladas;

  EmpresaEstadisticas({
    required this.empresaId,
    required this.nombreEmpresa,
    required this.totalTrabajadores,
    required this.trabajadoresActivos,
    required this.totalTareas,
    required this.tareasPendientes,
    required this.tareasAsignadas,
    required this.tareasAceptadas,
    required this.tareasFinalizadas,
    required this.tareasCanceladas,
  });

  factory EmpresaEstadisticas.fromJson(Map<String, dynamic> json) {
    return EmpresaEstadisticas(
      empresaId: json['empresaId'] ?? 0,
      nombreEmpresa: json['nombreEmpresa'] ?? '',
      totalTrabajadores: json['totalTrabajadores'] ?? 0,
      trabajadoresActivos: json['trabajadoresActivos'] ?? 0,
      totalTareas: json['totalTareas'] ?? 0,
      tareasPendientes: json['tareasPendientes'] ?? 0,
      tareasAsignadas: json['tareasAsignadas'] ?? 0,
      tareasAceptadas: json['tareasAceptadas'] ?? 0,
      tareasFinalizadas: json['tareasFinalizadas'] ?? 0,
      tareasCanceladas: json['tareasCanceladas'] ?? 0,
    );
  }

  int get tareasEnProgreso =>
      tareasAsignadas + tareasAceptadas;
}
