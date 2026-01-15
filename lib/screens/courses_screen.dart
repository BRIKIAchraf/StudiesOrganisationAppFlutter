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



  // Global filter state
  static String? _statusFilter;
  static bool _sortByDate = false;
  static String? _professorFilter; // Add this

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isStudent = auth.userRole == 'student';
    final provider = context.watch<CoursesProvider>();
    
    // Extract Profs
    final allCourses = [...provider.courses, ...provider.availableCourses];
    final professors = allCourses.map((c) => c.professorName).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterDialog(professors),
          ),
        ],
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
           // Active Filters Chips
           if (_statusFilter != null || _professorFilter != null || _sortByDate)
             SingleChildScrollView(
               scrollDirection: Axis.horizontal,
               padding: const EdgeInsets.symmetric(horizontal: 12),
               child: Row(
                 children: [
                   if (_sortByDate) 
                      Chip(
                        label: const Text('Sorted by Date'), 
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _sortByDate = false),
                        backgroundColor: Colors.blue.shade50,
                      ),
                   if (_statusFilter != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Chip(
                          label: Text('Status: $_statusFilter'),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => setState(() => _statusFilter = null),
                          backgroundColor: Colors.orange.shade50,
                        ),
                      ),
                   if (_professorFilter != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Chip(
                          label: Text('Prof: $_professorFilter'),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => setState(() => _professorFilter = null),
                          backgroundColor: Colors.purple.shade50,
                        ),
                      ),
                 ],
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
        _CoursesList(type: 'my', searchQuery: _searchQuery, statusFilter: _statusFilter, professorFilter: _professorFilter, sortByDate: _sortByDate),
        _CoursesList(type: 'discovery', searchQuery: _searchQuery, statusFilter: null, professorFilter: _professorFilter, sortByDate: _sortByDate),
      ],
    );
  }

  Widget _buildProfessorView() {
    return _CoursesList(type: 'my', searchQuery: _searchQuery, statusFilter: null, professorFilter: _professorFilter, sortByDate: _sortByDate);
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
  
  void _showFilterDialog(List<String> professors) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _FilterBottomSheet(
        professors: professors,
        onApply: () => setState(() {}),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final VoidCallback onApply;
  final List<String> professors;
  const _FilterBottomSheet({required this.onApply, required this.professors});

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Text('Filters & Sort', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
               TextButton(
                 onPressed: () {
                   setState(() {
                      _CoursesScreenState._sortByDate = false;
                      _CoursesScreenState._statusFilter = null;
                      _CoursesScreenState._professorFilter = null;
                   });
                 },
                 child: const Text('Reset'),
               )
            ],
          ),
          const SizedBox(height: 16),
          const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          SwitchListTile(
            title: const Text('Exam Date'),
            value: _CoursesScreenState._sortByDate,
            onChanged: (val) => setState(() => _CoursesScreenState._sortByDate = val),
          ),
          const SizedBox(height: 16),
          const Text('Filter Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('All', null),
              _buildFilterChip('Pending', 'pending'),
              _buildFilterChip('Approved', 'approved'),
            ],
          ),
          const SizedBox(height: 16),
           const Text('Professor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
           DropdownButton<String>(
             isExpanded: true,
             hint: const Text('Select Professor'),
             value: _CoursesScreenState._professorFilter,
             items: [
               const DropdownMenuItem(value: null, child: Text('All Professors')),
               ...widget.professors.map((p) => DropdownMenuItem(value: p, child: Text(p))),
             ],
             onChanged: (val) {
               setState(() => _CoursesScreenState._professorFilter = val);
             },
           ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('APPLY'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final selected = _CoursesScreenState._statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
         setState(() {
           _CoursesScreenState._statusFilter = value;
         });
      },
      selectedColor: Colors.indigo.withOpacity(0.2),
      checkmarkColor: Colors.indigo,
      labelStyle: TextStyle(color: selected ? Colors.indigo : Colors.black),
    );
  }
}

class _CoursesList extends StatelessWidget {
  final String type; 
  final String searchQuery;
  final String? statusFilter;
  final String? professorFilter;
  final bool sortByDate;

  const _CoursesList({
    required this.type, 
    required this.searchQuery,
    this.statusFilter,
    this.professorFilter,
    required this.sortByDate,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoursesProvider>();
    List<Course> courses = type == 'my' ? provider.courses : provider.availableCourses;
    
    // 1. Filter
    var filtered = courses.where((c) {
      final matchesSearch = c.title.toLowerCase().contains(searchQuery.toLowerCase()) || 
                            c.professorName.toLowerCase().contains(searchQuery.toLowerCase());
      
      bool matchesStatus = true;
      if (type == 'my' && statusFilter != null) {
        matchesStatus = c.enrollmentStatus == statusFilter;
      }
      
      bool matchesProf = true;
      if (professorFilter != null) {
        matchesProf = c.professorName == professorFilter;
      }

      return matchesSearch && matchesStatus && matchesProf;
    }).toList();

    // 2. Sort
    if (sortByDate) {
      filtered.sort((a, b) => a.examDate.compareTo(b.examDate));
    } else {
      // Default alpha
       filtered.sort((a, b) => a.title.compareTo(b.title));
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              type == 'my' ? 'No courses found.' : 'No courses found.',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
         // IMPLEMENTING SYNC
         await context.read<CoursesProvider>().loadData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: filtered.length,
        itemBuilder: (ctx, i) => _CourseCard(course: filtered[i], isDiscovery: type == 'discovery'),
      ),
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
            Text('Exam: ${DateFormat.yMMMd().format(course.examDate)}', style: TextStyle(fontSize: 12, color: _getExamColor(course.examDate))),
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

  Color _getExamColor(DateTime date) {
    if (date.difference(DateTime.now()).inDays < 3) return Colors.red;
    if (date.difference(DateTime.now()).inDays < 7) return Colors.orange;
    return Colors.grey;
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
