/// Modelo para el resultado de importación de un usuario individual
class ImportarUsuarioResultado {
  final int fila;
  final String email;
  final String nombreCompleto;
  final bool exitoso;
  final String? error;
  final String? usuarioId;
  final String? passwordGenerado;

  ImportarUsuarioResultado({
    required this.fila,
    required this.email,
    required this.nombreCompleto,
    required this.exitoso,
    this.error,
    this.usuarioId,
    this.passwordGenerado,
  });

  factory ImportarUsuarioResultado.fromJson(Map<String, dynamic> json) {
    return ImportarUsuarioResultado(
      fila: json['fila'] ?? 0,
      email: json['email'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      exitoso: json['exitoso'] ?? false,
      error: json['error'],
      usuarioId: json['usuarioId'],
      passwordGenerado: json['passwordGenerado'],
    );
  }
}

/// Modelo para el resultado completo de la importación masiva
class ImportarUsuariosResultado {
  final int totalProcesados;
  final int exitosos;
  final int fallidos;
  final List<ImportarUsuarioResultado> resultados;

  ImportarUsuariosResultado({
    required this.totalProcesados,
    required this.exitosos,
    required this.fallidos,
    required this.resultados,
  });

  factory ImportarUsuariosResultado.fromJson(Map<String, dynamic> json) {
    return ImportarUsuariosResultado(
      totalProcesados: json['totalProcesados'] ?? 0,
      exitosos: json['exitosos'] ?? 0,
      fallidos: json['fallidos'] ?? 0,
      resultados: (json['resultados'] as List<dynamic>?)
              ?.map((r) => ImportarUsuarioResultado.fromJson(r))
              .toList() ??
          [],
    );
  }

  /// Porcentaje de éxito
  double get porcentajeExito =>
      totalProcesados > 0 ? (exitosos / totalProcesados) * 100 : 0;

  /// Usuarios que tuvieron errores
  List<ImportarUsuarioResultado> get conErrores =>
      resultados.where((r) => !r.exitoso).toList();

  /// Usuarios creados exitosamente
  List<ImportarUsuarioResultado> get creados =>
      resultados.where((r) => r.exitoso).toList();
}
