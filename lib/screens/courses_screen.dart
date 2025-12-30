import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/courses_provider.dart';
import '../providers/auth_provider.dart';
import '../models/course.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load both data sets
    Future.microtask(() {
      final provider = context.read<CoursesProvider>();
      provider.loadMyCourses();
      provider.loadAvailableCourses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isStudent = auth.userRole == 'student';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: isStudent 
          ? TabBar(
              controller: _tabController,
              labelColor: Colors.indigo,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.indigo,
              tabs: const [
                Tab(text: 'My Courses'),
                Tab(text: 'Find Courses'),
              ],
            )
          : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Theme.of(context).cardColor.withOpacity(0.8),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: isStudent ? _buildStudentView() : _buildProfessorView(),
          ),
        ],
      ),
      floatingActionButton: !isStudent 
        ? FloatingActionButton.extended(
            onPressed: () => _showAddCourseDialog(context),
            label: const Text('New Course'),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          )
        : null,
    );
  }

  Widget _buildStudentView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _CoursesList(type: 'my', searchQuery: _searchQuery),
        _CoursesList(type: 'discovery', searchQuery: _searchQuery),
      ],
    );
  }

  Widget _buildProfessorView() {
    return _CoursesList(type: 'my', searchQuery: _searchQuery);
  }

  void _showAddCourseDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
         return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20, 
            right: 20,
            top: 20
          ),
          child: const NewCourseForm(),
        );
      },
    );
  }
}

class _CoursesList extends StatelessWidget {
  final String type; // 'my' or 'discovery'
  final String searchQuery;

  const _CoursesList({required this.type, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoursesProvider>();
    final courses = type == 'my' ? provider.courses : provider.availableCourses;
    
    final filtered = courses.where((c) {
      final matchesSearch = c.title.toLowerCase().contains(searchQuery.toLowerCase()) || 
                            c.professorName.toLowerCase().contains(searchQuery.toLowerCase());
      if (type == 'discovery') {
        // Exclude enrolled courses from discovery? optional, but better UX
        // For now show all, simple.
        return matchesSearch;
      }
      return matchesSearch;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              type == 'my' ? 'No enrolled courses.' : 'No courses found.',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => _CourseCard(course: filtered[i], isDiscovery: type == 'discovery'),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final bool isDiscovery;

  const _CourseCard({required this.course, required this.isDiscovery});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    
    // Status Logic
    bool isPending = course.enrollmentStatus == 'pending';
    bool isApproved = course.enrollmentStatus == 'approved';
    bool isRejected = course.enrollmentStatus == 'rejected';
    
    // Check if enrolled locally (for discovery list)
    if (isDiscovery) {
       // Ideally we check if this course ID exists in "my courses"
       // But assuming the backend list handles excluding or we handle it in provider
       // Let's assume Discovery list is RAW courses.
       // We can check local enrollment state if we merge lists, but for now simple.
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.withOpacity(0.1),
          child: Text(
            course.title.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prof. ${course.professorName}'),
            if (isDiscovery)
              Text('Exam: ${DateFormat.yMMMd().format(course.examDate)}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: isDiscovery 
          ? ElevatedButton.icon(
              onPressed: () {
                // Determine if we are already enrolled
                // Simple check: iterate my courses
                final myCourses = context.read<CoursesProvider>().courses;
                final already = myCourses.any((c) => c.id == course.id);
                
                if (already) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Already enrolled! Check "My Courses".')));
                } else {
                   context.read<CoursesProvider>().enrollInCourse(course.id);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent!')));
                }
              }, 
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('Enroll'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            )
          : _buildStatusBadge(context),
        onTap: () {
          // Navigate to details
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: course.id)),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    if (context.read<AuthProvider>().userRole == 'professor') {
       return const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey);
    }
  
    String text = 'Active';
    Color color = Colors.green;
    
    if (course.enrollmentStatus == 'pending') {
      text = 'Pending';
      color = Colors.orange;
    } else if (course.enrollmentStatus == 'rejected') {
      text = 'Rejected';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class NewCourseForm extends StatefulWidget {
  const NewCourseForm({super.key});

  @override
  State<NewCourseForm> createState() => _NewCourseFormState();
}

class _NewCourseFormState extends State<NewCourseForm> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Add New Course', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        ListTile(
          title: Text(_selectedDate == null ? 'No Date Chosen' : DateFormat.yMMMd().format(_selectedDate!)),
          trailing: TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context, 
                initialDate: DateTime.now(), 
                firstDate: DateTime.now(), 
                lastDate: DateTime(2030)
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: const Text('PICK DATE'),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isEmpty || _selectedDate == null) return;
            context.read<CoursesProvider>().addCourse(
              _titleController.text,
              _descController.text,
              _selectedDate!
            );
            Navigator.pop(context);
          },
          child: const Text('CREATE'),
        )
      ],
    );
  }
}
