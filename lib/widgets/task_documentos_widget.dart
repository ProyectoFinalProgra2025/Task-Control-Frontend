import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../models/documento_adjunto.dart';
import '../services/file_upload_service.dart';
import 'file_preview_widgets.dart';

/// Widget que muestra los documentos adjuntos de una tarea
class TaskDocumentosWidget extends StatefulWidget {
  final String tareaId;
  final bool showTitle;
  final bool canDelete;
  final VoidCallback? onDocumentosChanged;

  const TaskDocumentosWidget({
    super.key,
    required this.tareaId,
    this.showTitle = true,
    this.canDelete = false,
    this.onDocumentosChanged,
  });

  @override
  State<TaskDocumentosWidget> createState() => _TaskDocumentosWidgetState();
}

class _TaskDocumentosWidgetState extends State<TaskDocumentosWidget> {
  final FileUploadService _fileService = FileUploadService();
  List<DocumentoAdjunto> _documentos = [];
  bool _isLoading = true;
  bool _isExpanded = true; // Expandido por defecto para documentos

  @override
  void initState() {
    super.initState();
    _loadDocumentos();
  }

  Future<void> _loadDocumentos() async {
    setState(() => _isLoading = true);
    try {
      final documentos = await _fileService.getDocumentosTarea(widget.tareaId);
      if (mounted) {
        setState(() {
          _documentos = documentos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteDocumento(DocumentoAdjunto documento) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Documento'),
        content: Text('¿Eliminar "${documento.nombreArchivo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _fileService.deleteDocumentoTarea(
        widget.tareaId,
        documento.id,
      );
      if (success) {
        await _loadDocumentos();
        widget.onDocumentosChanged?.call();
      }
    }
  }

  Future<void> _openFile(String url, String fileName, String? mimeType) async {
    await FilePreviewHelper.openFile(
      context,
      url: url,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  IconData _getFileIcon(String? mimeType, String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    // Por extensión
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension)) {
      return Icons.image;
    }
    if (['mp4', 'avi', 'mov', 'mkv'].contains(extension)) {
      return Icons.video_file;
    }
    if (['mp3', 'wav', 'aac', 'flac'].contains(extension)) {
      return Icons.audio_file;
    }
    if (extension == 'pdf') return Icons.picture_as_pdf;
    if (['doc', 'docx'].contains(extension)) return Icons.description;
    if (['xls', 'xlsx'].contains(extension)) return Icons.table_chart;
    if (['ppt', 'pptx'].contains(extension)) return Icons.slideshow;
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(extension)) return Icons.folder_zip;
    
    // Por MIME type
    if (mimeType != null) {
      if (mimeType.startsWith('image/')) return Icons.image;
      if (mimeType.startsWith('video/')) return Icons.video_file;
      if (mimeType.startsWith('audio/')) return Icons.audio_file;
      if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    }
    
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String? mimeType, String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension)) {
      return Colors.purple;
    }
    if (['mp4', 'avi', 'mov', 'mkv'].contains(extension)) return Colors.red;
    if (['mp3', 'wav', 'aac', 'flac'].contains(extension)) return Colors.orange;
    if (extension == 'pdf') return const Color(0xFFE53935);
    if (['doc', 'docx'].contains(extension)) return const Color(0xFF2196F3);
    if (['xls', 'xlsx'].contains(extension)) return const Color(0xFF4CAF50);
    if (['ppt', 'pptx'].contains(extension)) return const Color(0xFFFF5722);
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(extension)) return Colors.amber;
    
    return AppTheme.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Cargando documentos...',
              style: TextStyle(color: textSecondary),
            ),
          ],
        ),
      );
    }

    if (_documentos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.attach_file_rounded,
                      size: 20,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Documentos Adjuntos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '${_documentos.length} ${_documentos.length == 1 ? 'archivo' : 'archivos'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Lista de documentos
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1, color: borderColor.withOpacity(0.3)),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _documentos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = _documentos[index];
                    return _buildDocumentoItem(doc, isDark, textPrimary, textSecondary);
                  },
                ),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentoItem(
    DocumentoAdjunto doc,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final fileColor = _getFileColor(doc.tipoMime, doc.nombreArchivo);
    final fileIcon = _getFileIcon(doc.tipoMime, doc.nombreArchivo);

    return InkWell(
      onTap: () => _openFile(doc.archivoUrl, doc.nombreArchivo, doc.tipoMime),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: fileColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fileColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            // Icono del archivo
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: fileColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(fileIcon, size: 24, color: fileColor),
            ),
            const SizedBox(width: 14),
            
            // Info del archivo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.nombreArchivo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        doc.tamanoFormateado,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(color: textSecondary),
                      ),
                      Text(
                        'Por ${doc.subidoPorUsuarioNombre}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Botones de acción
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _openFile(doc.archivoUrl, doc.nombreArchivo, doc.tipoMime),
                  icon: Icon(Icons.visibility, size: 20, color: fileColor),
                  tooltip: 'Ver archivo',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                if (widget.canDelete)
                  IconButton(
                    onPressed: () => _deleteDocumento(doc),
                    icon: Icon(Icons.delete_outline, size: 20, color: AppTheme.dangerRed),
                    tooltip: 'Eliminar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
