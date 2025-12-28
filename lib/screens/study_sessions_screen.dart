import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/courses_provider.dart';

class StudySessionsScreen extends StatefulWidget {
  const StudySessionsScreen({super.key});

  @override
  State<StudySessionsScreen> createState() => _StudySessionsScreenState();
}

class _StudySessionsScreenState extends State<StudySessionsScreen> {
  String? _selectedCourseId;

  @override
  Widget build(BuildContext context) {
    final coursesProvider = context.watch<CoursesProvider>();
    
    // Flatten and filter sessions
    final allSessions = [];
    for (var course in coursesProvider.courses) {
      if (_selectedCourseId != null && course.id != _selectedCourseId) continue;
      
      for (var session in course.sessions) {
        allSessions.add({
          'courseId': course.id,
          'courseName': course.name,
          'session': session,
        });
      }
    }
    
    // Sort by date descending
    allSessions.sort((a, b) => b['session'].date.compareTo(a['session'].date));

    return Column(
      children: [
        const SizedBox(height: 100), // Space for transparent AppBar
        
        // Premium Course Filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All Courses'),
                selected: _selectedCourseId == null,
                onSelected: (selected) => setState(() => _selectedCourseId = null),
                selectedColor: Colors.indigo.withOpacity(0.2),
                checkmarkColor: Colors.indigo,
              ),
              const SizedBox(width: 8),
              ...coursesProvider.courses.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(c.name),
                  selected: _selectedCourseId == c.id,
                  onSelected: (selected) => setState(() => _selectedCourseId = selected ? c.id : null),
                  selectedColor: Colors.indigo.withOpacity(0.2),
                  checkmarkColor: Colors.indigo,
                ),
              )),
            ],
          ),
        ),

        Expanded(
          child: allSessions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('No study sessions found.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: allSessions.length,
                itemBuilder: (ctx, i) {
                  final item = allSessions[i];
                  final session = item['session'];
                  final courseName = item['courseName'];
                  final courseId = item['courseId'];
                  
                  return Dismissible(
                    key: Key(session.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      context.read<CoursesProvider>().removeSession(courseId, session.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Session deleted')),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.history_edu_rounded, color: Colors.indigo),
                        ),
                        title: Text(courseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${session.durationMinutes} mins • ${session.notes.isEmpty ? "No notes" : session.notes}'),
                        trailing: Text(
                          DateFormat('MMM dd\nHH:mm').format(session.date),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}
