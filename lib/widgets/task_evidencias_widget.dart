import 'package:flutter/material.dart';
import '../config/theme_config.dart';
import '../models/evidencia.dart';
import '../services/file_upload_service.dart';
import 'file_preview_widgets.dart';

/// Widget que muestra las evidencias de una tarea
class TaskEvidenciasWidget extends StatefulWidget {
  final String tareaId;
  final bool showTitle;
  final bool canDelete;
  final VoidCallback? onEvidenciasChanged;

  const TaskEvidenciasWidget({
    super.key,
    required this.tareaId,
    this.showTitle = true,
    this.canDelete = false,
    this.onEvidenciasChanged,
  });

  @override
  State<TaskEvidenciasWidget> createState() => _TaskEvidenciasWidgetState();
}

class _TaskEvidenciasWidgetState extends State<TaskEvidenciasWidget> {
  final FileUploadService _fileService = FileUploadService();
  List<Evidencia> _evidencias = [];
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadEvidencias();
  }

  Future<void> _loadEvidencias() async {
    setState(() => _isLoading = true);
    try {
      final evidencias = await _fileService.getEvidenciasTarea(widget.tareaId);
      if (mounted) {
        setState(() {
          _evidencias = evidencias;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteEvidencia(Evidencia evidencia) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Evidencia'),
        content: const Text('¿Estás seguro de que deseas eliminar esta evidencia?'),
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
      final success = await _fileService.deleteEvidenciaTarea(
        widget.tareaId,
        evidencia.id,
      );
      if (success) {
        await _loadEvidencias();
        widget.onEvidenciasChanged?.call();
      }
    }
  }

  Future<void> _openFile(String url, String? fileName, String? mimeType) async {
    await FilePreviewHelper.openFile(
      context,
      url: url,
      fileName: fileName ?? 'archivo',
      mimeType: mimeType,
    );
  }

  IconData _getFileIcon(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file;
    
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.startsWith('video/')) return Icons.video_file;
    if (mimeType.startsWith('audio/')) return Icons.audio_file;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('document')) return Icons.description;
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) return Icons.table_chart;
    if (mimeType.contains('powerpoint') || mimeType.contains('presentation')) return Icons.slideshow;
    if (mimeType.contains('zip') || mimeType.contains('rar') || mimeType.contains('tar')) return Icons.folder_zip;
    
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String? mimeType) {
    if (mimeType == null) return Colors.grey;
    
    if (mimeType.startsWith('image/')) return Colors.purple;
    if (mimeType.startsWith('video/')) return Colors.red;
    if (mimeType.startsWith('audio/')) return Colors.orange;
    if (mimeType.contains('pdf')) return Colors.red;
    if (mimeType.contains('word') || mimeType.contains('document')) return Colors.blue;
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) return Colors.green;
    if (mimeType.contains('powerpoint') || mimeType.contains('presentation')) return Colors.deepOrange;
    
    return Colors.grey;
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
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
      );
    }

    if (_evidencias.isEmpty) {
      return const SizedBox.shrink(); // No mostrar nada si no hay evidencias
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header expandible
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.fact_check,
                      size: 18,
                      color: AppTheme.successGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evidencias',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '${_evidencias.length} ${_evidencias.length == 1 ? 'evidencia' : 'evidencias'}',
                          style: TextStyle(
                            fontSize: 12,
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

          // Lista de evidencias (expandible)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1, color: borderColor),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: _evidencias.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final evidencia = _evidencias[index];
                    return _buildEvidenciaItem(evidencia, isDark, textPrimary, textSecondary, borderColor);
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

  Widget _buildEvidenciaItem(
    Evidencia evidencia,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    final hasFile = evidencia.archivoUrl != null && evidencia.archivoUrl!.isNotEmpty;
    final hasDescription = evidencia.descripcion != null && evidencia.descripcion!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con fecha y usuario
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  evidencia.subidoPorUsuarioNombre.isNotEmpty 
                      ? evidencia.subidoPorUsuarioNombre 
                      : 'Usuario',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDate(evidencia.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
              if (widget.canDelete) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _deleteEvidencia(evidencia),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppTheme.dangerRed,
                  ),
                ),
              ],
            ],
          ),

          // Descripción
          if (hasDescription) ...[
            const SizedBox(height: 8),
            Text(
              evidencia.descripcion!,
              style: TextStyle(
                fontSize: 13,
                color: textPrimary,
                height: 1.4,
              ),
            ),
          ],

          // Archivo adjunto
          if (hasFile) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _openFile(evidencia.archivoUrl!, evidencia.nombreArchivo, evidencia.tipoMime),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getFileColor(evidencia.tipoMime).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getFileColor(evidencia.tipoMime).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFileIcon(evidencia.tipoMime),
                      size: 20,
                      color: _getFileColor(evidencia.tipoMime),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        evidencia.nombreArchivo ?? 'Archivo adjunto',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: _getFileColor(evidencia.tipoMime),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Ahora';
    if (difference.inHours < 1) return 'Hace ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'Hace ${difference.inHours}h';
    if (difference.inDays == 1) return 'Ayer';
    if (difference.inDays < 7) return 'Hace ${difference.inDays} días';

    return '${date.day}/${date.month}/${date.year}';
  }
}
