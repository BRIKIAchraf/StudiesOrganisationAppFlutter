import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';

import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {


  void _showEditProfile(BuildContext context, SettingsProvider settings) {
    final nameController = TextEditingController(text: settings.userName);
    final matricolaController = TextEditingController(text: settings.matricola);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: matricolaController,
              decoration: const InputDecoration(labelText: 'Matricola'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              settings.updateProfile(nameController.text, matricolaController.text);
              Navigator.pop(ctx);
            }, 
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();

    return ListView(
      children: [
        const SizedBox(height: 100), // Space for transparent AppBar
        
        // University Logo
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.primary,
                    child: const Icon(Icons.school, size: 40, color: Colors.white),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.dark_mode),
          title: const Text('Dark Mode'),
          value: settings.isDarkMode,
          onChanged: (value) => settings.toggleTheme(value),
        ),
        const Divider(),
        
        // Biometric Settings - NEW
        
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: Text(settings.userName),
          subtitle: Text('Matricola: ${settings.matricola}'),
          trailing: const Icon(Icons.edit),
          onTap: () => _showEditProfile(context, settings),
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Role Management', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        ListTile(
          leading: const Icon(Icons.swap_horizontal_circle_rounded),
          title: const Text('Current Role'),
          subtitle: Text(auth.userRole?.toUpperCase() ?? 'STUDENT'),
          trailing: Switch(
            value: auth.userRole == 'professor' || auth.userRole == 'admin',
            onChanged: (isProfessor) async {
              try {
                await auth.switchRole(isProfessor ? 'professor' : 'student');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Switched to ${isProfessor ? 'Professor' : 'Student'} role')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            activeColor: AppColors.primary,
          ),
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Account', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Log Out', style: TextStyle(color: Colors.red)),
          onTap: () async {
            await auth.logout();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
            }
          },
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('About', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        const ListTile(
          leading: Icon(Icons.info),
          title: Text('Version'),
          subtitle: Text('1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.school),
          title: const Text('Project'),
          subtitle: const Text('University Study Planner'),
          trailing: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.school, color: AppColors.primary);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

}
