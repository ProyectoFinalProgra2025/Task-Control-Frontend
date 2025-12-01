/// Modelo para representar una evidencia de tarea
class Evidencia {
  final String id;
  final String? descripcion;
  final String? nombreArchivo;
  final String? archivoUrl;
  final String? tipoMime;
  final int tamanoBytes;
  final String subidoPorUsuarioId;
  final String subidoPorUsuarioNombre;
  final DateTime createdAt;

  Evidencia({
    required this.id,
    this.descripcion,
    this.nombreArchivo,
    this.archivoUrl,
    this.tipoMime,
    required this.tamanoBytes,
    required this.subidoPorUsuarioId,
    required this.subidoPorUsuarioNombre,
    required this.createdAt,
  });

  factory Evidencia.fromJson(Map<String, dynamic> json) {
    return Evidencia(
      id: json['id']?.toString() ?? '',
      descripcion: json['descripcion'],
      nombreArchivo: json['nombreArchivo'],
      archivoUrl: json['archivoUrl'],
      tipoMime: json['tipoMime'],
      tamanoBytes: json['tamanoBytes'] ?? 0,
      subidoPorUsuarioId: json['subidoPorUsuarioId']?.toString() ?? '',
      subidoPorUsuarioNombre: json['subidoPorUsuarioNombre'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descripcion': descripcion,
      'nombreArchivo': nombreArchivo,
      'archivoUrl': archivoUrl,
      'tipoMime': tipoMime,
      'tamanoBytes': tamanoBytes,
      'subidoPorUsuarioId': subidoPorUsuarioId,
      'subidoPorUsuarioNombre': subidoPorUsuarioNombre,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Verificar si tiene archivo adjunto
  bool get tieneArchivo => archivoUrl != null && archivoUrl!.isNotEmpty;

  /// Verificar si solo es texto
  bool get soloTexto => !tieneArchivo && descripcion != null && descripcion!.isNotEmpty;

  /// Obtener extensión del archivo
  String get extension {
    if (nombreArchivo == null) return '';
    final parts = nombreArchivo!.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Verificar si es una imagen
  bool get isImage {
    if (!tieneArchivo) return false;
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    return imageExtensions.contains(extension) ||
        (tipoMime != null && tipoMime!.startsWith('image/'));
  }

  /// Verificar si es un PDF
  bool get isPdf {
    if (!tieneArchivo) return false;
    return extension == 'pdf' || tipoMime == 'application/pdf';
  }

  /// Verificar si es un documento de Word
  bool get isWord {
    if (!tieneArchivo) return false;
    return extension == 'doc' ||
        extension == 'docx' ||
        (tipoMime != null && tipoMime!.contains('word'));
  }

  /// Verificar si es un archivo de Excel
  bool get isExcel {
    if (!tieneArchivo) return false;
    return extension == 'xls' ||
        extension == 'xlsx' ||
        (tipoMime != null && (tipoMime!.contains('excel') || tipoMime!.contains('spreadsheet')));
  }

  /// Obtener tamaño formateado
  String get tamanoFormateado {
    if (tamanoBytes == 0) return '';
    if (tamanoBytes < 1024) return '$tamanoBytes B';
    if (tamanoBytes < 1024 * 1024) {
      return '${(tamanoBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(tamanoBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
