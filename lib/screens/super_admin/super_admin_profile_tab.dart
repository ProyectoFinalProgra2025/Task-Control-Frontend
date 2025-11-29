import 'package:flutter/material.dart';
import '../common/profile_screen.dart';

class SuperAdminProfileTab extends StatelessWidget {
  const SuperAdminProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen(role: ProfileRole.superAdmin);
  }
}
