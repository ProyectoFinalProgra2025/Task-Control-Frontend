import 'package:flutter/material.dart';
import '../common/profile_screen.dart';

class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen(role: ProfileRole.adminEmpresa);
  }
}
