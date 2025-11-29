import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';
import '../../models/enums/prioridad_tarea.dart';
import '../../models/enums/departamento.dart';
import '../../services/tarea_service.dart';
import '../../config/theme_config.dart';
import '../../widgets/task/task_widgets.dart';
import 'admin_task_detail_screen.dart';
import '../../providers/realtime_provider.dart';
import '../../services/storage_service.dart';

class AdminTasksTab extends StatefulWidget {
  const AdminTasksTab({super.key});

  @override
  State<AdminTasksTab> createState() => _AdminTasksTabState();
}

class _AdminTasksTabState extends State<AdminTasksTab> with SingleTickerProviderStateMixin {
  final TareaService _tareaService = TareaService();
  final StorageService _storage = StorageService();
  List<Tarea> _tareas = [];
  bool _isLoading = true;
  String? _error;

  EstadoTarea? _selectedEstado;
  PrioridadTarea? _selectedPrioridad;
  Departamento? _selectedDepartamento;
  String _searchQuery = '';

  late TabController _tabController;
  final List<String> _tabs = ['Todas', 'Pendientes', 'En Progreso', 'Completadas'];
  
  StreamSubscription? _tareaEventSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadTareas();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectRealtime();
      _subscribeToRealtimeEvents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tareaEventSubscription?.cancel();
    super.dispose();
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
      debugPrint('📋 Admin Tasks: Tarea event received: ${event['action']}');
      _loadTareas(); // Reload task list
      
      if (mounted) {
        final action = event['action'] ?? '';
        String message = '';
        if (action == 'tarea:created') {
          message = 'Nueva tarea creada';
        } else if (action == 'tarea:assigned') {
          message = 'Tarea asignada a un trabajador';
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

  Future<void> _loadTareas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tareas = await _tareaService.getTareas(
        estado: _selectedEstado,
        prioridad: _selectedPrioridad,
        departamento: _selectedDepartamento,
      );

      if (mounted) {
        setState(() {
          _tareas = tareas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showFiltersDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FiltersSheet(
        selectedEstado: _selectedEstado,
        selectedPrioridad: _selectedPrioridad,
        selectedDepartamento: _selectedDepartamento,
        onApply: (estado, prioridad, departamento) {
          setState(() {
            _selectedEstado = estado;
            _selectedPrioridad = prioridad;
            _selectedDepartamento = departamento;
          });
          _loadTareas();
        },
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Buscar Tarea',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Título de la tarea...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _searchQuery = '');
                Navigator.of(context).pop();
              },
              child: const Text('Limpiar', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  List<Tarea> get _filteredTareas {
    var tareas = _tareas;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      tareas = tareas.where((tarea) {
        return tarea.titulo.toLowerCase().contains(query) ||
            tarea.descripcion.toLowerCase().contains(query);
      }).toList();
    }

    // Filter by tab
    final tabIndex = _tabController.index;
    if (tabIndex == 1) {
      tareas = tareas.where((t) => t.estado == EstadoTarea.pendiente).toList();
    } else if (tabIndex == 2) {
      tareas = tareas.where((t) =>
        t.estado == EstadoTarea.asignada || t.estado == EstadoTarea.aceptada
      ).toList();
    } else if (tabIndex == 3) {
      tareas = tareas.where((t) => t.estado == EstadoTarea.finalizada).toList();
    }

    return tareas;
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
            Container(
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
                            Text(
                              'Gestión de Tareas',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_filteredTareas.length} tareas encontradas',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.search_rounded,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                          onPressed: _showSearchDialog,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: (_selectedEstado != null || _selectedPrioridad != null || _selectedDepartamento != null)
                              ? AppTheme.primaryBlue
                              : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (_selectedEstado != null || _selectedPrioridad != null || _selectedDepartamento != null)
                                ? AppTheme.primaryBlue
                                : (isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            color: (_selectedEstado != null || _selectedPrioridad != null || _selectedDepartamento != null)
                                ? Colors.white
                                : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                          ),
                          onPressed: _showFiltersDialog,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Modern Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBackground : const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      onTap: (_) => setState(() {}),
                      indicator: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      padding: const EdgeInsets.all(4),
                      tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Active Filters
            if (_selectedEstado != null || _selectedPrioridad != null || _selectedDepartamento != null)
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_selectedEstado != null)
                      _buildFilterChip(_selectedEstado!.label, () {
                        setState(() => _selectedEstado = null);
                        _loadTareas();
                      }),
                    if (_selectedPrioridad != null)
                      _buildFilterChip(_selectedPrioridad!.label, () {
                        setState(() => _selectedPrioridad = null);
                        _loadTareas();
                      }),
                    if (_selectedDepartamento != null)
                      _buildFilterChip(_selectedDepartamento!.label, () {
                        setState(() => _selectedDepartamento = null);
                        _loadTareas();
                      }),
                  ],
                ),
              ),

            // Task List
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: AppTheme.dangerRed),
                              const SizedBox(height: 16),
                              Text(
                                'Error al cargar tareas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadTareas,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Reintentar', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        )
                      : _filteredTareas.isEmpty
                          ? Center(
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
                                      Icons.assignment_outlined,
                                      size: 64,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No hay tareas',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Crea una nueva tarea usando el botón +',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadTareas,
                              color: AppTheme.primaryBlue,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                                itemCount: _filteredTareas.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) => _buildTaskCard(_filteredTareas[index], isDark),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return TaskFilterChip(label: label, onRemove: onRemove);
  }

  Widget _buildTaskCard(Tarea tarea, bool isDark) {
    return Padding(
      padding: EdgeInsets.zero,
      child: TaskCard(
        tarea: tarea,
        style: TaskCardStyle.premium,
        showSkills: true,
        showAssignee: true,
        showDueDate: true,
        showProgressIndicator: true,
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AdminTaskDetailScreen(tareaId: tarea.id)),
          );
          if (result == true) _loadTareas();
        },
      ),
    );
  }
}

// Modern Filters Sheet
class _FiltersSheet extends StatefulWidget {
  final EstadoTarea? selectedEstado;
  final PrioridadTarea? selectedPrioridad;
  final Departamento? selectedDepartamento;
  final Function(EstadoTarea?, PrioridadTarea?, Departamento?) onApply;

  const _FiltersSheet({
    this.selectedEstado,
    this.selectedPrioridad,
    this.selectedDepartamento,
    required this.onApply,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late EstadoTarea? _tempEstado;
  late PrioridadTarea? _tempPrioridad;
  late Departamento? _tempDepartamento;

  @override
  void initState() {
    super.initState();
    _tempEstado = widget.selectedEstado;
    _tempPrioridad = widget.selectedPrioridad;
    _tempDepartamento = widget.selectedDepartamento;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppTheme.primaryBlue, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _tempEstado = null;
                          _tempPrioridad = null;
                          _tempDepartamento = null;
                        });
                      },
                      child: const Text('Limpiar', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
              // Filters
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSection('Estado', isDark),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: EstadoTarea.values.map((estado) => _buildFilterChip(
                        estado.label,
                        _tempEstado == estado,
                        () => setState(() => _tempEstado = _tempEstado == estado ? null : estado),
                        isDark,
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                    _buildSection('Prioridad', isDark),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PrioridadTarea.values.map((prioridad) => _buildFilterChip(
                        prioridad.label,
                        _tempPrioridad == prioridad,
                        () => setState(() => _tempPrioridad = _tempPrioridad == prioridad ? null : prioridad),
                        isDark,
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                    _buildSection('Departamento', isDark),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Departamento.principales.map((dept) => _buildFilterChip(
                        dept.label,
                        _tempDepartamento == dept,
                        () => setState(() => _tempDepartamento = _tempDepartamento == dept ? null : dept),
                        isDark,
                      )).toList(),
                    ),
                  ],
                ),
              ),
              // Apply button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_tempEstado, _tempPrioridad, _tempDepartamento);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Aplicar Filtros', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : (isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
          ),
        ),
      ),
    );
  }
}
