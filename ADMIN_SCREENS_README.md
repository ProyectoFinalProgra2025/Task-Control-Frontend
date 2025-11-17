# Company Admin Screens - Implementation Guide

## Overview
This implementation provides a complete navigation system for Company Admin (AdminEmpresa) users with a modern bottom navigation bar and dedicated screens for different functionalities.

## Architecture

### Main Navigation
- **AdminMainScreen**: Main container with bottom navigation bar (5 buttons)
  - Home Tab
  - Chats Tab
  - Center FAB (Create Task)
  - Tasks Tab
  - Profile Tab

### Screens Structure
```
lib/screens/company_admin/
├── admin_main_screen.dart      # Main container with bottom nav
├── admin_home_tab.dart          # Home screen with quick actions
├── admin_chats_tab.dart         # Chats list screen
├── admin_tasks_tab.dart         # Task management screen
└── admin_profile_tab.dart       # Company admin profile
```

### Widgets
```
lib/widgets/
└── create_task_modal.dart       # Modal for creating/assigning tasks
```

## Features

### 1. Home Tab (admin_home_tab.dart)
- **Welcome Section**: Personalized greeting with avatar
- **Quick Actions Grid**: 4 action cards
  - Create Task (opens modal)
  - View Team (coming soon)
  - Workflows (coming soon)
  - Reports (coming soon)
- **Task Summary Section**: Tabbed view with task lists
  - Tabs: Ongoing, Overdue, Completed
  - Task cards with status indicators

### 2. Chats Tab (admin_chats_tab.dart)
- **Search & New Chat**: Top actions
- **Chat Filters**: All, Teams, Direct Messages
- **Chat List**: Recent conversations with:
  - Avatar (person/group icon)
  - Last message preview
  - Timestamp
  - Unread badge count

### 3. Tasks Tab (admin_tasks_tab.dart)
- **Task Filters**: Horizontal scrollable chips
  - All, Active, Completed, Cancelled, Not Started
- **Task Cards**: Display task information
  - Title and description
  - Assignee
  - Due date
  - Status badge
  - Priority indicator

### 4. Profile Tab (admin_profile_tab.dart)
- **Profile Header**: Avatar, name, role
- **Personal Information Section**:
  - Full Name
  - Job Title
  - Email Address
  - Phone
- **Company Information Section**:
  - Company Name
  - Role
- **Logout Button**: Secure logout with confirmation

### 5. Create Task Modal (create_task_modal.dart)
- **Form Fields**:
  - Task Name (required)
  - Category (dropdown)
  - Priority (dropdown)
  - Department (dropdown)
  - Due Date (date picker)
  - Description (multi-line)
- **Validation**: Form validation before submission
- **Accessible from**: Center FAB in bottom nav (available on all tabs)

## Navigation Flow

```
HomeScreen (checks role)
    ↓
AdminMainScreen (if AdminEmpresa)
    ↓
Bottom Navigation (4 tabs + center FAB)
    ├── Home Tab
    ├── Chats Tab
    ├── Tasks Tab
    └── Profile Tab
    
Create Task Modal (accessible from any tab via center FAB)
```

## Design System

### Colors
- **Primary**: `#135bec` (Blue) - Main brand color
- **Secondary**: `#7C3AED` (Purple) - Accent color
- **Success**: `#10B981` (Green)
- **Warning**: `#F59E0B` (Orange)
- **Danger**: `#EF4444` (Red)
- **Info**: `#46B3A9` (Teal)

### Dark Mode Support
All screens support automatic dark mode with proper color switching:
- Background colors adjust based on theme
- Text colors maintain readability
- Card colors adapt to theme

### Typography
- **Manrope Font Family** (fallback to system sans-serif)
- Heading sizes: 28px, 22px, 18px, 16px
- Body text: 14px, 12px
- Font weights: Regular (400), Medium (500), Semibold (600), Bold (700)

## Backend Integration Points

### Endpoints to Implement
1. **GET /api/tareas** - List tasks with filters
2. **POST /api/tareas** - Create new task
3. **GET /api/usuarios/me** - Get current user profile
4. **GET /api/usuarios** - List team members (for View Team feature)
5. **Chats endpoints** - To be defined

### Current Status
- ✅ UI/UX Implementation Complete
- ⏳ Backend Integration (API calls to be implemented)
- ⏳ Real-time Chat (to be implemented)
- ⏳ Team Management (to be implemented)
- ⏳ Workflows & Reports (to be implemented)

## Testing the Implementation

### As Company Admin:
1. Login with AdminEmpresa credentials
2. Navigate through all 4 tabs using bottom navigation
3. Click center FAB to open Create Task modal
4. Test task creation form validation
5. View profile information
6. Test logout functionality

### To Test:
```bash
flutter run
# or
flutter run -d chrome  # For web
```

## Next Steps

1. **Backend Integration**:
   - Implement API service for tasks
   - Connect create task modal to backend
   - Load real task data in home and tasks tabs
   - Implement user profile data fetching

2. **Chat Functionality**:
   - Implement chat service
   - Add real-time messaging
   - Create chat detail screen

3. **Team Management**:
   - Create team list screen
   - Implement team member management
   - Add capacity assignment

4. **Advanced Features**:
   - Workflows automation
   - Analytics and reports
   - Push notifications
   - Task comments and attachments

## Notes

- The implementation follows the HTML mockups provided in `mockups_for_role/`
- Material Design 3 principles with custom theming
- Responsive design for various screen sizes
- Clean architecture with separation of concerns
- Ready for state management integration (Provider, Riverpod, Bloc, etc.)

## File Locations

- **Main Entry**: `lib/screens/home_screen.dart` (routes to AdminMainScreen for AdminEmpresa)
- **Admin Screens**: `lib/screens/company_admin/`
- **Shared Widgets**: `lib/widgets/`
- **Services**: `lib/services/` (auth_service.dart, storage_service.dart)
- **Models**: `lib/models/` (user_model.dart, etc.)
