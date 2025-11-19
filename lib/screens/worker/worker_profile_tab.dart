import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';

class WorkerProfileTab extends StatefulWidget {
  const WorkerProfileTab({super.key});

  @override
  State<WorkerProfileTab> createState() => _WorkerProfileTabState();
}

class _WorkerProfileTabState extends State<WorkerProfileTab> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  UserModel? _user;
  bool _isLoading = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _storageService.getUserData();
      if (userData != null) {
        setState(() {
          _user = UserModel.fromJson(userData);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF005A9C),
        centerTitle: true,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            // Optional: Navigate back if needed
          },
        ),
        actions: [
          // Spacer for centering
          const SizedBox(width: 48),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: const Color(0xFF005A9C),
                    child: const Icon(
                      Icons.person,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user?.nombreCompleto ?? 'Eleanor Vance',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sales Associate',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? const Color(0xFF92A4C9) : const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Personal Information Section
                  _buildSection(
                    title: 'Personal Information',
                    isDark: isDark,
                    trailing: TextButton(
                      onPressed: () {
                        // TODO: Edit profile
                      },
                      child: const Text(
                        'Edit Details',
                        style: TextStyle(
                          color: Color(0xFF005A9C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    children: [
                      _buildInfoTile(
                        icon: Icons.mail,
                        label: 'Email',
                        value: _user?.email ?? 'e.vance@example.com',
                        isDark: isDark,
                      ),
                      const Divider(height: 1),
                      _buildInfoTile(
                        icon: Icons.phone,
                        label: 'Phone Number',
                        value: '+1 (555) 987-6543',
                        isDark: isDark,
                      ),
                      const Divider(height: 1),
                      _buildInfoTile(
                        icon: Icons.groups,
                        label: 'Team / Department',
                        value: 'Enterprise Sales',
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Account & Security Section
                  _buildSection(
                    title: 'Account & Security',
                    isDark: isDark,
                    children: [
                      _buildInfoTile(
                        icon: Icons.badge,
                        label: 'Username / ID',
                        value: _user?.email.split('@')[0] ?? 'evance',
                        isDark: isDark,
                      ),
                      const Divider(height: 1),
                      _buildSettingTile(
                        icon: Icons.lock,
                        title: 'Change Password',
                        isDark: isDark,
                        onTap: () {
                          // TODO: Change password
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Settings Section
                  _buildSection(
                    title: 'Settings',
                    isDark: isDark,
                    children: [
                      _buildSwitchTile(
                        icon: Icons.notifications,
                        title: 'Push Notifications',
                        value: _notificationsEnabled,
                        isDark: isDark,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      _buildSettingTile(
                        icon: Icons.dark_mode,
                        title: 'Theme',
                        isDark: isDark,
                        onTap: () {
                          // TODO: Change theme
                        },
                      ),
                      const Divider(height: 1),
                      _buildSettingTile(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        isDark: isDark,
                        onTap: () {
                          // TODO: Help screen
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD93025),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool isDark,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF333333),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Column(children: children),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF232F48)
                  : const Color(0xFFE6F0F7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : const Color(0xFF005A9C),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF92A4C9) : const Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF232F48)
                    : const Color(0xFFE6F0F7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white : const Color(0xFF005A9C),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF333333),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? const Color(0xFF92A4C9) : const Color(0xFF666666),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF232F48)
                  : const Color(0xFFE6F0F7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : const Color(0xFF005A9C),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF333333),
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF005A9C),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD93025),
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }
}
