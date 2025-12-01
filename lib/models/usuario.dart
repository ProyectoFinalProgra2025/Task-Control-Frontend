class Usuario {
  final String id;
  final String email;
  final String nombreCompleto;
  final String? telefono;
  final String rol;
  final String? empresaId;
  final String? empresaNombre;
  final String? departamento;
  final int? nivelHabilidad;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<CapacidadUsuario> capacidades;

  Usuario({
    required this.id,
    required this.email,
    required this.nombreCompleto,
    this.telefono,
    required this.rol,
    this.empresaId,
    this.empresaNombre,
    this.departamento,
    this.nivelHabilidad,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
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
      empresaNombre: json['empresaNombre'],
      departamento: json['departamento'],
      nivelHabilidad: json['nivelHabilidad'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt']) 
          : null,
      capacidades: json['capacidades'] != null
          ? (json['capacidades'] as List)
              .map((c) => CapacidadUsuario.fromJson(c))
              .toList()
          : [],
    );
  }
  
  /// Helper para obtener el nombre del rol en formato legible
  String get rolDisplayName {
    switch (rol.toLowerCase()) {
      case 'admingeneral':
        return 'Super Admin';
      case 'adminempresa':
        return 'Company Admin';
      case 'managerdepartamento':
        return 'Manager';
      case 'usuario':
        return 'Worker';
      default:
        return rol;
    }
  }
  
  /// Helper para obtener el nombre del departamento legible
  String? get departamentoDisplayName {
    if (departamento == null) return null;
    // Capitalizar primera letra y el resto minúscula
    return departamento!.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
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

/// Estadísticas personales del usuario (tareas)
class UsuarioDashboardStats {
  final int total;
  final int pendientes;
  final int asignadas;
  final int aceptadas;
  final int finalizadas;
  final int hoy;
  final int urgentes;

  UsuarioDashboardStats({
    required this.total,
    required this.pendientes,
    required this.asignadas,
    required this.aceptadas,
    required this.finalizadas,
    required this.hoy,
    required this.urgentes,
  });

  factory UsuarioDashboardStats.fromJson(Map<String, dynamic> json) {
    final tareas = json['tareas'] ?? json;
    return UsuarioDashboardStats(
      total: tareas['total'] ?? 0,
      pendientes: tareas['pendientes'] ?? 0,
      asignadas: tareas['asignadas'] ?? 0,
      aceptadas: tareas['aceptadas'] ?? 0,
      finalizadas: tareas['finalizadas'] ?? 0,
      hoy: tareas['hoy'] ?? 0,
      urgentes: tareas['urgentes'] ?? 0,
    );
  }
  
  /// Tareas en progreso = asignadas + aceptadas
  int get enProgreso => asignadas + aceptadas;
  
  /// Porcentaje de tareas completadas
  double get porcentajeCompletado => total > 0 ? (finalizadas / total) * 100 : 0;
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
