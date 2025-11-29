# 📊 Unificación de Home Screens y Calendario de Tareas

## Fecha: Noviembre 2025

---

## 🎯 Objetivo

Unificar las pantallas de inicio (`home_tab`) de `CompanyAdmin` y `AreaManager` en un diseño común con componentes modulares, e integrar un **Calendario de Tareas** que se adapte según el rol:

- **CompanyAdmin**: Visualiza tareas de **TODA la empresa**
- **AreaManager**: Visualiza tareas de **SU departamento**

---

## 📁 Archivos Actuales

### Company Admin
```
lib/screens/company_admin/admin_home_tab.dart
```

### Area Manager
```
lib/screens/area_manager/manager_home_tab.dart
```

### Widgets Reutilizables
```
lib/widgets/premium_widgets.dart
lib/widgets/task_progress_indicator.dart
lib/widgets/theme_toggle_button.dart
lib/widgets/create_task_modal.dart
```

---

## 🧩 ANÁLISIS DE COMPONENTES EXISTENTES

### 📌 COMPANY ADMIN (`admin_home_tab.dart`)

| Componente | Descripción | Widget/Método | Reutilizable |
|------------|-------------|---------------|--------------|
| **Header Premium** | Avatar + nombre + empresa + theme toggle + notificaciones | Inline Container | ✅ Extraer a widget |
| **Quick Actions Cards** | 2 tarjetas: "Nueva Tarea" y "Ver Equipo" | `_buildActionCard()` | ✅ Ya es modular |
| **Task Metrics Grid** | 4 métricas: Total, Pendientes, En Progreso, Completadas | `_buildMetricCard()` | ✅ Ya es modular |
| **Recent Tasks List** | Lista de tareas recientes con estado | `_buildTaskItem()` | ✅ Ya es modular |
| **Realtime Events** | Suscripción a eventos de tareas/usuarios | StreamSubscription | ✅ Reutilizar patrón |

#### Métodos Clave:
```dart
_buildActionCard(icon, title, subtitle, color, onTap, isDark)
_buildMetricCard(title, value, icon, color, isDark)
_buildTaskItem(tarea, isDark)
_getStatusColor(estado)
_getStatusText(estado)
_getInitials(name)
```

---

### 📌 AREA MANAGER (`manager_home_tab.dart`)

| Componente | Descripción | Widget/Método | Reutilizable |
|------------|-------------|---------------|--------------|
| **Header Premium** | Avatar + nombre + rol badge + theme toggle + notificaciones | Inline Container | ✅ Extraer a widget |
| **Stats Card Simple** | 1 tarjeta de "Tareas Pendientes" | Inline Container | ✅ Usar `StatCard` |
| **Task Card** | Tarjeta de tarea activa con acciones | `_buildTaskCard()` | ✅ Ya es modular |
| **Empty State** | Estado vacío cuando no hay tareas | `_buildEmptyState()` | ✅ Usar `PremiumEmptyState` |
| **Delegation Actions** | Botones de delegar, aceptar, finalizar | Inline en task card | ✅ Extraer a widget |
| **Realtime Events** | Suscripción a eventos de tareas/usuarios | StreamSubscription | ✅ Reutilizar patrón |

#### Métodos de Acción:
```dart
_aceptarTarea(tareaId)
_finalizarTarea(tarea)
_delegarORechazarTarea(tarea)
_asignarAWorker(tarea)
_delegarAOtroManager(tarea)
_rechazarTarea(tarea)
```

---

## 🎨 WIDGETS PREMIUM EXISTENTES (`premium_widgets.dart`)

| Widget | Uso | Parámetros Clave |
|--------|-----|------------------|
| `PremiumCard` | Container con bordes, sombras y gradientes | `isDark`, `gradientColors`, `enableGlow`, `onTap` |
| `StatCard` | Tarjeta de estadística con icono | `icon`, `title`, `value`, `color`, `isDark` |
| `PremiumButton` | Botón con gradiente | `text`, `icon`, `gradientColors`, `isOutlined`, `isLoading` |
| `PremiumAppBar` | Header con avatar y acciones | `title`, `subtitle`, `avatar`, `actions`, `isDark` |
| `PremiumNavItem` | Item de navegación inferior | `icon`, `activeIcon`, `label`, `isActive`, `badgeCount` |
| `TaskStateBadge` | Badge de estado de tarea | `text`, `color`, `showGlow` |
| `InfoRow` | Fila de info con icono | `icon`, `text`, `isDark`, `iconColor` |
| `PremiumAvatar` | Avatar circular premium | `initials`, `icon`, `radius`, `gradientColors` |
| `PremiumEmptyState` | Estado vacío elegante | `icon`, `title`, `subtitle`, `isDark`, `action` |

---

## 🗓️ NUEVO COMPONENTE: TaskCalendarWidget

### Descripción
Widget de calendario modular que muestra tareas organizadas por día, adaptándose al rol del usuario.

### Características

1. **Vista Mensual**: Calendario con indicadores de tareas por día
2. **Vista Diaria**: Al tocar un día, muestra lista detallada de tareas
3. **Filtros**: Por estado, por trabajador (opcional)
4. **Tiempo Real**: Actualización automática con SignalR

### API

```dart
class TaskCalendarWidget extends StatefulWidget {
  /// Rol del usuario: determina el alcance de tareas
  final UserRole role; // companyAdmin | areaManager
  
  /// ID del departamento (solo para areaManager)
  final String? departamentoId;
  
  /// Color primario del calendario
  final Color primaryColor;
  
  /// Callback cuando se selecciona una tarea
  final Function(Tarea)? onTaskTap;
  
  /// Callback cuando se selecciona un día
  final Function(DateTime)? onDayTap;
}
```

### Diseño Visual (basado en imagen adjunta)

```
┌─────────────────────────────────────────────┐
│  Analytics                     Jan 2025  ▼  │
├─────────────────────────────────────────────┤
│   Sat    Sun    Mon    Tue    Wed    Thu    │
│                                              │
│   ●●●    ●●●    ●●     ●●     ●●●           │
│   ●●     ●●●    ●●     ●      ●●            │
│   50+    80+    50+    20+    80+           │
│                                              │
│   (círculos apilados por prioridad/estado)  │
└─────────────────────────────────────────────┘
```

Cada columna representa un día con:
- **Círculos superiores**: Tareas ordenadas por prioridad (más oscuro = mayor prioridad)
- **Número inferior**: Total de tareas del día
- **Colores**:
  - Azul claro: Pendiente
  - Azul medio: Asignada
  - Azul oscuro: En progreso
  - Verde: Completada

---

## 📐 ARQUITECTURA PROPUESTA

### Nueva Estructura de Archivos

```
lib/
├── widgets/
│   ├── dashboard/
│   │   ├── dashboard_header.dart          # Header unificado
│   │   ├── quick_action_card.dart         # Tarjeta de acción rápida
│   │   ├── metric_card.dart               # Tarjeta de métrica
│   │   ├── task_list_compact.dart         # Lista de tareas compacta
│   │   └── README.md                      # Documentación
│   │
│   ├── calendar/
│   │   ├── task_calendar_widget.dart      # Calendario principal
│   │   ├── calendar_day_cell.dart         # Celda de día individual
│   │   ├── calendar_task_indicator.dart   # Indicador de tareas
│   │   ├── day_tasks_sheet.dart           # Bottom sheet con tareas del día
│   │   └── README.md                      # Documentación
│   │
│   └── premium_widgets.dart               # Widgets base (existente)
│
├── screens/
│   ├── common/
│   │   └── unified_home_tab.dart          # Home unificado para ambos roles
│   │
│   ├── company_admin/
│   │   └── admin_home_screen.dart         # Usa unified_home_tab
│   │
│   └── area_manager/
│       └── manager_home_screen.dart       # Usa unified_home_tab
```

---

## 🔧 PLAN DE IMPLEMENTACIÓN

### FASE 1: Extracción de Widgets (1-2 horas)

1. **Crear `dashboard_header.dart`**
   - Extraer lógica común del header
   - Parámetros: `userName`, `userRole`, `companyName`, `avatarInitials`

2. **Crear `quick_action_card.dart`**
   - Mover `_buildActionCard()` a widget separado
   - Agregar variantes: con badge, con progreso

3. **Crear `metric_card.dart`**
   - Mover `_buildMetricCard()` a widget separado
   - Agregar animación de entrada

4. **Crear `task_list_compact.dart`**
   - Mover `_buildTaskItem()` a widget separado
   - Agregar soporte para acciones inline

### FASE 2: Calendario de Tareas (2-3 horas)

1. **Crear `task_calendar_widget.dart`**
   ```dart
   // Dependencias sugeridas:
   // - table_calendar: ^3.0.0 (base del calendario)
   // - provider (ya instalado)
   ```

2. **Crear `calendar_day_cell.dart`**
   - Renderizado custom de cada día
   - Indicadores visuales de tareas

3. **Crear `day_tasks_sheet.dart`**
   - Bottom sheet con lista de tareas del día
   - Navegación a detalle de tarea

4. **Backend**: Nuevo endpoint (si es necesario)
   ```
   GET /api/tareas/calendario?fechaInicio=X&fechaFin=Y
   ```

### FASE 3: Unificación de Home Screen (1-2 horas)

1. **Crear `unified_home_tab.dart`**
   - Usar patrón de composición
   - Recibir widgets según rol

2. **Actualizar navegación**
   - CompanyAdmin usa unified con sus widgets
   - AreaManager usa unified con sus widgets

---

## 📊 DATOS DEL CALENDARIO

### Endpoint Existente (puede reutilizarse)
```
GET /api/tareas          → Para CompanyAdmin (todas las tareas)
GET /api/tareas/mis      → Para AreaManager (tareas del departamento)
```

### Filtrado por Fecha
Las tareas tienen `dueDate` que puede usarse para agrupar por día.

### Estructura de Datos para Calendario
```dart
class CalendarDayData {
  final DateTime date;
  final List<Tarea> tareas;
  
  int get totalTareas => tareas.length;
  int get pendientes => tareas.where((t) => t.estado == EstadoTarea.pendiente).length;
  int get enProgreso => tareas.where((t) => t.estado == EstadoTarea.aceptada).length;
  int get completadas => tareas.where((t) => t.estado == EstadoTarea.finalizada).length;
}
```

---

## 🎨 ESPECIFICACIONES VISUALES

### Colores del Calendario (basados en imagen)
```dart
// Intensidad de tareas (de menos a más)
static const Color taskLight = Color(0xFFBFDBFE);    // 1-10 tareas
static const Color taskMedium = Color(0xFF60A5FA);   // 11-30 tareas
static const Color taskDark = Color(0xFF2563EB);     // 30+ tareas
static const Color taskIntense = Color(0xFF1D4ED8);  // 50+ tareas

// Estados
static const Color estadoPendiente = Color(0xFFFBBF24);
static const Color estadoAsignada = Color(0xFF60A5FA);
static const Color estadoAceptada = Color(0xFFA855F7);
static const Color estadoFinalizada = Color(0xFF10B981);
```

### Animaciones
- Transición suave al cambiar de mes
- Bounce al seleccionar día
- Fade in al cargar tareas

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

### Fase 1: Widgets Base
- [x] `dashboard_header.dart`
- [x] `quick_action_card.dart`
- [x] `metric_card.dart`

### Fase 2: Calendario
- [x] Agregar dependencia `table_calendar`
- [x] `task_calendar_widget.dart`
- [x] `DayTasksSheet` (integrado en task_calendar_widget.dart)
- [x] Integración en admin_home_tab.dart
- [x] Integración en manager_home_tab.dart

### Fase 3: Integración (Pendiente futuro)
- [ ] `unified_home_tab.dart` (opcional - unificar en un solo archivo)
- [ ] Tests de integración

---

## 🚀 PRÓXIMOS PASOS

1. **Confirmar diseño** del calendario con el usuario
2. **Agregar dependencia** `table_calendar` a `pubspec.yaml`
3. **Comenzar con Fase 1** - Extracción de widgets
4. **Iterar** según feedback

---

## 📚 REFERENCIAS

- Imagen de referencia: Diseño tipo "Analytics" con círculos apilados
- Design System: `premium_widgets.dart`
- Tema: `config/theme_config.dart`
