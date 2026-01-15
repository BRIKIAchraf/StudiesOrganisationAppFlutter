import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/tip_service.dart';
import '../providers/courses_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'admin_dashboard_screen.dart';
import 'study_timer_screen.dart';
import '../models/course.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final coursesProvider = context.watch<CoursesProvider>();
    final upcoming = coursesProvider.upcomingExams;
    final auth = context.watch<AuthProvider>();
    final rec = coursesProvider.recommendedCourse;
    final theme = Theme.of(context);

    // Calculate total study time
    int totalMinutes = 0;
    for (var course in coursesProvider.courses) {
      totalMinutes += course.totalStudyMinutes;
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CoursesProvider>().loadData(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 100, 20, 40), // Top padding for transparent AppBar
        children: [
          // Welcome Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${auth.userName}!',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                auth.userRole == 'professor' || auth.userRole == 'admin' 
                  ? 'Managing your teaching excellence' 
                  : 'Ready for another productive session?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6)
                ),
              ),
            ],
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 32),
          
          if (auth.userRole == 'professor' || auth.userRole == 'admin') 
            _buildProfessorSection(context, coursesProvider).animate().fadeIn(delay: 200.ms).slideX(),
          
          // Student-only study metrics
          if (auth.userRole == 'student' || auth.userRole == null) 
            _buildStudentSection(context, coursesProvider, totalMinutes, rec).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 32),

          // Achievement Badges Section
          if (coursesProvider.achievementBadges.isNotEmpty) ...[
            _buildSectionTitle('Achievements', Icons.military_tech_outlined),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: coursesProvider.achievementBadges.map((badge) => Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text(badge, style: theme.textTheme.labelLarge?.copyWith(color: AppColors.accent)),
                    ],
                  ),
                ).animate().scale(delay: 300.ms)).toList(),
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Weekly Chart Section
          _buildSectionTitle('Weekly Focus', Icons.bar_chart_rounded),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              boxShadow: theme.cardTheme.shadowColor != null 
                  ? [BoxShadow(color: theme.cardTheme.shadowColor!, blurRadius: 20, offset: const Offset(0, 10))] 
                  : [],
            ),
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final index = value.toInt() - 1;
                        if (index < 0 || index >= days.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(days[index], style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withOpacity(0.4)
                          )),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: coursesProvider.weeklyStudyData.entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.toDouble(),
                        color: e.value > 60 ? AppColors.success : theme.primaryColor,
                        width: 12,
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 120, // Max scale
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.3)
                        )
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).moveY(begin: 20),
          
          const SizedBox(height: 32),
            
          // Stats Row
          Row(
            children: [
              _buildStatCard(
                context, 
                'GPA', 
                coursesProvider.averageGrade.toStringAsFixed(1), 
                Icons.school_outlined, 
                AppColors.warning
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context, 
                'Progress', 
                '${((coursesProvider.completedCoursesCount / (coursesProvider.courses.isEmpty ? 1 : coursesProvider.courses.length)) * 100).toInt()}%', 
                Icons.pie_chart_outline, 
                AppColors.success
              ),
            ],
          ).animate().fadeIn(delay: 500.ms),
          
          const SizedBox(height: 32),

          // Daily Tip Section
          _buildDailyTip(settings.isDarkMode).animate().fadeIn(delay: 600.ms),
          
          const SizedBox(height: 32),

          // Next Exam Section
          _buildSectionTitle('Upcoming Exams', Icons.event_available_rounded),
          const SizedBox(height: 16),
          
          if (upcoming.isEmpty)
            _buildEmptyState(context, "No upcoming exams", "Add exam dates to your courses to see them here.")
          else
            ...upcoming.take(2).map((nextExam) {
              final daysLeft = nextExam.examDate.difference(DateTime.now()).inDays + 1;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBrand.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Text(
                      DateFormat.d().format(nextExam.examDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryBrand),
                    ),
                  ),
                  title: Text(nextExam.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Prof. ${nextExam.professorName}', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: daysLeft <= 3 ? AppColors.error.withOpacity(0.1) : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20)
                    ),
                    child: Text(
                      daysLeft == 0 ? "TODAY" : (daysLeft == 1 ? "TOMORROW" : "$daysLeft days"),
                      style: TextStyle(
                        color: daysLeft <= 3 ? AppColors.error : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 12
                      ),
                    ),
                  ),
                ),
              );
            }),
            
             // Bottom padding for fab
            const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildProfessorSection(BuildContext context, CoursesProvider provider) {
    return Column(
      children: [
        Card(
          elevation: 0,
          color: AppColors.backgroundLight, // or minimal
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.grey.withOpacity(0.2))
          ),
          child: InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.analytics_rounded, color: AppColors.warning, size: 32),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        SizedBox(height: 4),
                        Text('View analytics & students', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
             _buildStatCard(context, 'Courses', '${provider.courses.length}', Icons.class_outlined, AppColors.info),
             const SizedBox(width: 16),
             _buildStatCard(context, 'Students', '1,240', Icons.people_outline, AppColors.success),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildStudentSection(BuildContext context, CoursesProvider provider, int totalMinutes, Course? rec) {
    return Column(
      children: [
        // Study Today Card - Premium Design
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryBrand, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: AppColors.primaryBrand.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.timer_outlined, color: Colors.white),
                  ),
                  const Text('TODAY\'S FOCUS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 20),
              Text('${(provider.studyTimeToday / 60).toStringAsFixed(1)} Hours', 
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, height: 1)
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text('Total Study: ${(totalMinutes / 60).toStringAsFixed(1)}h', style: const TextStyle(color: Colors.white70)),
                ],
              )
            ],
          ),
        ),
        
        const SizedBox(height: 24),

        if (rec != null) ...[
          _buildSectionTitle('Recommended', Icons.stars_rounded),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 1.5),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.lightbulb_rounded, color: AppColors.warning),
              ),
              title: Text(rec.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Priority: High (Exam soon)'),
              trailing: ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudyTimerScreen(course: rec))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('START'),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context, String title, String subtitle) {
     return Center(
       child: Column(
         children: [
           Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey[300]),
           const SizedBox(height: 16),
           Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
           Text(subtitle, style: const TextStyle(color: Colors.grey)),
         ],
       ),
     );
  }

  Widget _buildDailyTip(bool isDark) {
    return FutureBuilder<String>(
      future: TipService().fetchRandomTip(),
      builder: (ctx, snapshot) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4)
              )
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tips_and_updates_rounded, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text('DAILY INSIGHT', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                snapshot.connectionState == ConnectionState.waiting 
                  ? 'Loading wisdom...' 
                  : (snapshot.data ?? 'Stay consistent!'),
                style: const TextStyle(fontSize: 16, height: 1.5, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      },
    );
  }
}
