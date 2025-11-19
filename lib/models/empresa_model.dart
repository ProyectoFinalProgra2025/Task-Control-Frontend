class EmpresaModel {
  final int id;
  final String nombre;
  final String? direccion;
  final String? telefono;
  final String estado; // Pending, Approved, Rejected
  final DateTime createdAt;

  EmpresaModel({
    required this.id,
    required this.nombre,
    this.direccion,
    this.telefono,
    required this.estado,
    required this.createdAt,
  });

  factory EmpresaModel.fromJson(Map<String, dynamic> json) {
    return EmpresaModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'],
      telefono: json['telefono'],
      estado: json['estado'] ?? 'Pending',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'estado': estado,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isPending => estado == 'Pending';
  bool get isApproved => estado == 'Approved';
  bool get isRejected => estado == 'Rejected';

  String get estadoDisplayName {
    switch (estado) {
      case 'Pending':
        return 'Pendiente';
      case 'Approved':
        return 'Aprobada';
      case 'Rejected':
        return 'Rechazada';
      default:
        return estado;
    }
  }
}

class EmpresaEstadisticasModel {
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

  EmpresaEstadisticasModel({
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

  factory EmpresaEstadisticasModel.fromJson(Map<String, dynamic> json) {
    return EmpresaEstadisticasModel(
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

  Map<String, dynamic> toJson() {
    return {
      'empresaId': empresaId,
      'nombreEmpresa': nombreEmpresa,
      'totalTrabajadores': totalTrabajadores,
      'trabajadoresActivos': trabajadoresActivos,
      'totalTareas': totalTareas,
      'tareasPendientes': tareasPendientes,
      'tareasAsignadas': tareasAsignadas,
      'tareasAceptadas': tareasAceptadas,
      'tareasFinalizadas': tareasFinalizadas,
      'tareasCanceladas': tareasCanceladas,
    };
  }
}

// Modelo para estadísticas globales del sistema (SUDO ADMIN)
class SystemStatsModel {
  final int totalEmpresas;
  final int empresasPendientes;
  final int empresasAprobadas;
  final int empresasRechazadas;
  final int totalTrabajadores;
  final int tareasActivas;
  final int tareasCompletadas;

  SystemStatsModel({
    required this.totalEmpresas,
    required this.empresasPendientes,
    required this.empresasAprobadas,
    required this.empresasRechazadas,
    required this.totalTrabajadores,
    required this.tareasActivas,
    required this.tareasCompletadas,
  });

  factory SystemStatsModel.fromMap(Map<String, dynamic> map) {
    return SystemStatsModel(
      totalEmpresas: map['totalEmpresas'] ?? 0,
      empresasPendientes: map['empresasPendientes'] ?? 0,
      empresasAprobadas: map['empresasAprobadas'] ?? 0,
      empresasRechazadas: map['empresasRechazadas'] ?? 0,
      totalTrabajadores: map['totalTrabajadores'] ?? 0,
      tareasActivas: map['tareasActivas'] ?? 0,
      tareasCompletadas: map['tareasCompletadas'] ?? 0,
    );
  }
}
