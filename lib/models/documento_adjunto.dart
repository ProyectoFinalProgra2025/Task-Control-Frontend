/// Modelo para representar un documento adjunto de tarea
class DocumentoAdjunto {
  final String id;
  final String nombreArchivo;
  final String archivoUrl;
  final String tipoMime;
  final int tamanoBytes;
  final String subidoPorUsuarioId;
  final String subidoPorUsuarioNombre;
  final DateTime createdAt;

  DocumentoAdjunto({
    required this.id,
    required this.nombreArchivo,
    required this.archivoUrl,
    required this.tipoMime,
    required this.tamanoBytes,
    required this.subidoPorUsuarioId,
    required this.subidoPorUsuarioNombre,
    required this.createdAt,
  });

  factory DocumentoAdjunto.fromJson(Map<String, dynamic> json) {
    return DocumentoAdjunto(
      id: json['id']?.toString() ?? '',
      nombreArchivo: json['nombreArchivo'] ?? '',
      archivoUrl: json['archivoUrl'] ?? '',
      tipoMime: json['tipoMime'] ?? '',
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
      'nombreArchivo': nombreArchivo,
      'archivoUrl': archivoUrl,
      'tipoMime': tipoMime,
      'tamanoBytes': tamanoBytes,
      'subidoPorUsuarioId': subidoPorUsuarioId,
      'subidoPorUsuarioNombre': subidoPorUsuarioNombre,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Obtener extensión del archivo
  String get extension {
    final parts = nombreArchivo.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Verificar si es una imagen
  bool get isImage {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    return imageExtensions.contains(extension) ||
        tipoMime.startsWith('image/');
  }

  /// Verificar si es un PDF
  bool get isPdf {
    return extension == 'pdf' || tipoMime == 'application/pdf';
  }

  /// Verificar si es un documento de Word
  bool get isWord {
    return extension == 'doc' ||
        extension == 'docx' ||
        tipoMime.contains('word');
  }

  /// Verificar si es un archivo de Excel
  bool get isExcel {
    return extension == 'xls' ||
        extension == 'xlsx' ||
        tipoMime.contains('excel') ||
        tipoMime.contains('spreadsheet');
  }

  /// Obtener tamaño formateado
  String get tamanoFormateado {
    if (tamanoBytes < 1024) return '$tamanoBytes B';
    if (tamanoBytes < 1024 * 1024) {
      return '${(tamanoBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(tamanoBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
