import 'enums/estado_tarea.dart';
import 'enums/prioridad_tarea.dart';
import 'enums/departamento.dart';

class Tarea {
  final int id;
  final String titulo;
  final String descripcion;
  final PrioridadTarea prioridad;
  final EstadoTarea estado;
  final Departamento? departamento;
  final DateTime? dueDate;
  final int empresaId;
  final int? asignadoA;
  final String? asignadoANombre;
  final int creadoPor;
  final String? creadoPorNombre;
  final List<String> capacidadesRequeridas;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tarea({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.prioridad,
    required this.estado,
    this.departamento,
    this.dueDate,
    required this.empresaId,
    this.asignadoA,
    this.asignadoANombre,
    required this.creadoPor,
    this.creadoPorNombre,
    required this.capacidadesRequeridas,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      prioridad: json['prioridad'] != null
          ? PrioridadTarea.fromValue(json['prioridad'])
          : PrioridadTarea.medium,
      estado: json['estado'] != null
          ? EstadoTarea.fromValue(json['estado'])
          : EstadoTarea.pendiente,
      departamento: json['departamento'] != null
          ? Departamento.fromValue(json['departamento'])
          : null,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      empresaId: json['empresaId'] ?? 0,
      asignadoA: json['asignadoA'],
      asignadoANombre: json['asignadoANombre'],
      creadoPor: json['creadoPor'] ?? 0,
      creadoPorNombre: json['creadoPorNombre'],
      capacidadesRequeridas: json['capacidadesRequeridas'] != null
          ? List<String>.from(json['capacidadesRequeridas'])
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'prioridad': prioridad.value,
      'estado': estado.value,
      'departamento': departamento?.value,
      'dueDate': dueDate?.toIso8601String(),
      'empresaId': empresaId,
      'asignadoA': asignadoA,
      'asignadoANombre': asignadoANombre,
      'creadoPor': creadoPor,
      'creadoPorNombre': creadoPorNombre,
      'capacidadesRequeridas': capacidadesRequeridas,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CreateTareaDTO {
  final String titulo;
  final String descripcion;
  final PrioridadTarea prioridad;
  final DateTime? dueDate;
  final Departamento? departamento;
  final List<String> capacidadesRequeridas;

  CreateTareaDTO({
    required this.titulo,
    required this.descripcion,
    this.prioridad = PrioridadTarea.medium,
    this.dueDate,
    this.departamento,
    this.capacidadesRequeridas = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'Titulo': titulo,
      'Descripcion': descripcion,
      'Prioridad': prioridad.value,
      if (dueDate != null) 'DueDate': dueDate!.toIso8601String(),
      if (departamento != null) 'Departamento': departamento!.value,
      'CapacidadesRequeridas': capacidadesRequeridas,
    };
  }
}

class AsignarManualTareaDTO {
  final int? usuarioId;
  final String? nombreUsuario;

  AsignarManualTareaDTO({
    this.usuarioId,
    this.nombreUsuario,
  });

  Map<String, dynamic> toJson() {
    return {
      if (usuarioId != null) 'UsuarioId': usuarioId,
      if (nombreUsuario != null) 'NombreUsuario': nombreUsuario,
      'IgnorarValidacionesSkills': true,
    };
  }
}

class AsignarAutomaticoTareaDTO {
  final bool forzarReasignacion;

  AsignarAutomaticoTareaDTO({
    this.forzarReasignacion = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'ForzarReasignacion': forzarReasignacion,
    };
  }
}

class FinalizarTareaDTO {
  final String? evidenciaTexto;
  final String? evidenciaImagenUrl;

  FinalizarTareaDTO({
    this.evidenciaTexto,
    this.evidenciaImagenUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      if (evidenciaTexto != null) 'EvidenciaTexto': evidenciaTexto,
      if (evidenciaImagenUrl != null) 'EvidenciaImagenUrl': evidenciaImagenUrl,
    };
  }
}
