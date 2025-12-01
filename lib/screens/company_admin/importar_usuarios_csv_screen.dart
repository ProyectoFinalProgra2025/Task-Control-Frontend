import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../services/usuario_service.dart';
import '../../models/importar_usuarios_resultado.dart';

/// Estados del proceso de importación
enum ImportState { initial, fileSelected, processing, completed }

class ImportarUsuariosCsvScreen extends StatefulWidget {
  const ImportarUsuariosCsvScreen({super.key});

  @override
  State<ImportarUsuariosCsvScreen> createState() =>
      _ImportarUsuariosCsvScreenState();
}

class _ImportarUsuariosCsvScreenState extends State<ImportarUsuariosCsvScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  final TextEditingController _passwordController = TextEditingController();

  PlatformFile? _selectedFile;
  bool _isLoading = false;
  bool _useDefaultPassword = false;
  ImportarUsuariosResultado? _resultado;
  String? _error;

  ImportState _currentState = ImportState.initial;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _currentState = ImportState.fileSelected;
          _error = null;
          _resultado = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al seleccionar archivo: $e';
      });
    }
  }

  Future<void> _importarUsuarios() async {
    if (_selectedFile == null) return;

    setState(() {
      _isLoading = true;
      _currentState = ImportState.processing;
      _error = null;
    });

    try {
      final resultado = await _usuarioService.importarUsuariosCsv(
        _selectedFile!,
        passwordPorDefecto:
            _useDefaultPassword ? _passwordController.text : null,
      );

      setState(() {
        _resultado = resultado;
        _currentState = ImportState.completed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _currentState = ImportState.fileSelected;
      });
    }
  }

  Future<void> _descargarPlantilla() async {
    const plantillaUrl = 'https://taskcontrolstorage.blob.core.windows.net/test/Libro1.csv';
    
    try {
      if (kIsWeb) {
        // En web, abrir la URL directamente para descargar
        // ignore: avoid_web_libraries_in_flutter
        await launchUrl(Uri.parse(plantillaUrl), mode: LaunchMode.externalApplication);
      } else {
        // En móvil/desktop, descargar el archivo desde la URL
        final response = await http.get(Uri.parse(plantillaUrl));
        
        if (response.statusCode == 200) {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/plantilla_usuarios.csv');
          await file.writeAsBytes(response.bodyBytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Plantilla guardada en: ${file.path}')),
            );
          }
        } else {
          throw Exception('Error al descargar: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _reiniciar() {
    setState(() {
      _selectedFile = null;
      _resultado = null;
      _error = null;
      _currentState = ImportState.initial;
      _passwordController.clear();
      _useDefaultPassword = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF101622) : const Color(0xFFf6f6f8);
    final cardColor = isDark ? const Color(0xFF192233) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary =
        isDark ? const Color(0xFF92a4c9) : const Color(0xFF64748b);
    final borderColor =
        isDark ? const Color(0xFF324467) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Importar Usuarios',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: textPrimary),
        actions: [
          TextButton.icon(
            onPressed: _descargarPlantilla,
            icon: Icon(Icons.download, color: textSecondary, size: 20),
            label: Text('Plantilla', style: TextStyle(color: textSecondary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instrucciones
            _buildInstructionsCard(cardColor, textPrimary, textSecondary, borderColor),
            const SizedBox(height: 16),

            // Área de selección de archivo
            _buildFilePickerCard(
                cardColor, textPrimary, textSecondary, borderColor, isDark),
            const SizedBox(height: 16),

            // Opciones de contraseña
            if (_currentState == ImportState.fileSelected ||
                _currentState == ImportState.processing)
              _buildPasswordOptions(
                  cardColor, textPrimary, textSecondary, borderColor, isDark),

            // Resultado de la importación
            if (_resultado != null)
              _buildResultCard(
                  cardColor, textPrimary, textSecondary, borderColor, isDark),

            // Error
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(isDark),
    );
  }

  Widget _buildInstructionsCard(
      Color cardColor, Color textPrimary, Color textSecondary, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF135BEC).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF135BEC).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF135BEC).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline,
                    color: Color(0xFF135BEC), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Formato del CSV',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF135BEC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'El archivo CSV debe contener las siguientes columnas:',
            style: TextStyle(color: Color(0xFF135BEC)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColumnChip('Email *', true),
              _buildColumnChip('NombreCompleto *', true),
              _buildColumnChip('Telefono', false),
              _buildColumnChip('Rol', false),
              _buildColumnChip('Departamento', false),
              _buildColumnChip('NivelHabilidad', false),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '* Campos requeridos. Rol puede ser "Usuario" o "ManagerDepartamento".',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF135BEC).withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnChip(String label, bool required) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: required
            ? const Color(0xFF135BEC).withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: required ? FontWeight.bold : FontWeight.normal,
          color: required ? const Color(0xFF135BEC) : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildFilePickerCard(Color cardColor, Color textPrimary,
      Color textSecondary, Color borderColor, bool isDark) {
    return InkWell(
      onTap: _isLoading ? null : _pickCsvFile,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedFile != null
                ? const Color(0xFF10B981)
                : borderColor,
            width: _selectedFile != null ? 2 : 1,
            style: _selectedFile == null ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedFile != null
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : isDark
                        ? const Color(0xFF324467).withOpacity(0.3)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                _selectedFile != null
                    ? Icons.check_circle
                    : Icons.upload_file,
                size: 48,
                color: _selectedFile != null
                    ? const Color(0xFF10B981)
                    : textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedFile != null) ...[
              Text(
                _selectedFile!.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _formatFileSize(_selectedFile!.size),
                style: TextStyle(fontSize: 14, color: textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _pickCsvFile,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Cambiar archivo'),
              ),
            ] else ...[
              Text(
                'Seleccionar archivo CSV',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Toca aquí para buscar en tus archivos',
                style: TextStyle(fontSize: 14, color: textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordOptions(Color cardColor, Color textPrimary,
      Color textSecondary, Color borderColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Opciones de contraseña',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _useDefaultPassword,
            onChanged: (value) {
              setState(() {
                _useDefaultPassword = value;
                if (!value) _passwordController.clear();
              });
            },
            title: Text(
              'Usar contraseña por defecto',
              style: TextStyle(fontSize: 14, color: textPrimary),
            ),
            subtitle: Text(
              'Si no se activa, se generará una contraseña aleatoria para cada usuario',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFF135BEC),
          ),
          if (_useDefaultPassword) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              onChanged: (value) {
                // Trigger rebuild to update button state
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Contraseña por defecto',
                hintText: 'Mínimo 8 caracteres',
                prefixIcon: const Icon(Icons.password),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF324467).withOpacity(0.3)
                    : Colors.grey.shade50,
                suffixIcon: _passwordController.text.length >= 8
                    ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                    : null,
              ),
              style: TextStyle(color: textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              _passwordController.text.isEmpty
                  ? 'Ingresa una contraseña de al menos 8 caracteres'
                  : _passwordController.text.length < 8
                      ? 'Faltan ${8 - _passwordController.text.length} caracteres'
                      : '✓ Contraseña válida',
              style: TextStyle(
                fontSize: 12,
                color: _passwordController.text.length >= 8
                    ? const Color(0xFF10B981)
                    : textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(Color cardColor, Color textPrimary,
      Color textSecondary, Color borderColor, bool isDark) {
    final resultado = _resultado!;
    final isSuccess = resultado.fallidos == 0;
    final hasPartialSuccess =
        resultado.exitosos > 0 && resultado.fallidos > 0;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con resumen
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSuccess
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : hasPartialSuccess
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? const Color(0xFF10B981).withOpacity(0.2)
                        : hasPartialSuccess
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    isSuccess
                        ? Icons.check_circle
                        : hasPartialSuccess
                            ? Icons.warning_amber_rounded
                            : Icons.error,
                    size: 32,
                    color: isSuccess
                        ? const Color(0xFF10B981)
                        : hasPartialSuccess
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSuccess
                            ? '¡Importación exitosa!'
                            : hasPartialSuccess
                                ? 'Importación parcial'
                                : 'Error en la importación',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSuccess
                              ? const Color(0xFF10B981)
                              : hasPartialSuccess
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${resultado.exitosos} de ${resultado.totalProcesados} usuarios creados',
                        style: TextStyle(fontSize: 14, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Estadísticas
          Row(
            children: [
              _buildStatCard(
                'Total',
                resultado.totalProcesados.toString(),
                Icons.people,
                const Color(0xFF135BEC),
                isDark,
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                'Exitosos',
                resultado.exitosos.toString(),
                Icons.check_circle,
                const Color(0xFF10B981),
                isDark,
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                'Fallidos',
                resultado.fallidos.toString(),
                Icons.cancel,
                Colors.red,
                isDark,
              ),
            ],
          ),

          // Detalles de errores si los hay
          if (resultado.conErrores.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Errores encontrados:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: resultado.conErrores.length,
                itemBuilder: (context, index) {
                  final error = resultado.conErrores[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Fila ${error.fila}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                error.email.isNotEmpty
                                    ? error.email
                                    : 'Email vacío',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                error.error ?? 'Error desconocido',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          // Usuarios creados con contraseñas generadas
          if (resultado.creados
              .any((u) => u.passwordGenerado != null)) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Se generaron contraseñas aleatorias para los usuarios. Revisa los detalles para anotarlas.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              title: Text(
                'Ver contraseñas generadas',
                style: TextStyle(fontSize: 14, color: textPrimary),
              ),
              children: resultado.creados
                  .where((u) => u.passwordGenerado != null)
                  .map((u) => ListTile(
                        dense: true,
                        title: Text(u.email,
                            style: TextStyle(
                                fontSize: 13, color: textPrimary)),
                        subtitle: Text(
                          'Contraseña: ${u.passwordGenerado}',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildBottomActions(bool isDark) {
    if (_currentState == ImportState.initial) return null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192233) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentState == ImportState.completed)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reiniciar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Nueva importación'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF135BEC)),
                  ),
                ),
              )
            else ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _reiniciar,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ||
                          (_useDefaultPassword &&
                              _passwordController.text.length < 8)
                      ? null
                      : _importarUsuarios,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.upload, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Importando...' : 'Importar usuarios',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135BEC),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor:
                        const Color(0xFF135BEC).withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
