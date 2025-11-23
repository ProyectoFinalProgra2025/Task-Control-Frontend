class Usuario {
  final String id;
  final String email;
  final String nombreCompleto;
  final String? telefono;
  final String rol;
  final String? empresaId;
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
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      telefono: json['telefono'],
      rol: json['rol'] ?? 'Usuario',
      empresaId: json['empresaId']?.toString(),
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
  final String? capacidadId;
  final String nombre;
  final int nivel;

  CapacidadUsuario({
    this.capacidadId,
    required this.nombre,
    required this.nivel,
  });

  factory CapacidadUsuario.fromJson(Map<String, dynamic> json) {
    return CapacidadUsuario(
      capacidadId: json['capacidadId']?.toString(),
      nombre: json['nombre'] ?? '',
      nivel: json['nivel'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (capacidadId != null) 'capacidadId': capacidadId,
      'nombre': nombre,
      'nivel': nivel,
    };
  }
}

class EmpresaEstadisticas {
  final String empresaId;
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
      empresaId: json['empresaId']?.toString() ?? '',
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
