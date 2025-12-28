import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/course.dart';
import '../models/study_session.dart';
import '../providers/courses_provider.dart';
import 'study_timer_screen.dart';
import 'chat_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final TextEditingController _notesController = TextEditingController();

  void _showEditNotesDialog(BuildContext context, Course course) {
    _notesController.text = course.notes ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Course Notes'),
        content: SizedBox(
          width: 600,
          child: TextField(
            controller: _notesController,
            maxLines: 15,
            decoration: const InputDecoration(
              hintText: 'Use Markdown for formatting (**bold**, # Header, - list)',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<CoursesProvider>().updateCourse(course.id, notes: _notesController.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save Notes'),
          ),
        ],
      ),
    );
  }

  void _showEditCourseDialog(BuildContext context, Course course) {
    final nameController = TextEditingController(text: course.name);
    final professorController = TextEditingController(text: course.professor);
    DateTime? selectedDate = course.examDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Course Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: professorController, decoration: const InputDecoration(labelText: 'Professor')),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Exam: ${DateFormat.yMMMd().format(selectedDate!)}'),
                trailing: const Icon(Icons.edit_calendar),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate!,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                context.read<CoursesProvider>().updateCourse(
                  course.id,
                  name: nameController.text,
                  professor: professorController.text,
                  examDate: selectedDate,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompleteCourseDialog(BuildContext context, Course course) {
    final gradeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Great job! Enter your final grade.'),
            const SizedBox(height: 16),
            TextField(
              controller: gradeController,
              decoration: const InputDecoration(labelText: 'Grade (18-30L)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final grade = int.tryParse(gradeController.text);
              if (grade == null) return;
              context.read<CoursesProvider>().updateCourseStatus(course.id, 'completed', grade: grade);
              Navigator.pop(ctx);
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coursesProvider = context.watch<CoursesProvider>();
    final course = coursesProvider.courses.firstWhere(
      (c) => c.id == widget.courseId, 
      orElse: () => Course(id: '0', name: 'Not Found', professor: '', examDate: DateTime.now())
    );

    if (course.id == '0') return const Scaffold(body: Center(child: Text('Course not found')));

    final totalMinutes = course.sessions.fold(0, (sum, s) => sum + s.durationMinutes);

    return Scaffold(
      appBar: AppBar(
        title: Text(course.name),
        actions: [
          IconButton(icon: const Icon(Icons.note_alt_rounded), onPressed: () => _showEditNotesDialog(context, course)),
          IconButton(icon: const Icon(Icons.settings_rounded), onPressed: () => _showEditCourseDialog(context, course)),
          IconButton(
            icon: const Icon(Icons.chat_bubble_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(courseId: course.id, courseName: course.name),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 900;

          final headerAndStats = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernHeader(course),
              const SizedBox(height: 24),
              _buildStatsRow(totalMinutes, course.sessions.length),
              const SizedBox(height: 24),
              if (!course.isCompleted) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudyTimerScreen(course: course))),
                    icon: const Icon(Icons.timer_rounded),
                    label: const Text('START FOCUS SESSION'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCompleteCourseDialog(context, course),
                    icon: const Icon(Icons.verified_rounded),
                    label: const Text('MARK AS COMPLETED'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          );

          final notesAndHistory = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotesWidget(course),
              const SizedBox(height: 32),
              _buildHistoryWidget(course),
            ],
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: SingleChildScrollView(padding: const EdgeInsets.all(32), child: headerAndStats)),
                const VerticalDivider(width: 1),
                Expanded(flex: 3, child: SingleChildScrollView(padding: const EdgeInsets.all(32), child: notesAndHistory)),
              ],
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                headerAndStats,
                const SizedBox(height: 32),
                notesAndHistory,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernHeader(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Professor', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(course.professor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: course.isCompleted ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                course.status.toUpperCase(),
                style: TextStyle(color: course.isCompleted ? Colors.green : Colors.blue, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Exam Date', style: TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          DateFormat('EEEE, d MMMM y').format(course.examDate),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (course.grade != null) ...[
          const SizedBox(height: 16),
          const Text('Final Grade', style: TextStyle(color: Colors.grey, fontSize: 12)),
          Text('${course.grade}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.indigo)),
        ]
      ],
    );
  }

  Widget _buildStatsRow(int totalMin, int sessionCount) {
    return Row(
      children: [
        _buildStatBox('Study Time', '${totalMin ~/ 60}h ${totalMin % 60}m', Icons.timer_outlined),
        const SizedBox(width: 16),
        _buildStatBox('Sessions', '$sessionCount', Icons.history_rounded),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesWidget(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Quick Thoughts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Icon(Icons.notes_rounded, size: 16, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.02),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.indigo.withOpacity(0.1)),
          ),
          child: course.notes == null || course.notes!.isEmpty
              ? const Text('Click the note icon above to add Markdown notes!', style: TextStyle(color: Colors.grey))
              : MarkdownBody(data: course.notes!),
        ),
      ],
    );
  }

  Widget _buildHistoryWidget(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activity History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (course.sessions.isEmpty)
          const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No sessions logged yet.')))
        else
          ...course.sessions.reversed.map((s) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(s.type == 'pomodoro' ? Icons.timer_rounded : Icons.history_rounded, color: Colors.indigo),
              title: Text('${s.durationMinutes} Minutes'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat.MMMEd().format(s.date)),
                  if (s.notes != null && s.notes!.isNotEmpty)
                    Text(s.notes!, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
              trailing: PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditSessionDialog(context, course, s);
                  } else if (value == 'delete') {
                    _showDeleteSessionDialog(context, course.id, s.id, s.durationMinutes);
                  }
                },
              ),
            ),
          )),
      ],
    );
  }

  void _showEditSessionDialog(BuildContext context, Course course, StudySession session) {
    final durationController = TextEditingController(text: session.durationMinutes.toString());
    final notesController = TextEditingController(text: session.notes ?? '');
    String selectedType = session.type;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Session'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Duration (minutes)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'stopwatch', child: Text('Stopwatch')),
                    DropdownMenuItem(value: 'pomodoro', child: Text('Pomodoro')),
                  ],
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final newDuration = int.tryParse(durationController.text);
                if (newDuration == null || newDuration <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid duration')));
                  return;
                }
                
                Navigator.pop(ctx);
                // Call provider to update session
                await context.read<CoursesProvider>().updateSession(
                  course.id,
                  session.id,
                  durationMinutes: newDuration,
                  notes: notesController.text,
                  type: selectedType,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session updated!')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteSessionDialog(BuildContext context, String courseId, String sessionId, int minutes) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Session?'),
        content: Text('Remove this $minutes-minute study session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<CoursesProvider>().removeSession(courseId, sessionId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session deleted')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
