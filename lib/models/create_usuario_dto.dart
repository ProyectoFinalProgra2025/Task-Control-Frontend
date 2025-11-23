import 'enums/departamento.dart';

class CreateUsuarioDTO {
  final String email;
  final String password;
  final String nombreCompleto;
  final String? telefono;
  final Departamento? departamento;
  final int? nivelHabilidad;

  CreateUsuarioDTO({
    required this.email,
    required this.password,
    required this.nombreCompleto,
    this.telefono,
    this.departamento,
    this.nivelHabilidad,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'nombreCompleto': nombreCompleto,
      if (telefono != null) 'telefono': telefono,
      if (departamento != null) 'departamento': departamento!.index,
      if (nivelHabilidad != null) 'nivelHabilidad': nivelHabilidad,
    };
  }
}
