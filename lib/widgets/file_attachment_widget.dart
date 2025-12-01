import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../config/theme_config.dart';
import '../services/file_upload_service.dart';

/// Widget para seleccionar y mostrar archivos adjuntos
class FileAttachmentWidget extends StatefulWidget {
  final List<PlatformFile> selectedFiles;
  final Function(List<PlatformFile>) onFilesChanged;
  final bool allowMultiple;
  final int maxFiles;
  final String title;
  final String hint;
  final FileType fileType;
  final bool showUploadedFiles;
  final List<AttachedFileInfo>? uploadedFiles;
  final Function(String)? onDeleteUploadedFile;

  const FileAttachmentWidget({
    super.key,
    required this.selectedFiles,
    required this.onFilesChanged,
    this.allowMultiple = true,
    this.maxFiles = 5,
    this.title = 'Archivos Adjuntos',
    this.hint = 'Toca para seleccionar archivos',
    this.fileType = FileType.any,
    this.showUploadedFiles = false,
    this.uploadedFiles,
    this.onDeleteUploadedFile,
  });

  @override
  State<FileAttachmentWidget> createState() => _FileAttachmentWidgetState();
}

class _FileAttachmentWidgetState extends State<FileAttachmentWidget> {
  final FileUploadService _fileService = FileUploadService();

  Future<void> _pickFiles() async {
    if (widget.allowMultiple) {
      final files = await _fileService.pickMultipleFiles(type: widget.fileType);
      if (files.isNotEmpty) {
        final newFiles = [...widget.selectedFiles, ...files];
        // Limitar a maxFiles
        final limitedFiles = newFiles.take(widget.maxFiles).toList();
        widget.onFilesChanged(limitedFiles);
      }
    } else {
      final file = await _fileService.pickFile(type: widget.fileType);
      if (file != null) {
        widget.onFilesChanged([file]);
      }
    }
  }

  void _removeFile(int index) {
    final newFiles = List<PlatformFile>.from(widget.selectedFiles);
    newFiles.removeAt(index);
    widget.onFilesChanged(newFiles);
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF192233) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF4F6F8) : const Color(0xFF212529);
    final textSecondary = isDark ? const Color(0xFF92a4c9) : const Color(0xFF6C757D);
    final borderColor = isDark ? const Color(0xFF324467) : const Color(0xFFE0E0E0);

    final totalFiles = widget.selectedFiles.length + (widget.uploadedFiles?.length ?? 0);
    final canAddMore = totalFiles < widget.maxFiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.attach_file,
              size: 20,
              color: textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
            if (widget.maxFiles > 1) ...[
              const Spacer(),
              Text(
                '$totalFiles/${widget.maxFiles}',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // Uploaded files (si se muestran)
        if (widget.showUploadedFiles && widget.uploadedFiles != null)
          ...widget.uploadedFiles!.map((file) => _buildUploadedFileItem(
                file,
                isDark,
                textPrimary,
                textSecondary,
                borderColor,
              )),

        // Selected files list
        ...widget.selectedFiles.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;
          return _buildFileItem(
            file,
            index,
            isDark,
            textPrimary,
            textSecondary,
            borderColor,
          );
        }),

        // Add file button
        if (canAddMore)
          InkWell(
            onTap: _pickFiles,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border.all(
                  color: borderColor,
                  width: 1,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: AppTheme.primaryBlue,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.hint,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFileItem(
    PlatformFile file,
    int index,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    final extension = _getExtension(file.name);
    final fileColor = _getFileColor(extension);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: fileColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(extension),
              color: fileColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  FileUploadService.formatFileSize(file.size),
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeFile(index),
            icon: Icon(
              Icons.close,
              color: textSecondary,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedFileItem(
    AttachedFileInfo file,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    final extension = _getExtension(file.nombreArchivo);
    final fileColor = _getFileColor(extension);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successGreen.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: fileColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(extension),
              color: fileColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.nombreArchivo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: AppTheme.successGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Subido',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.onDeleteUploadedFile != null)
            IconButton(
              onPressed: () => widget.onDeleteUploadedFile!(file.id),
              icon: Icon(
                Icons.delete_outline,
                color: AppTheme.dangerRed,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }
}

/// Info de archivo ya subido
class AttachedFileInfo {
  final String id;
  final String nombreArchivo;
  final String archivoUrl;
  final String? tipoMime;
  final int? tamanoBytes;

  AttachedFileInfo({
    required this.id,
    required this.nombreArchivo,
    required this.archivoUrl,
    this.tipoMime,
    this.tamanoBytes,
  });
}
