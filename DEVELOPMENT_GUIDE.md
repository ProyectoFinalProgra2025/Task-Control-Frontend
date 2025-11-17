# 🚀 Guía de Extensión - Agregar Nuevas Funcionalidades

Esta guía te ayudará a agregar nuevas funcionalidades a la app Flutter de TaskControl.

## 📋 Índice
1. [Agregar un Nuevo Endpoint](#agregar-un-nuevo-endpoint)
2. [Crear una Nueva Pantalla](#crear-una-nueva-pantalla)
3. [Agregar Modelos de Datos](#agregar-modelos-de-datos)
4. [Implementar Gestión de Estado](#implementar-gestión-de-estado)
5. [Agregar Navegación](#agregar-navegación)

---

## 1. Agregar un Nuevo Endpoint

### Ejemplo: Obtener Lista de Tareas

**Paso 1**: Actualizar `api_config.dart`

```dart
// lib/config/api_config.dart
class ApiConfig {
  // ... código existente ...
  
  // Agregar nuevo endpoint
  static String tareasUsuario(int usuarioId) => '/api/Tareas/usuario/$usuarioId';
  static String tareaDetalle(int tareaId) => '/api/Tareas/$tareaId';
}
```

**Paso 2**: Crear modelo de Tarea

```dart
// lib/models/tarea_model.dart
class TareaModel {
  final int id;
  final String titulo;
  final String? descripcion;
  final String estado; // Pending, InProgress, Completed
  final String prioridad; // Low, Medium, High
  final DateTime? fechaVencimiento;
  final int? asignadoA;
  final String? nombreAsignado;

  TareaModel({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.estado,
    required this.prioridad,
    this.fechaVencimiento,
    this.asignadoA,
    this.nombreAsignado,
  });

  factory TareaModel.fromJson(Map<String, dynamic> json) {
    return TareaModel(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'],
      estado: json['estado'] ?? 'Pending',
      prioridad: json['prioridad'] ?? 'Medium',
      fechaVencimiento: json['fechaVencimiento'] != null
          ? DateTime.parse(json['fechaVencimiento'])
          : null,
      asignadoA: json['asignadoA'],
      nombreAsignado: json['nombreAsignado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'estado': estado,
      'prioridad': prioridad,
      'fechaVencimiento': fechaVencimiento?.toIso8601String(),
      'asignadoA': asignadoA,
      'nombreAsignado': nombreAsignado,
    };
  }
}
```

**Paso 3**: Crear servicio de Tareas

```dart
// lib/services/tarea_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/tarea_model.dart';
import 'storage_service.dart';

class TareaService {
  final StorageService _storage = StorageService();

  Future<List<TareaModel>> getTareasUsuario(int usuarioId) async {
    final token = await _storage.getAccessToken();
    if (token == null) throw Exception('No autenticado');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tareasUsuario(usuarioId)}');
    
    final response = await http.get(
      url,
      headers: ApiConfig.headersWithAuth(token),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> tareasJson = jsonResponse['data'] ?? [];
      return tareasJson.map((json) => TareaModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener tareas: ${response.statusCode}');
    }
  }

  Future<TareaModel> getTareaDetalle(int tareaId) async {
    final token = await _storage.getAccessToken();
    if (token == null) throw Exception('No autenticado');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tareaDetalle(tareaId)}');
    
    final response = await http.get(
      url,
      headers: ApiConfig.headersWithAuth(token),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return TareaModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Error al obtener tarea: ${response.statusCode}');
    }
  }

  Future<void> actualizarEstadoTarea(int tareaId, String nuevoEstado) async {
    final token = await _storage.getAccessToken();
    if (token == null) throw Exception('No autenticado');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tareaDetalle(tareaId)}/estado');
    
    final response = await http.put(
      url,
      headers: ApiConfig.headersWithAuth(token),
      body: jsonEncode({'estado': nuevoEstado}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar tarea: ${response.statusCode}');
    }
  }
}
```

---

## 2. Crear una Nueva Pantalla

### Ejemplo: Pantalla de Lista de Tareas

```dart
// lib/screens/tareas_list_screen.dart
import 'package:flutter/material.dart';
import '../models/tarea_model.dart';
import '../services/tarea_service.dart';
import '../services/storage_service.dart';

class TareasListScreen extends StatefulWidget {
  const TareasListScreen({super.key});

  @override
  State<TareasListScreen> createState() => _TareasListScreenState();
}

class _TareasListScreenState extends State<TareasListScreen> {
  final TareaService _tareaService = TareaService();
  final StorageService _storage = StorageService();
  
  List<TareaModel> _tareas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTareas();
  }

  Future<void> _loadTareas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userData = await _storage.getUserData();
      final usuarioId = userData?['id'] ?? 0;
      
      final tareas = await _tareaService.getTareasUsuario(usuarioId);
      
      setState(() {
        _tareas = tareas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar tareas: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navegar a crear tarea
        },
        backgroundColor: const Color(0xFF4F46E5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTareas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_tareas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tienes tareas asignadas',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTareas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tareas.length,
        itemBuilder: (context, index) {
          return _buildTareaCard(_tareas[index]);
        },
      ),
    );
  }

  Widget _buildTareaCard(TareaModel tarea) {
    Color estadoColor;
    IconData estadoIcon;

    switch (tarea.estado) {
      case 'Completed':
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        break;
      case 'InProgress':
        estadoColor = Colors.blue;
        estadoIcon = Icons.work;
        break;
      default:
        estadoColor = Colors.orange;
        estadoIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: estadoColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(estadoIcon, color: estadoColor),
        ),
        title: Text(
          tarea.titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tarea.descripcion != null) ...[
              const SizedBox(height: 4),
              Text(
                tarea.descripcion!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChip(
                  tarea.prioridad,
                  _getPrioridadColor(tarea.prioridad),
                ),
                const SizedBox(width: 8),
                if (tarea.fechaVencimiento != null)
                  _buildChip(
                    _formatFecha(tarea.fechaVencimiento!),
                    Colors.grey,
                  ),
              ],
            ),
          ],
        ),
        onTap: () {
          // TODO: Navegar a detalle de tarea
          Navigator.pushNamed(
            context,
            '/tarea-detalle',
            arguments: tarea.id,
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getPrioridadColor(String prioridad) {
    switch (prioridad) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final difference = fecha.difference(now).inDays;
    
    if (difference == 0) return 'Hoy';
    if (difference == 1) return 'Mañana';
    if (difference < 0) return 'Vencida';
    
    return '${difference}d';
  }
}
```

---

## 3. Implementar Provider para Estado Global

Si necesitas gestión de estado más avanzada, instala Provider:

```yaml
# pubspec.yaml
dependencies:
  provider: ^6.1.1
```

```dart
// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();
  
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final isAuth = await _storage.isAuthenticated();
    if (isAuth) {
      final userData = await _storage.getUserData();
      if (userData != null) {
        _currentUser = UserModel.fromJson(userData);
        _isAuthenticated = true;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final authResponse = await _authService.login(email, password);
      _currentUser = authResponse.usuario;
      _isAuthenticated = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
```

**Uso en main.dart:**

```dart
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const TaskControlApp(),
    ),
  );
}
```

**Uso en widgets:**

```dart
// Obtener datos
final authProvider = Provider.of<AuthProvider>(context);
final user = authProvider.currentUser;

// O usando Consumer
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    return Text(authProvider.currentUser?.nombreCompleto ?? '');
  },
)
```

---

## 4. Agregar Rutas con Argumentos

```dart
// En main.dart
routes: {
  '/tareas': (context) => const TareasListScreen(),
  '/tarea-detalle': (context) => const TareaDetalleScreen(),
},

onGenerateRoute: (settings) {
  if (settings.name == '/tarea-detalle') {
    final tareaId = settings.arguments as int;
    return MaterialPageRoute(
      builder: (context) => TareaDetalleScreen(tareaId: tareaId),
    );
  }
  return null;
},
```

**Navegación:**

```dart
// Con argumentos
Navigator.pushNamed(context, '/tarea-detalle', arguments: tareaId);

// Recibir argumentos
class TareaDetalleScreen extends StatelessWidget {
  final int tareaId;
  
  const TareaDetalleScreen({super.key, required this.tareaId});
  
  @override
  Widget build(BuildContext context) {
    // Usar tareaId
  }
}
```

---

## 5. Agregar Filtros y Búsqueda

```dart
// En TareasListScreen
String _searchQuery = '';
String _filtroEstado = 'Todos';

List<TareaModel> get _tareasFiltradas {
  var tareas = _tareas;
  
  // Filtro por búsqueda
  if (_searchQuery.isNotEmpty) {
    tareas = tareas.where((t) => 
      t.titulo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (t.descripcion?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }
  
  // Filtro por estado
  if (_filtroEstado != 'Todos') {
    tareas = tareas.where((t) => t.estado == _filtroEstado).toList();
  }
  
  return tareas;
}

// En AppBar
AppBar(
  title: TextField(
    decoration: const InputDecoration(
      hintText: 'Buscar tareas...',
      border: InputBorder.none,
    ),
    onChanged: (value) {
      setState(() {
        _searchQuery = value;
      });
    },
  ),
  actions: [
    PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list),
      onSelected: (value) {
        setState(() {
          _filtroEstado = value;
        });
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Todos', child: Text('Todos')),
        const PopupMenuItem(value: 'Pending', child: Text('Pendientes')),
        const PopupMenuItem(value: 'InProgress', child: Text('En Progreso')),
        const PopupMenuItem(value: 'Completed', child: Text('Completadas')),
      ],
    ),
  ],
)
```

---

## 6. Agregar Notificaciones Locales

```yaml
# pubspec.yaml
dependencies:
  flutter_local_notifications: ^16.3.0
```

```dart
// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'taskcontrol_channel',
      'TaskControl',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(0, title, body, details);
  }
}
```

---

## 📚 Recursos Adicionales

- [Flutter Documentation](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [HTTP Package](https://pub.dev/packages/http)
- [Shared Preferences](https://pub.dev/packages/shared_preferences)

---

**¡Feliz desarrollo! 🚀**
