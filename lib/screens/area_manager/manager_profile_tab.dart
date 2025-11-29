import 'package:flutter/material.dart';
import '../common/profile_screen.dart';

class ManagerProfileTab extends StatelessWidget {
  const ManagerProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen(role: ProfileRole.manager);
  }
}
