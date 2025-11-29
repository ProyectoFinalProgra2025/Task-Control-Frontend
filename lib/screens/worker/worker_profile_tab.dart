import 'package:flutter/material.dart';
import '../common/profile_screen.dart';

class WorkerProfileTab extends StatelessWidget {
  const WorkerProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen(role: ProfileRole.worker);
  }
}
