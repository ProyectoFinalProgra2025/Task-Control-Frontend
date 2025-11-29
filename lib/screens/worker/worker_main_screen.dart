import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'worker_home_tab.dart';
import '../common/chat_list_screen.dart';
import 'worker_profile_tab.dart';
import '../../widgets/premium_widgets.dart';
import '../../config/theme_config.dart';
import '../../providers/chat_provider.dart';

class WorkerMainScreen extends StatefulWidget {
  const WorkerMainScreen({super.key});

  @override
  State<WorkerMainScreen> createState() => _WorkerMainScreenState();
}

class _WorkerMainScreenState extends State<WorkerMainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _tabs = const [
    WorkerHomeTab(),
    ChatListScreen(),
    WorkerProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: _tabs,
      ),
      bottomNavigationBar: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final unreadCount = chatProvider.totalUnreadCount;
          
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              border: Border(
                top: BorderSide(
                  color: isDark
                    ? AppTheme.darkBorder.withOpacity(0.3)
                    : AppTheme.lightBorder,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceRegular,
                  vertical: AppTheme.spaceSmall,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    PremiumNavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Home',
                      isActive: _currentIndex == 0,
                      activeColor: AppTheme.primaryBlue,
                      isDark: isDark,
                      onTap: () => _onNavItemTapped(0),
                    ),
                    PremiumNavItem(
                      icon: Icons.chat_bubble_outline,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: 'Chats',
                      isActive: _currentIndex == 1,
                      activeColor: AppTheme.primaryBlue,
                      isDark: isDark,
                      badgeCount: unreadCount,
                      onTap: () => _onNavItemTapped(1),
                    ),
                PremiumNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: _currentIndex == 2,
                  activeColor: AppTheme.primaryBlue,
                  isDark: isDark,
                  onTap: () => _onNavItemTapped(2),
                ),
              ],
            ),
          ),
        ),
        );
        },
      ),
    );
  }
}
