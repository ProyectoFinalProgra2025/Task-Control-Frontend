import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../models/capacidad_nivel_item.dart';
import '../services/usuario_service.dart';

class UsuarioProvider extends ChangeNotifier {
  final UsuarioService _usuarioService = UsuarioService();

  Usuario? _usuario;
  bool _isLoading = false;
  String? _error;

  Usuario? get usuario => _usuario;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<CapacidadUsuario> get capacidades => _usuario?.capacidades ?? [];

  /// Cargar datos del usuario autenticado
  Future<void> cargarPerfil() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _usuario = await _usuarioService.getMe();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _usuario = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualizar mis capacidades
  Future<bool> actualizarMisCapacidades(List<CapacidadNivelItem> capacidades) async {
    try {
      await _usuarioService.updateMisCapacidades(capacidades);
      // Recargar perfil para obtener datos actualizados
      await cargarPerfil();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Eliminar una capacidad del perfil
  Future<bool> eliminarCapacidad(String capacidadId) async {
    try {
      await _usuarioService.deleteMiCapacidad(capacidadId);
      // Actualizar localmente
      if (_usuario != null) {
        _usuario = Usuario(
          id: _usuario!.id,
          email: _usuario!.email,
          nombreCompleto: _usuario!.nombreCompleto,
          telefono: _usuario!.telefono,
          rol: _usuario!.rol,
          empresaId: _usuario!.empresaId,
          departamento: _usuario!.departamento,
          nivelHabilidad: _usuario!.nivelHabilidad,
          isActive: _usuario!.isActive,
          capacidades: _usuario!.capacidades
              .where((c) => c.capacidadId != capacidadId)
              .toList(),
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Agregar una nueva capacidad
  Future<bool> agregarCapacidad(CapacidadNivelItem capacidad) async {
    try {
      // Obtener las capacidades actuales
      final capacidadesActuales = _usuario?.capacidades
              .map((c) => CapacidadNivelItem(nombre: c.nombre, nivel: c.nivel))
              .toList() ??
          [];

      // Agregar la nueva capacidad
      capacidadesActuales.add(capacidad);

      // Actualizar en el backend
      await _usuarioService.updateMisCapacidades(capacidadesActuales);

      // Recargar perfil silenciosamente (sin cambiar isLoading)
      await _recargarPerfilSilencioso();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Agregar múltiples capacidades de una sola vez
  Future<bool> agregarCapacidadesMultiples(List<CapacidadNivelItem> nuevasCapacidades) async {
    try {
      // Obtener las capacidades actuales
      final capacidadesActuales = _usuario?.capacidades
              .map((c) => CapacidadNivelItem(nombre: c.nombre, nivel: c.nivel))
              .toList() ??
          [];

      // Agregar todas las nuevas capacidades
      capacidadesActuales.addAll(nuevasCapacidades);

      // Actualizar en el backend de una sola vez
      await _usuarioService.updateMisCapacidades(capacidadesActuales);

      // Recargar perfil silenciosamente (sin cambiar isLoading)
      await _recargarPerfilSilencioso();
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Recargar perfil sin activar el estado de loading (para actualizaciones en background)
  Future<void> _recargarPerfilSilencioso() async {
    try {
      _usuario = await _usuarioService.getMe();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Limpiar errores
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refrescar perfil
  Future<void> refresh() async {
    await cargarPerfil();
  }
}
