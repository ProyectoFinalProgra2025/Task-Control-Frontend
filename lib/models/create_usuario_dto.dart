import 'enums/departamento.dart';

enum RolUsuario {
  usuario(3, 'Worker'),
  managerDepartamento(4, 'Jefe de Área');

  final int value;
  final String label;

  const RolUsuario(this.value, this.label);
}

class CreateUsuarioDTO {
  final String email;
  final String password;
  final String nombreCompleto;
  final String? telefono;
  final RolUsuario? rol;
  final Departamento? departamento;
  final int? nivelHabilidad;

  CreateUsuarioDTO({
    required this.email,
    required this.password,
    required this.nombreCompleto,
    this.telefono,
    this.rol,
    this.departamento,
    this.nivelHabilidad,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'nombreCompleto': nombreCompleto,
      if (telefono != null) 'telefono': telefono,
      if (rol != null) 'rol': rol!.value,
      if (departamento != null) 'departamento': departamento!.index,
      if (nivelHabilidad != null) 'nivelHabilidad': nivelHabilidad,
    };
  }
}
