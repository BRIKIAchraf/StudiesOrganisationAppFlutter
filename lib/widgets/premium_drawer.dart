import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/admin_dashboard_screen.dart';

class PremiumDrawer extends StatelessWidget {
  const PremiumDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDarkMode;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Glass Background Effect
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: isDark 
                  ? Colors.black.withOpacity(0.5) 
                  : Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          
          Column(
            children: [
              // Premium Header with User Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, bottom: 20, left: 24, right: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo[900]!.withOpacity(0.8),
                      Colors.indigo[600]!.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        auth.userName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      auth.userName ?? 'User',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      auth.userRole?.toUpperCase() ?? 'STUDENT',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Navigation Items
              _buildDrawerItem(
                context,
                icon: Icons.home_rounded,
                label: 'Dashboard',
                onTap: () => Navigator.pop(context),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.auto_stories_rounded,
                label: auth.userRole == 'professor' ? 'My Teaching' : 'My Courses',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.timer_rounded,
                label: auth.userRole == 'professor' ? 'Course Stats' : 'Study History',
                onTap: () => Navigator.pop(context),
              ),
              if (auth.isAdmin || auth.userRole == 'professor')
                _buildDrawerItem(
                  context,
                  icon: Icons.psychology_rounded,
                  label: 'Professor Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                    );
                  },
                  color: Colors.amber[700],
                ),
              
              const Spacer(),
              
              // Bottom Section: Logout
              const Divider(indent: 20, endIndent: 20),
              _buildDrawerItem(
                context,
                icon: Icons.logout_rounded,
                label: 'Log Out',
                onTap: () async {
                  Navigator.pop(context);
                  await auth.logout();
                },
                color: Colors.redAccent,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color ?? (isDark ? Colors.white70 : Colors.indigo)),
        title: Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: Colors.indigo.withOpacity(0.1),
      ),
    );
  }
}
