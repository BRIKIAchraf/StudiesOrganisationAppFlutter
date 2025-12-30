import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'courses_screen.dart';
import 'study_sessions_screen.dart';
import 'settings_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_professor_management_screen.dart';
import 'chat_screen.dart';
import '../providers/auth_provider.dart';
import '../widgets/premium_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

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
        const HomeScreen(), // Professor view of home
        const CoursesScreen(), // Management view
        const Center(child: Text('Chat List Coming Soon')), // Placeholder for build fix
        const SettingsScreen(),
      ];
    } else {
      // Default: Student
      return [
        const HomeScreen(),
        const CoursesScreen(),
        const StudySessionsScreen(),
        const SettingsScreen(),
      ];
    }
  }

  List<String> _getTitles(String? role) {
    if (role == 'admin') return ['Admin Panel', 'Professors', 'Settings'];
    if (role == 'professor') return ['Home', 'Courses', 'Messages', 'Settings'];
    return ['Dashboard', 'My Courses', 'Study Sessions', 'Settings'];
  }

  List<BottomNavigationBarItem> _getNavItems(String? role) {
    if (role == 'admin') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_rounded), label: 'Panel'),
        BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Professors'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
      ];
    } else if (role == 'professor') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Management'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.book_rounded), label: 'Courses'),
        BottomNavigationBarItem(icon: Icon(Icons.timer_rounded), label: 'Sessions'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().userRole;
    final pages = _getPages(role);
    final titles = _getTitles(role);
    final navItems = _getNavItems(role);

    // Safety check for index out of bounds when switching roles
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: const PremiumDrawer(),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
