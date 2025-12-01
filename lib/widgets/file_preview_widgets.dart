import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/theme_config.dart';

// Imports condicionales para web/mobile
import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart'
    if (dart.library.io) 'file_download_mobile.dart' as downloader;

/// Helper para determinar el tipo de archivo y abrir el previsualizador correcto
class FilePreviewHelper {
  /// Extensiones de imagen soportadas
  static const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
  
  /// Extensiones de PDF
  static const pdfExtensions = ['pdf'];
  
  /// Determina si es una imagen basándose en la URL o MIME type
  static bool isImage(String url, {String? mimeType}) {
    if (mimeType != null && mimeType.startsWith('image/')) return true;
    
    final extension = _getExtension(url);
    return imageExtensions.contains(extension);
  }
  
  /// Determina si es un PDF
  static bool isPdf(String url, {String? mimeType}) {
    if (mimeType != null && mimeType.contains('pdf')) return true;
    
    final extension = _getExtension(url);
    return pdfExtensions.contains(extension);
  }
  
  /// Obtiene la extensión de una URL
  static String _getExtension(String url) {
    try {
      // Limpiar query params si hay
      final cleanUrl = url.split('?').first;
      final parts = cleanUrl.split('.');
      if (parts.length > 1) {
        return parts.last.toLowerCase();
      }
    } catch (_) {}
    return '';
  }
  
  /// Abre el archivo con el previsualizador apropiado
  static Future<void> openFile(
    BuildContext context, {
    required String url,
    required String fileName,
    String? mimeType,
  }) async {
    if (isImage(url, mimeType: mimeType)) {
      // Mostrar imagen
      _showImagePreview(context, url: url, fileName: fileName);
    } else if (isPdf(url, mimeType: mimeType)) {
      // Mostrar PDF
      _showPdfPreview(context, url: url, fileName: fileName);
    } else {
      // Descargar archivo
      await _downloadFile(context, url: url, fileName: fileName);
    }
  }
  
  /// Muestra el previsualizador de imágenes
  static void _showImagePreview(
    BuildContext context, {
    required String url,
    required String fileName,
  }) {
    showDialog(
      context: context,
      builder: (context) => ImagePreviewDialog(
        imageUrl: url,
        fileName: fileName,
      ),
    );
  }
  
  /// Muestra el previsualizador de PDF
  static void _showPdfPreview(
    BuildContext context, {
    required String url,
    required String fileName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          pdfUrl: url,
          fileName: fileName,
        ),
      ),
    );
  }
  
  /// Descarga el archivo
  static Future<void> _downloadFile(
    BuildContext context, {
    required String url,
    required String fileName,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Mostrar snackbar de descarga iniciada
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Descargando $fileName...')),
            ],
          ),
          backgroundColor: AppTheme.primaryBlue,
          duration: const Duration(seconds: 30),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Usar el downloader apropiado para la plataforma
      await downloader.downloadFile(url, fileName);
        
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('$fileName descargado')),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error al descargar: $e'),
          backgroundColor: AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Diálogo para previsualizar imágenes
class ImagePreviewDialog extends StatefulWidget {
  final String imageUrl;
  final String fileName;

  const ImagePreviewDialog({
    super.key,
    required this.imageUrl,
    required this.fileName,
  });

  @override
  State<ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<ImagePreviewDialog> {
  final TransformationController _transformationController = TransformationController();
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: size.width,
        height: size.height,
        color: Colors.black.withOpacity(0.9),
        child: Stack(
          children: [
            // Imagen con zoom
            Center(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                child: _hasError
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 64,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No se pudo cargar la imagen',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      )
                    : Image.network(
                        widget.imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            if (_isLoading) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => _isLoading = false);
                              });
                            }
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && !_hasError) {
                              setState(() {
                                _hasError = true;
                                _isLoading = false;
                              });
                            }
                          });
                          return const SizedBox.shrink();
                        },
                      ),
              ),
            ),

            // Header con nombre y botones
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          widget.fileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: _resetZoom,
                        icon: const Icon(Icons.zoom_out_map, color: Colors.white),
                        tooltip: 'Restablecer zoom',
                      ),
                      IconButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await FilePreviewHelper._downloadFile(
                            context,
                            url: widget.imageUrl,
                            fileName: widget.fileName,
                          );
                        },
                        icon: const Icon(Icons.download, color: Colors.white),
                        tooltip: 'Descargar',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Instrucciones de zoom
            if (!_isLoading && !_hasError)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Pellizca para hacer zoom',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla para previsualizar PDFs (usando WebView o similar)
class PdfPreviewScreen extends StatefulWidget {
  final String pdfUrl;
  final String fileName;

  const PdfPreviewScreen({
    super.key,
    required this.pdfUrl,
    required this.fileName,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Verificar que el PDF es accesible
      final response = await http.head(Uri.parse(widget.pdfUrl));
      
      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          widget.fileName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        actions: [
          IconButton(
            onPressed: () async {
              await FilePreviewHelper._downloadFile(
                context,
                url: widget.pdfUrl,
                fileName: widget.fileName,
              );
            },
            icon: const Icon(Icons.download),
            tooltip: 'Descargar',
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryBlue),
            const SizedBox(height: 16),
            Text(
              'Cargando PDF...',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 64,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar el PDF',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Puedes descargarlo para verlo',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await FilePreviewHelper._downloadFile(
                  context,
                  url: widget.pdfUrl,
                  fileName: widget.fileName,
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Descargar PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadPdf,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Si llegó aquí, el PDF se descargó
    // Por ahora mostramos un mensaje de éxito con opción de descargar
    // Nota: Para un visor de PDF real, necesitaríamos flutter_pdfview o similar
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.picture_as_pdf,
              size: 64,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.fileName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'PDF listo para descargar',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await FilePreviewHelper._downloadFile(
                context,
                url: widget.pdfUrl,
                fileName: widget.fileName,
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Descargar PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
