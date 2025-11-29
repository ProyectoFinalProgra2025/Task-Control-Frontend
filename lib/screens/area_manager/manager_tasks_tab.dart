import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/tarea_provider.dart';
import '../../providers/admin_tarea_provider.dart';
import '../../providers/realtime_provider.dart';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';
import '../../models/enums/prioridad_tarea.dart';
import '../../config/theme_config.dart';
import '../../services/storage_service.dart';
import '../../widgets/task/task_widgets.dart';
import 'manager_task_detail_screen.dart';

/// ManagerTasksTab - Pantalla híbrida de tareas para Area Manager
/// 
/// Tab "Mis Tareas": Estilo worker con botón de aceptar para tareas asignadas
/// Tab "Departamento": Estilo admin con 4 sub-tabs (Todas, Pendientes, En Progreso, Completadas)
class ManagerTasksTab extends StatefulWidget {
  const ManagerTasksTab({super.key});

  @override
  State<ManagerTasksTab> createState() => _ManagerTasksTabState();
}

class _ManagerTasksTabState extends State<ManagerTasksTab> with TickerProviderStateMixin {
  final StorageService _storage = StorageService();
  
  // Main tabs: Mis Tareas / Departamento
  late TabController _mainTabController;
  
  // Sub-tabs for Departamento: Todas / Pendientes / En Progreso / Completadas
  late TabController _deptTabController;
  
  // Filters
  PrioridadTarea? _filtroPrioridad;
  String? _searchQuery;
  
  StreamSubscription? _tareaEventSubscription;
  bool _isAcceptingTask = false;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _deptTabController = TabController(length: 4, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
      _connectRealtime();
      _subscribeToRealtimeEvents();
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _deptTabController.dispose();
    _tareaEventSubscription?.cancel();
    super.dispose();
  }
  
  Future<void> _loadAllData() async {
    // Cargar MIS tareas (asignadas a mí)
    Provider.of<TareaProvider>(context, listen: false).cargarMisTareas();
    // Cargar TODAS las tareas del departamento
    Provider.of<AdminTareaProvider>(context, listen: false).cargarTodasLasTareas();
  }
  
  Future<void> _connectRealtime() async {
    try {
      final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);
      final empresaId = await _storage.getEmpresaId();
      if (empresaId != null) {
        await realtimeProvider.connect(empresaId: empresaId);
      }
    } catch (e) {
      debugPrint('Error connecting to realtime: $e');
    }
  }
  
  void _subscribeToRealtimeEvents() {
    final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);
    
    _tareaEventSubscription = realtimeProvider.tareaEventStream.listen((event) {
      debugPrint('📋 Manager Tasks: Tarea event received: ${event['action']}');
      _loadAllData();
      
      if (mounted) {
        final action = event['action'] ?? '';
        String message = '';
        if (action == 'tarea:created') {
          message = 'Nueva tarea creada';
        } else if (action == 'tarea:assigned') {
          message = 'Tarea asignada';
        } else if (action == 'tarea:accepted') {
          message = 'Tarea aceptada';
        } else if (action == 'tarea:completed') {
          message = 'Tarea completada';
        }
        
        if (message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Premium Header
            _buildHeader(isDark),
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _mainTabController,
                children: [
                  _buildMisTareasTab(),
                  _buildDepartamentoTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.successGreen, Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Gestión de Tareas',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supervisa tu trabajo y el de tu departamento',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Search Button
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
                ),
                child: IconButton(
                  icon: Icon(Icons.search_rounded, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                  onPressed: () => _showSearchDialog(isDark),
                ),
              ),
              const SizedBox(width: 8),
              // Filter Button
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
                ),
                child: IconButton(
                  icon: Icon(Icons.filter_list_rounded, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                  onPressed: () => _showFiltersSheet(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Main Tab Bar: Mis Tareas / Departamento
          Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.grey[100])?.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _mainTabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.successGreen, Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: '👤 Mis Tareas'),
                Tab(text: '👥 Departamento'),
              ],
            ),
          ),
          // Active Filters Chips
          if (_filtroPrioridad != null || _searchQuery != null) ...[
            const SizedBox(height: 12),
            _buildActiveFiltersChips(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_searchQuery != null)
          _buildFilterChip(
            isDark,
            icon: Icons.search,
            label: 'Búsqueda: "$_searchQuery"',
            onRemove: () => setState(() => _searchQuery = null),
          ),
        if (_filtroPrioridad != null)
          _buildFilterChip(
            isDark,
            icon: Icons.flag_outlined,
            label: 'Prioridad: ${_filtroPrioridad!.name}',
            onRemove: () => setState(() => _filtroPrioridad = null),
          ),
      ],
    );
  }

  Widget _buildFilterChip(bool isDark, {required IconData icon, required String label, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.successGreen),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: AppTheme.successGreen),
          ),
        ],
      ),
    );
  }

  // ===== TAB 1: MIS TAREAS (Worker Style) =====
  Widget _buildMisTareasTab() {
    return Consumer<TareaProvider>(
      builder: (context, tareaProvider, child) {
        if (tareaProvider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.successGreen));
        }

        if (tareaProvider.error != null) {
          return _buildErrorWidget(
            tareaProvider.error!,
            () => tareaProvider.cargarMisTareas(),
          );
        }

        List<Tarea> tareas = tareaProvider.misTareas;
        
        // Apply filters
        if (_filtroPrioridad != null) {
          tareas = tareas.where((t) => t.prioridad == _filtroPrioridad).toList();
        }
        if (_searchQuery != null && _searchQuery!.isNotEmpty) {
          final query = _searchQuery!.toLowerCase();
          tareas = tareas.where((t) => 
            t.titulo.toLowerCase().contains(query) ||
            t.descripcion.toLowerCase().contains(query)
          ).toList();
        }

        if (tareas.isEmpty) {
          return _buildEmptyWidget(
            icon: Icons.check_circle_outline_rounded,
            title: 'Sin tareas personales',
            subtitle: 'No tienes tareas asignadas en este momento',
          );
        }

        return RefreshIndicator(
          color: AppTheme.successGreen,
          onRefresh: () => tareaProvider.cargarMisTareas(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tareas.length,
            itemBuilder: (context, index) => _buildWorkerTaskCard(tareas[index]),
          ),
        );
      },
    );
  }

  Widget _buildWorkerTaskCard(Tarea tarea) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool canAccept = tarea.estado == EstadoTarea.asignada;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TaskCard(
        tarea: tarea,
        style: TaskCardStyle.worker,
        accentColor: AppTheme.successGreen,
        showSkills: true,
        showAssignee: false,
        showDueDate: true,
        showProgressIndicator: true,
        trailing: canAccept ? _buildAcceptButton(tarea, isDark) : null,
        onTap: () => _navigateToDetail(tarea),
      ),
    );
  }

  Widget _buildAcceptButton(Tarea tarea, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.successGreen, Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _isAcceptingTask ? null : () => _acceptTask(tarea),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _isAcceptingTask
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Aceptar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _acceptTask(Tarea tarea) async {
    setState(() => _isAcceptingTask = true);
    
    try {
      final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
      await tareaProvider.aceptarTarea(tarea.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('¡Tarea aceptada exitosamente!'),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        
        // Reload all data
        _loadAllData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aceptar: $e'),
            backgroundColor: AppTheme.dangerRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAcceptingTask = false);
      }
    }
  }

  // ===== TAB 2: DEPARTAMENTO (Admin Style with Sub-tabs) =====
  Widget _buildDepartamentoTab(bool isDark) {
    return Column(
      children: [
        // Sub-tabs
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.grey[100])?.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _deptTabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.successGreen.withOpacity(0.5)),
            ),
            labelColor: AppTheme.successGreen,
            unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Todas'),
              Tab(text: 'Pendientes'),
              Tab(text: 'En Progreso'),
              Tab(text: 'Completadas'),
            ],
          ),
        ),
        // Sub-tab views
        Expanded(
          child: TabBarView(
            controller: _deptTabController,
            children: [
              _buildDeptTaskList(null), // Todas
              _buildDeptTaskList(EstadoTarea.pendiente), // Pendientes (includes asignada)
              _buildDeptTaskList(EstadoTarea.aceptada), // En Progreso
              _buildDeptTaskList(EstadoTarea.finalizada), // Completadas
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeptTaskList(EstadoTarea? filterEstado) {
    return Consumer<AdminTareaProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.successGreen));
        }

        if (adminProvider.error != null) {
          return _buildErrorWidget(
            adminProvider.error!,
            () => adminProvider.cargarTodasLasTareas(),
          );
        }

        List<Tarea> tareas = adminProvider.todasLasTareas;
        
        // Apply estado filter
        if (filterEstado != null) {
          if (filterEstado == EstadoTarea.pendiente) {
            // Pendientes includes both pendiente and asignada
            tareas = tareas.where((t) => 
              t.estado == EstadoTarea.pendiente || 
              t.estado == EstadoTarea.asignada
            ).toList();
          } else {
            tareas = tareas.where((t) => t.estado == filterEstado).toList();
          }
        }
        
        // Apply prioridad filter
        if (_filtroPrioridad != null) {
          tareas = tareas.where((t) => t.prioridad == _filtroPrioridad).toList();
        }
        
        // Apply search filter
        if (_searchQuery != null && _searchQuery!.isNotEmpty) {
          final query = _searchQuery!.toLowerCase();
          tareas = tareas.where((t) => 
            t.titulo.toLowerCase().contains(query) ||
            t.descripcion.toLowerCase().contains(query) ||
            (t.asignadoANombre?.toLowerCase().contains(query) ?? false)
          ).toList();
        }

        if (tareas.isEmpty) {
          return _buildEmptyWidget(
            icon: _getEmptyIcon(filterEstado),
            title: _getEmptyTitle(filterEstado),
            subtitle: _getEmptySubtitle(filterEstado),
          );
        }

        return RefreshIndicator(
          color: AppTheme.successGreen,
          onRefresh: () => adminProvider.cargarTodasLasTareas(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tareas.length,
            itemBuilder: (context, index) => _buildAdminTaskCard(tareas[index]),
          ),
        );
      },
    );
  }

  Widget _buildAdminTaskCard(Tarea tarea) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TaskCard(
        tarea: tarea,
        style: TaskCardStyle.premium,
        accentColor: AppTheme.successGreen,
        showSkills: true,
        showAssignee: true,
        showDueDate: true,
        showProgressIndicator: true,
        onTap: () => _navigateToDetail(tarea),
      ),
    );
  }

  Future<void> _navigateToDetail(Tarea tarea) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManagerTaskDetailScreen(tareaId: tarea.id),
      ),
    );
    if (result == true) {
      _loadAllData();
    }
  }

  // ===== EMPTY & ERROR WIDGETS =====
  IconData _getEmptyIcon(EstadoTarea? estado) {
    switch (estado) {
      case EstadoTarea.pendiente:
        return Icons.pending_actions_rounded;
      case EstadoTarea.aceptada:
        return Icons.engineering_rounded;
      case EstadoTarea.finalizada:
        return Icons.celebration_rounded;
      default:
        return Icons.folder_open_rounded;
    }
  }

  String _getEmptyTitle(EstadoTarea? estado) {
    switch (estado) {
      case EstadoTarea.pendiente:
        return 'Sin tareas pendientes';
      case EstadoTarea.aceptada:
        return 'Sin tareas en progreso';
      case EstadoTarea.finalizada:
        return 'Sin tareas completadas';
      default:
        return 'Sin tareas en el departamento';
    }
  }

  String _getEmptySubtitle(EstadoTarea? estado) {
    switch (estado) {
      case EstadoTarea.pendiente:
        return 'No hay tareas esperando asignación';
      case EstadoTarea.aceptada:
        return 'No hay trabajadores ejecutando tareas';
      case EstadoTarea.finalizada:
        return 'Aún no se han completado tareas';
      default:
        return 'Las tareas del departamento aparecerán aquí';
    }
  }

  Widget _buildEmptyWidget({required IconData icon, required String title, required String subtitle}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppTheme.successGreen),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.dangerRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 40, color: AppTheme.dangerRed),
            ),
            const SizedBox(height: 20),
            Text(
              'Error al cargar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== DIALOGS =====
  void _showSearchDialog(bool isDark) {
    final controller = TextEditingController(text: _searchQuery);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.search_rounded, color: AppTheme.successGreen),
            ),
            const SizedBox(width: 12),
            const Text('Buscar Tareas'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Título, descripción, asignado...',
            prefixIcon: const Icon(Icons.search_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? Colors.black.withOpacity(0.3) : Colors.grey[100],
          ),
          onSubmitted: (value) {
            setState(() => _searchQuery = value.isEmpty ? null : value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = null);
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _searchQuery = controller.text.isEmpty ? null : controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  void _showFiltersSheet(bool isDark) {
    PrioridadTarea? tempPrioridad = _filtroPrioridad;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.successGreen, Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.filter_list_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Priority Filter
              Text(
                'Prioridad',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPriorityFilterChip(
                    isDark,
                    label: 'Todas',
                    isSelected: tempPrioridad == null,
                    onTap: () => setSheetState(() => tempPrioridad = null),
                  ),
                  ...PrioridadTarea.values.map((p) => _buildPriorityFilterChip(
                    isDark,
                    label: p.name,
                    color: _getPriorityColor(p),
                    isSelected: tempPrioridad == p,
                    onTap: () => setSheetState(() => tempPrioridad = p),
                  )),
                ],
              ),
              const SizedBox(height: 32),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _filtroPrioridad = null;
                        });
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _filtroPrioridad = tempPrioridad;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Aplicar Filtros', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityFilterChip(bool isDark, {required String label, Color? color, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? (color ?? AppTheme.successGreen).withOpacity(0.15)
              : (isDark ? Colors.black.withOpacity(0.3) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected 
                ? (color ?? AppTheme.successGreen)
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected 
                ? (color ?? AppTheme.successGreen)
                : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(PrioridadTarea prioridad) {
    switch (prioridad) {
      case PrioridadTarea.high:
        return AppTheme.dangerRed;
      case PrioridadTarea.medium:
        return AppTheme.warningOrange;
      case PrioridadTarea.low:
        return AppTheme.successGreen;
    }
  }
}
