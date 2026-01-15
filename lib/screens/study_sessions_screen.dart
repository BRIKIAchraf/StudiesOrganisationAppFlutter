import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/courses_provider.dart';

class StudySessionsScreen extends StatefulWidget {
  const StudySessionsScreen({super.key});

  @override
  State<StudySessionsScreen> createState() => _StudySessionsScreenState();
}

class _StudySessionsScreenState extends State<StudySessionsScreen> {
  String? _selectedCourseId;

  Future<void> _exportStats(List<Map<String, dynamic>> sessions) async {
    final doc = pw.Document();
    
    // Add page
    doc.addPage(pw.Page(
      build: (pw.Context context) {
         return pw.Center(
           child: pw.Column(
             mainAxisAlignment: pw.MainAxisAlignment.center,
             children: [
               pw.Text('Study Report', style: pw.TextStyle(fontSize: 40)),
               pw.SizedBox(height: 20),
               pw.Text('Total Sessions: ${sessions.length}'),
               pw.SizedBox(height: 20),
               pw.ListView.builder(
                 itemCount: sessions.length > 20 ? 20 : sessions.length, // Limit for demo
                 itemBuilder: (ctx, i) {
                    final s = sessions[i]['session'];
                    final c = sessions[i]['courseName'];
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('$c - ${s.durationMinutes} min - ${s.notes}')
                    );
                 }
               )
             ]
           )
         );
      }
    ));

    await Printing.sharePdf(bytes: await doc.save(), filename: 'study_report.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final coursesProvider = context.watch<CoursesProvider>();
    
    // Flatten and filter sessions
    final List<Map<String, dynamic>> allSessions = [];
    for (var course in coursesProvider.courses) {
      if (_selectedCourseId != null && course.id != _selectedCourseId) continue;
      
      for (var session in course.sessions) {
        allSessions.add({
          'courseId': course.id,
          'courseName': course.title,
          'session': session,
        });
      }
    }
    
    // Sort by date descending
    allSessions.sort((a, b) => b['session'].date.compareTo(a['session'].date));

    // Note: Since this screen is used in main_screen logic which assumes a Body content rather than Scaffold,
    // IF it's called from Drawer, it needs Scaffold. IF called from Tab, it might complicate things.
    // However, MainScreen uses it as a body page but provides its own Scaffold.
    // BUT! Since we want an AppBar button for Export, we probably want a specific scaffold for this screen 
    // OR we inject the action. 
    // Given MainScreen structure: "body: pages[_selectedIndex]", and AppBar titles.
    // MainScreen doesn't dynamically change AppBar actions.
    // So simpler: Add a Floating Action Button or a header button for export.

    return Column(
      children: [
        const SizedBox(height: 100), // Space for transparent AppBar
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter Courses', style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.indigo),
                tooltip: 'Export PDF Report',
                onPressed: () => _exportStats(allSessions),
              )
            ],
          ),
        ),

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
                  label: Text(c.title),
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
