import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/courses_provider.dart';
import '../models/course.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String _searchQuery = '';
  bool _sortByDate = true;

  // Just show the dialog here, keeping it simple
  void _showAddCourseDialog(BuildContext context) {
    final nameController = TextEditingController();
    final professorController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Course Name'),
              ),
              TextField(
                controller: professorController,
                decoration: const InputDecoration(labelText: 'Professor (Optional)'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDate == null
                          ? 'No Date Chosen!'
                          : 'Exam Date: ${DateFormat.yMd().format(selectedDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        // set state inside dialog using StatefulBuilder if needed, 
                        // but simpler to just rebuild this small part or navigate properly.
                        // Actually, for a dialog, we need a way to update the text.
                        // Let's us a StatefulBuilder for the dialog content or just be lazy 
                        // and rely on the variable since showDatePicker is async and we are inside a closure?
                        // No, the Text widget won't update unless we call setState somewhere.
                        // Let's use a dirty hack: close and reopen? No that's bad.
                        // Correct student way: StatefulBuilder or just a separate widget.
                        // I'll stick to a simple StatefulBuilder in the content.
                        (ctx as Element).markNeedsBuild(); // Very hacky or just set variable.
                        // Let's use StatefulBuilder properly.
                      }
                      // Wait, I can't use markNeedsBuild on context easily.
                      // Let's just trust the user to remember the date or update UI?
                      // Better:
                      // selectedDate = picked;
                    },
                    child: const Text('Choose Date'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Basic validation
              if (nameController.text.isEmpty) return;
              
              // If no date, default into the future? Or force it?
              // Let's force it for simplicity of "Exam Project"
              // Currently the UI for date picking above is broken because I didn't implement the update logic.
              // I will fix this in a second pass or just use a helper method.
              // Actually, I'll rewrite this dialog logic right now to be cleaner.
            }, 
            child: const Text('Add'),
          )
        ],
      ),
    );
  }
  
  // Refactored Dialog Logic
  void _startAddNewCourse(BuildContext context) {
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
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, 
            right: 20,
            top: 20
          ),
          child: const NewCourseForm(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final coursesProvider = context.watch<CoursesProvider>();
    
    // Filter and Sort
    List<Course> filteredCourses = coursesProvider.courses.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             c.professor.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (_sortByDate) {
      filteredCourses.sort((a, b) => a.examDate.compareTo(b.examDate));
    } else {
      filteredCourses.sort((a, b) => a.name.compareTo(b.name));
    }
    
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 100), // Space for transparent AppBar
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Sort by date'),
                Switch(
                  value: _sortByDate,
                  onChanged: (val) => setState(() => _sortByDate = val),
                  activeColor: Colors.indigo,
                ),
                const SizedBox(width: 16),
              ],
            ),
            Expanded(
              child: filteredCourses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No courses yet.' : 'No matches found.',
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: filteredCourses.length,
                    itemBuilder: (ctx, index) {
                      final course = filteredCourses[index];
                      final daysLeft = course.isCompleted ? 999 : course.examDate.difference(DateTime.now()).inDays;
                      Color urgencyColor;
                      if (daysLeft < 3) {
                        urgencyColor = Colors.red;
                      } else if (daysLeft < 7) {
                        urgencyColor = Colors.orange;
                      } else {
                        urgencyColor = Colors.indigo;
                      }

                      return Dismissible(
                        key: Key('course_${course.id}'),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(15)),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: const Icon(Icons.check_rounded, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            if (!course.isCompleted) {
                              await context.read<CoursesProvider>().updateCourseStatus(course.id, 'completed', grade: 30);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course completed!')));
                              }
                            }
                            return false;
                          } else {
                            _showDeleteConfirm(context, course.id, course.name);
                            return false;
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: urgencyColor.withOpacity(0.3), width: 1),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor: urgencyColor.withOpacity(0.1),
                              child: Icon(
                                course.isCompleted ? Icons.check_circle_rounded : Icons.book_outlined, 
                                color: urgencyColor
                              ),
                            ),
                            title: Text(
                              course.name, 
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 18,
                                color: course.isCompleted ? Colors.grey : null,
                                decoration: course.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Text('${course.professor} • ${DateFormat.yMMMd().format(course.examDate)}'),
                            trailing: course.isCompleted 
                              ? const Icon(Icons.verified_rounded, color: Colors.green)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${daysLeft}d', style: TextStyle(color: urgencyColor, fontWeight: FontWeight.bold)),
                                    const Text('left', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: course.id)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _startAddNewCourse(context),
            label: const Text('New Course'),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
  
  @override
  void initState() {
    super.initState();
    // Load data once
    Future.delayed(Duration.zero).then((_) {
      Provider.of<CoursesProvider>(context, listen: false).loadData();
    });
  }

  void _showDeleteConfirm(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course?'),
        content: Text('Are you sure you want to remove "$name"? All study sessions will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<CoursesProvider>().deleteCourse(id);
              Navigator.pop(ctx);
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Minimal form widget for the modal
class NewCourseForm extends StatefulWidget {
  const NewCourseForm({super.key});

  @override
  State<NewCourseForm> createState() => _NewCourseFormState();
}

class _NewCourseFormState extends State<NewCourseForm> {
  final _nameController = TextEditingController();
  final _profController = TextEditingController();
  DateTime? _selectedDate;

  void _submitData() {
    if (_nameController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name and select a date.')),
      );
      return; 
    }
    
    context.read<CoursesProvider>().addCourse(
      _nameController.text,
      _profController.text,
      _selectedDate!,
    );
    
    Navigator.of(context).pop();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() => _selectedDate = pickedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Add Course',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Course Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _profController,
          decoration: const InputDecoration(
            labelText: 'Professor',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _selectedDate == null
                ? 'No Exam Date Chosen!'
                : 'Exam Date: ${DateFormat.yMMMd().format(_selectedDate!)}',
          ),
          trailing: TextButton(
            onPressed: _presentDatePicker,
            child: const Text('CHOOSE DATE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submitData,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: const Text('SAVE COURSE'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
