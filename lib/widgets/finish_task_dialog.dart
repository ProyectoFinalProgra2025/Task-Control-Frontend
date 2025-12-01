import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../config/theme_config.dart';
import '../models/tarea.dart';
import 'file_attachment_widget.dart';

/// Diálogo para finalizar una tarea con evidencias (texto + archivos)
class FinishTaskDialog extends StatefulWidget {
  final Tarea tarea;
  final Future<bool> Function(String?, List<PlatformFile>) onFinish;

  const FinishTaskDialog({
    super.key,
    required this.tarea,
    required this.onFinish,
  });

  @override
  State<FinishTaskDialog> createState() => _FinishTaskDialogState();

  /// Método estático para mostrar el diálogo
  static Future<bool?> show(
    BuildContext context, {
    required Tarea tarea,
    required Future<bool> Function(String?, List<PlatformFile>) onFinish,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FinishTaskDialog(
        tarea: tarea,
        onFinish: onFinish,
      ),
    );
  }
}

class _FinishTaskDialogState extends State<FinishTaskDialog> {
  final _evidenciaController = TextEditingController();
  List<PlatformFile> _attachedFiles = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _evidenciaController.dispose();
    super.dispose();
  }

  Future<void> _handleFinish() async {
    // Validar que haya al menos una descripción o un archivo
    if (_evidenciaController.text.trim().isEmpty && _attachedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Proporciona al menos una descripción o un archivo como evidencia'),
          backgroundColor: AppTheme.warningOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await widget.onFinish(
        _evidenciaController.text.trim().isNotEmpty 
            ? _evidenciaController.text.trim() 
            : null,
        _attachedFiles,
      );

      if (!mounted) return;

      Navigator.of(context).pop(success);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF192233) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF4F6F8) : const Color(0xFF212529);
    final textSecondary = isDark ? const Color(0xFF92a4c9) : const Color(0xFF6C757D);
    final borderColor = isDark ? const Color(0xFF324467) : const Color(0xFFE0E0E0);

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.successGreen, AppTheme.successGreen.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Finalizar Tarea',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.tarea.titulo,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mensaje de confirmación
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.successGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.successGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Agrega evidencias del trabajo realizado para completar esta tarea.',
                              style: TextStyle(
                                fontSize: 13,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Campo de descripción de evidencia
                    Text(
                      'Descripción del trabajo realizado',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _evidenciaController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe brevemente el trabajo realizado...',
                        hintStyle: TextStyle(color: textSecondary.withOpacity(0.7)),
                        filled: true,
                        fillColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.successGreen, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Widget de archivos de evidencia
                    FileAttachmentWidget(
                      selectedFiles: _attachedFiles,
                      onFilesChanged: (files) {
                        setState(() => _attachedFiles = files);
                      },
                      title: 'Archivos de Evidencia',
                      hint: 'Adjuntar fotos, documentos o archivos',
                      maxFiles: 10,
                    ),
                  ],
                ),
              ),
            ),

            // Footer con botones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: borderColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondary,
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleFinish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: AppTheme.successGreen.withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.check_circle, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Finalizar Tarea',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
