import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/courses_provider.dart';
import '../providers/auth_provider.dart';
import '../models/course.dart';
import 'chat_screen.dart';
import 'study_sessions_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Tab length will be dynamic based on role in build potentially, but TabController needs fixed length.
    // Better to init in build or use DefaultTabController.
    // Let's rely on build to re-init if needed or use max length?
    // Actually, safest to check role in initState? Role is in Provider.
    // Let's use DefaultTabController in build to handle dynamic tabs easily.
  }

  @override
  void dispose() {
    // _tabController.dispose(); // Removed if using DefaultTabController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Find course
    final provider = context.watch<CoursesProvider>();
    final auth = context.watch<AuthProvider>();
    
    Course? course;
    try {
      course = provider.courses.firstWhere((c) => c.id == widget.courseId, 
         orElse: () => provider.availableCourses.firstWhere((c) => c.id == widget.courseId));
    } catch (e) {
      // Not found
    }

    if (course == null) return const Scaffold(body: Center(child: Text('Course not found')));

    final isStudent = auth.userRole == 'student';
    final isProfessor = auth.userRole == 'professor';
    final isPending = isStudent && course.enrollmentStatus == 'pending';
    final isApproved = !isStudent || course.enrollmentStatus == 'approved'; // Profesors "approved" by default context
    final isNone = isStudent && course.enrollmentStatus == null;
    
    // Tabs
    final tabs = <Tab>[
      const Tab(text: 'Info'),
      const Tab(text: 'Chat'),
      const Tab(text: 'Documents'),
    ];
    if (isProfessor) {
      tabs.add(const Tab(text: 'Students'));
    }

    // Load docs on entry if approved
    if (isApproved) {
       Future.microtask(() => context.read<CoursesProvider>().loadDocuments(widget.courseId));
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(course.title),
          bottom: isApproved 
            ? TabBar(
                tabs: tabs,
                isScrollable: true, // Allow more tabs
              ) 
            : null,
        ),
        body: isApproved 
          ? TabBarView(
              children: [
                _buildInfoTab(course, isStudent),
                ChatScreen(courseId: course.id, courseName: course.title),
                _buildDocumentsTab(course, isStudent),
                if (isProfessor) _buildStudentsTab(course),
              ],
            )
          : _buildRestrictedView(course, isPending, isNone),
      ),
    );
  }

  Widget _buildRestrictedView(Course course, bool isPending, bool isNone) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPending ? Icons.hourglass_top_rounded : Icons.lock_outline, 
            size: 80, 
            color: Colors.grey
          ),
          const SizedBox(height: 24),
          Text(
            isPending ? 'Request Pending' : 'Access Restricted',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isPending 
                ? 'Your Enrollment request is waiting for Professor ${course.professorName} to approve.'
                : 'You must enroll in this course to access materials and chat.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
          if (isNone)
            ElevatedButton(
              onPressed: () {
                context.read<CoursesProvider>().enrollInCourse(course.id);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white
              ),
              child: const Text('REQUEST ACCESS'),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(Course course, bool isStudent) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Professor', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Text(course.professorName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 32),
                const Text('Exam Date', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.event_rounded, color: Colors.indigo),
                    const SizedBox(width: 12),
                    Text(DateFormat.yMMMMd().format(course.examDate), style: const TextStyle(fontSize: 18)),
                  ],
                ),
                const Divider(height: 32),
                const Text('Description', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(course.description.isEmpty ? 'No description available.' : course.description),
              ],
            ),
          ),
        ),
        if (isStudent) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
             onPressed: () {
               // Quick session logic
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudySessionsScreen()));
             }, 
             icon: const Icon(Icons.timer), 
             label: const Text('Start Study Session')
          )
        ]
      ],
    );
  }

  Widget _buildDocumentsTab(Course course, bool isStudent) {
    final provider = context.watch<CoursesProvider>();
    final docs = provider.currentDocuments;

    return Column(
      children: [
        if (!isStudent)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _uploadDocumentDialog(context, course.id),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload PDF'),
            ),
          ),
        Expanded(
          child: docs.isEmpty 
            ? const Center(child: Text('No documents uploaded yet.'))
            : ListView.builder(
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final doc = docs[i];
                  return ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(doc.title),
                    subtitle: Text(DateFormat.Hms().format(doc.uploadedAt)),
                    onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('PDF viewing is currently disabled')),
                       );
                    },
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildStudentsTab(Course course) {
    return _StudentsList(courseId: course.id);
  }

  void _uploadDocumentDialog(BuildContext context, String courseId) {
    final titleController = TextEditingController();
    final pathController = TextEditingController(); // For demo, manual path
    // In real app: FilePicker
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Document Title')),
             TextField(controller: pathController, decoration: const InputDecoration(labelText: 'File Path / URL')),
             // Add Button "Pick File" which sets pathController text
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
             onPressed: () {
                context.read<CoursesProvider>().uploadDocument(courseId, titleController.text, pathController.text);
                Navigator.pop(ctx);
             },
             child: const Text('Upload'),
          )
        ],
      ),
    );
  }
}

class _StudentsList extends StatefulWidget {
  final String courseId;
  const _StudentsList({required this.courseId});

  @override
  State<_StudentsList> createState() => _StudentsListState();
}

class _StudentsListState extends State<_StudentsList> {
  // Use FutureBuilder to load fresh list
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<CoursesProvider>().fetchEnrollments(widget.courseId),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return const Center(child: Text('No students enrolled yet.'));
        }

        final enrollments = snapshot.data as List; // List<Enrollment>
        
        return ListView.builder(
          itemCount: enrollments.length,
          itemBuilder: (ctx, i) {
            final enrollment = enrollments[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(child: Text(enrollment.studentName[0].toUpperCase())),
                title: Text(enrollment.studentName),
                subtitle: Text('Status: ${enrollment.status.toUpperCase()}'),
                trailing: enrollment.status == 'pending'
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            await context.read<CoursesProvider>().approveStudent(widget.courseId, enrollment.id, 'approved');
                            setState(() {}); // Refresh
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            await context.read<CoursesProvider>().approveStudent(widget.courseId, enrollment.id, 'rejected');
                            setState(() {}); // Refresh
                          },
                        ),
                      ],
                    )
                  : enrollment.status == 'approved' 
                    ? const Icon(Icons.verified, color: Colors.green)
                    : const Icon(Icons.block, color: Colors.red),
              ),
            );
          },
        );
      },
    );
  }
}
