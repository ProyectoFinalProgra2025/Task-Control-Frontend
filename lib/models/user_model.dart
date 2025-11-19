class UserModel {
  final int id;
  final String email;
  final String nombreCompleto;
  final String? telefono;
  final String rol; // AdminGeneral, AdminEmpresa, Usuario
  final int? empresaId;
  final String? nombreEmpresa;

  UserModel({
    required this.id,
    required this.email,
    required this.nombreCompleto,
    this.telefono,
    required this.rol,
    this.empresaId,
    this.nombreEmpresa,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      telefono: json['telefono'],
      rol: json['rol'] ?? 'Usuario',
      empresaId: json['empresaId'],
      nombreEmpresa: json['nombreEmpresa'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombreCompleto': nombreCompleto,
      'telefono': telefono,
      'rol': rol,
      'empresaId': empresaId,
      'nombreEmpresa': nombreEmpresa,
    };
  }

  bool get isAdminGeneral => rol == 'AdminGeneral';
  bool get isAdminEmpresa => rol == 'AdminEmpresa';
  bool get isUsuario => rol == 'Usuario';
}
