import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';
import '../theme.dart';
import 'admin_professor_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  int _pendingProfessors = 2; // Mock count

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final auth = context.read<AuthProvider>();
    final url = '${ApiConfig.baseUrl}/admin/stats';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _stats = json.decode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // University Logo Header
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
              const Text(
                'Academic Impact Overview',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildStatsGrid(),
              const SizedBox(height: 32),
              const Text('Management Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              // Professor Management - NEW
              _buildActionItem(
                'Professor Management',
                _pendingProfessors > 0 
                  ? '$_pendingProfessors pending approvals'
                  : 'Manage professor authorizations',
                Icons.person_add_alt_1_rounded,
                AppColors.primary,
                badge: _pendingProfessors > 0 ? _pendingProfessors.toString() : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminProfessorManagementScreen()),
                  );
                },
              ),
              
              _buildActionItem(
                'Broadcast Study Tip',
                'Notify all enrolled students',
                Icons.campaign_rounded,
                AppColors.warning,
                onTap: () {},
              ),
              _buildActionItem(
                'Grade Distributions',
                'View global performance trends',
                Icons.bar_chart_rounded,
                AppColors.primary,
                onTap: () {},
              ),
              _buildActionItem(
                'Course Content',
                'Manage lectures and materials',
                Icons.folder_copy_rounded,
                AppColors.accent,
                onTap: () {},
              ),
            ],
          ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatTile('Total Students', '1.2k', Icons.groups_rounded, Colors.blue),
        _buildStatTile('Teaching Load', _stats?['totalCourses']?.toString() ?? '0', Icons.auto_stories_rounded, Colors.orange),
        _buildStatTile('Campus GPA', (_stats?['globalAverageGrade'] ?? 0.0).toStringAsFixed(1), Icons.star_rounded, AppColors.primary),
        _buildStatTile('Completions', _stats?['completedCoursesCount']?.toString() ?? '0', Icons.verified_user_rounded, Colors.green),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, String sub, IconData icon, Color color, {String? badge, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            if (badge != null)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), 
          side: BorderSide(color: Colors.grey.withOpacity(0.1))
        ),
      ),
    );
  }
}
