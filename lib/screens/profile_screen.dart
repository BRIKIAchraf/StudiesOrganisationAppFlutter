import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../providers/courses_provider.dart';
import '../services/persistence_service.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _universityController = TextEditingController();
  final _departmentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController.text = auth.userName ?? '';
    // Load other fields from preferences if available
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _universityController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final coursesProvider = context.watch<CoursesProvider>();
    final isStudent = auth.userRole == 'student';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryBrand.withOpacity(0.1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: _isEditing ? _buildEditMode(auth) : _buildViewMode(auth, coursesProvider, isStudent),
        ),
      ),
    );
  }

  Widget _buildViewMode(AuthProvider auth, CoursesProvider coursesProvider, bool isStudent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile Picture
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primaryBrand.withOpacity(0.2),
                child: Text(
                  (auth.userName ?? 'U')[0].toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBrand,
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBrand,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBrand.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Name
          Text(
            auth.userName ?? 'User',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 8),
          
          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryBrand.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryBrand.withOpacity(0.3)),
            ),
            child: Text(
              auth.userRole?.toUpperCase() ?? 'STUDENT',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBrand,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
          
          const SizedBox(height: 32),
          
          // Stats Cards
          if (isStudent) _buildStudentStats(coursesProvider),
          if (!isStudent) _buildProfessorStats(coursesProvider),
          
          const SizedBox(height: 24),
          
          // Info Section
          _buildInfoCard(
            icon: Icons.school_outlined,
            title: 'University',
            value: 'Not Set',
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoCard(
            icon: Icons.business_outlined,
            title: 'Department',
            value: 'Not Set',
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoCard(
            icon: Icons.info_outline,
            title: 'Bio',
            value: 'No bio yet. Tap edit to add one!',
          ),
          
          const SizedBox(height: 32),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                auth.logout();
                Navigator.of(context).pushReplacementNamed('/auth');
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildEditMode(AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          
          Text(
            'Edit Profile',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 32),
          
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: _universityController,
            decoration: const InputDecoration(
              labelText: 'University',
              prefixIcon: Icon(Icons.school_outlined),
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: _departmentController,
            decoration: const InputDecoration(
              labelText: 'Department',
              prefixIcon: Icon(Icons.business_outlined),
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: _bioController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Bio',
              prefixIcon: Icon(Icons.edit_note),
              alignLabelWithHint: true,
            ),
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // Save profile changes
                try {
                  final auth = context.read<AuthProvider>();
                  
                  // Update via API
                  await auth.updateProfile(
                    bio: _bioController.text.isNotEmpty ? _bioController.text : null,
                    university: _universityController.text.isNotEmpty ? _universityController.text : null,
                    department: _departmentController.text.isNotEmpty ? _departmentController.text : null,
                  );
                  
                  // Also save locally with PersistenceService
                  final persistence = PersistenceService();
                  await persistence.updateUserProfile(
                    userName: _nameController.text.isNotEmpty ? _nameController.text : null,
                    university: _universityController.text.isNotEmpty ? _universityController.text : null,
                    department: _departmentController.text.isNotEmpty ? _departmentController.text : null,
                    bio: _bioController.text.isNotEmpty ? _bioController.text : null,
                  );
                  
                  setState(() => _isEditing = false);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Profile updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('SAVE CHANGES'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentStats(CoursesProvider provider) {
    final totalCourses = provider.courses.length;
    final studyTime = provider.studyTimeToday;
    final avgGrade = provider.averageGrade;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Courses',
            totalCourses.toString(),
            Icons.book_outlined,
            AppColors.primaryBrand,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Study Today',
            '${studyTime}m',
            Icons.timer_outlined,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Avg Grade',
            avgGrade.toStringAsFixed(1),
            Icons.grade_outlined,
            AppColors.warning,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildProfessorStats(CoursesProvider provider) {
    final totalCourses = provider.courses.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'My Courses',
            totalCourses.toString(),
            Icons.class_outlined,
            AppColors.primaryBrand,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Students',
            '0', // TODO: Calculate from enrollments
            Icons.people_outline,
            AppColors.success,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBrand.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryBrand),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1, end: 0);
  }
}
