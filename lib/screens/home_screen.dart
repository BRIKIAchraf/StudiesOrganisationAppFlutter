import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/tip_service.dart';
import '../providers/courses_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'admin_dashboard_screen.dart';
import 'study_timer_screen.dart';

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
    
    // Calculate total study time
    int totalMinutes = 0;
    for (var course in coursesProvider.courses) {
      totalMinutes += course.totalStudyMinutes;
    }

     final auth = context.watch<AuthProvider>();

    final rec = coursesProvider.recommendedCourse;

    return RefreshIndicator(
        onRefresh: () => context.read<CoursesProvider>().loadData(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // ... (welcome header logic)
            // Welcome Header
            Text(
              'Hello, ${auth.userName}!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              auth.userRole == 'professor' || auth.userRole == 'admin' 
                ? 'Managing your teaching excellence' 
                : 'Ready for another study session?',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            if (auth.userRole == 'professor' || auth.userRole == 'admin') ...[
              Card(
                elevation: 4,
                shadowColor: Colors.amber.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.amber[50]!, Colors.white]),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.psychology_rounded, color: Colors.amber, size: 30),
                    title: const Text('Professor Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Global analytics & student progress'),
                    trailing: const Icon(Icons.keyboard_arrow_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Professor Specific Stats
              Row(
                children: [
                   _buildStatCard(context, 'Teaching Load', '${coursesProvider.courses.length} courses', Icons.auto_stories_rounded, Colors.indigo),
                   _buildStatCard(context, 'Total Students', '1,240 enrolled', Icons.people_alt_rounded, Colors.teal),
                ],
              ),
              const SizedBox(height: 20),
            ],
            // Student-only study metrics
            if (auth.userRole == 'student' || auth.userRole == null) ...[
              // Student Study Today Highlight Card
              Card(
                elevation: 0,
                color: Colors.indigo.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.indigo.withOpacity(0.1))),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(15)),
                        child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('STUDY TODAY', style: TextStyle(letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                          Text('${(coursesProvider.studyTimeToday / 60).toStringAsFixed(1)} Hours', 
                               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Smart Recommendation Card
              if (rec != null) ...[
                const Text('Smart Recommendation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: Colors.amber.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.amber.withOpacity(0.3))),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.bolt_rounded, color: Colors.white)),
                    title: Text('Study ${rec.title} Next', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Priority: High (Nearest exam or low efforts)'),
                    trailing: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudyTimerScreen(course: rec))),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.white, elevation: 0),
                      child: const Text('START'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
            if (auth.userRole == 'professor') ...[
              // Professor Management Shortcuts
              const Text('Active Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                   _buildStatCard(context, 'Exam Requests', '12 pending', Icons.assignment_late_rounded, Colors.orange),
                   _buildStatCard(context, 'Resource Views', '450 today', Icons.visibility_rounded, Colors.blue),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Achievement Badges Section
            if (coursesProvider.achievementBadges.isNotEmpty) ...[
              const Text('Academic Achievements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: coursesProvider.achievementBadges.map((badge) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(badge, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Weekly Chart Section
            const Text('Weekly Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
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
                          return Text(days[value.toInt() - 1], style: const TextStyle(fontSize: 10, color: Colors.grey));
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
                          color: Colors.indigo,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
              
              // Academic Stats Comparison
              Row(
                children: [
                  _buildStatCard(
                    context, 
                    'Credits/GPA', 
                    coursesProvider.averageGrade.toStringAsFixed(1), 
                    Icons.grade_rounded, 
                    Colors.amber
                  ),
                   _buildStatCard(
                    context, 
                    'Courses Done', 
                    '${coursesProvider.completedCoursesCount}/${coursesProvider.courses.length}', 
                    Icons.assignment_turned_in_rounded, 
                    Colors.green
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Total Study Time Summary
              Row(
                children: [
                  _buildStatCard(
                    context, 
                    'Total Study', 
                    '${(totalMinutes / 60).toStringAsFixed(1)}h', 
                    Icons.timer_rounded, 
                    Colors.blue
                  ),
                  _buildStatCard(
                    context, 
                    'Active Goals', 
                    '${coursesProvider.courses.length - coursesProvider.completedCoursesCount}', 
                    Icons.pending_actions_rounded, 
                    Colors.orange
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Daily Tip Section
              FutureBuilder<String>(
                future: TipService().fetchRandomTip(),
                builder: (ctx, snapshot) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: settings.isDarkMode 
                          ? [Colors.teal[900]!, Colors.teal[800]!]
                          : [Colors.teal[50]!, Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.teal[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tips_and_updates, color: Colors.teal),
                            SizedBox(width: 8),
                            Text('DAILY TIP', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.connectionState == ConnectionState.waiting 
                            ? 'Fetching a tip for you...' 
                            : (snapshot.data ?? 'Stay focused and hydrated!'),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Next Exam Section
              const Text(
                'Upcoming Exams',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              if (upcoming.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text("No upcoming exams! Add a course.")),
                  ),
                )
              else
                ...upcoming.take(2).map((nextExam) {
                  final daysLeft = nextExam.examDate.difference(DateTime.now()).inDays + 1;
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(nextExam.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Prof. ${nextExam.professorName}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat.MMMd().format(nextExam.examDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            daysLeft == 0 ? "TODAY" : (daysLeft == 1 ? "TOMORROW" : "In $daysLeft days"),
                            style: TextStyle(
                              color: daysLeft <= 3 ? Colors.red : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
        ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
