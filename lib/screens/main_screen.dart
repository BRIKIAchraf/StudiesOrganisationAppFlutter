import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'home_screen.dart';
import 'courses_screen.dart';
import 'study_sessions_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_professor_management_screen.dart';
import 'chat_screen.dart';
import '../providers/auth_provider.dart';
import '../widgets/premium_drawer.dart';
import '../theme.dart';

import '../services/notification_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Request permissions on first load
    NotificationService().requestPermissions();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  List<Widget> _getPages(String? role) {
    if (role == 'admin') {
      return [
        const AdminDashboardScreen(),
        const AdminProfessorManagementScreen(),
        const SettingsScreen(),
      ];
    } else if (role == 'professor') {
      return [
        const HomeScreen(), 
        const CoursesScreen(), 
        const Center(child: Text('Messages')), 
        const SettingsScreen(),
      ];
    } else {
      return [
        const HomeScreen(),
        const CoursesScreen(),
        const CalendarScreen(), 
        const SettingsScreen(),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().userRole;
    final pages = _getPages(role);

    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    return Scaffold(
      extendBody: true, // Content behind navbar
      extendBodyBehindAppBar: true,
      
      // Transparent AppBar for maximum whitespace & content focus
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
            onPressed: () {},
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(width: 8),
          Padding(
             padding: const EdgeInsets.only(right: 16),
             child: CircleAvatar(
               radius: 18,
               backgroundColor: AppColors.primaryBrand.withOpacity(0.1),
               child: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.primaryBrand),
             ),
          ).animate().scale(delay: 700.ms),
        ],
      ),
      drawer: const PremiumDrawer(),
      body: pages[_selectedIndex],
      
      // Floating Pill Navigation Bar
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 80,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBrand.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _buildNavItems(role),
          ),
        ).animate().slideY(begin: 1.0, end: 0, duration: 800.ms, curve: Curves.easeOutQuint),
      ),
    );
  }

  List<Widget> _buildNavItems(String? role) {
    List<Map<String, dynamic>> items = [];

    if (role == 'admin') {
      items = [
        {'icon': Icons.grid_view_rounded, 'label': 'Panel'},
        {'icon': Icons.groups_rounded, 'label': 'Profs'},
        {'icon': Icons.tune_rounded, 'label': 'Settings'},
      ];
    } else if (role == 'professor') {
      items = [
        {'icon': Icons.grid_view_rounded, 'label': 'Home'},
        {'icon': Icons.class_outlined, 'label': 'Courses'},
        {'icon': Icons.chat_bubble_outline_rounded, 'label': 'Chat'},
        {'icon': Icons.tune_rounded, 'label': 'Settings'},
      ];
    } else {
      items = [
        {'icon': Icons.home_filled, 'label': 'Home'}, // Filled for stronger home presence
        {'icon': Icons.auto_stories_outlined, 'label': 'Learn'},
        {'icon': Icons.calendar_month_rounded, 'label': 'Plan'},
        {'icon': Icons.tune_rounded, 'label': 'Profile'},
      ];
    }

    return List.generate(items.length, (index) {
      final isSelected = _selectedIndex == index;
      return GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBrand.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Icon(
                items[index]['icon'],
                color: isSelected ? AppColors.primaryBrand : AppColors.textTertiary,
                size: 26,
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Text(
                  items[index]['label'],
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBrand,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
