import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/courses_provider.dart';
import '../models/course.dart';
import '../services/notification_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Course> _getEventsForDay(DateTime day, List<Course> courses) {
    return courses.where((course) {
      if (course.examDate == null) return false;
      return isSameDay(course.examDate, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<CoursesProvider>().courses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Calendar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
         decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                eventLoader: (day) => _getEventsForDay(day, courses),
                calendarStyle: CalendarStyle(
                  markerDecoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.indigo,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _selectedDay == null 
                  ? const Center(child: Text('Select a date to view exams')) 
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: _getEventsForDay(_selectedDay!, courses).map((course) {
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            leading: Container(
                               padding: const EdgeInsets.all(10),
                               decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(10)),
                               child: const Icon(Icons.event, color: Colors.red),
                            ),
                            title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Exam at ${course.examDate!.hour}:${course.examDate!.minute.toString().padLeft(2, '0')}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.notifications_active_outlined, color: Colors.indigo),
                              onPressed: () => _showReminderDialog(course),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReminderDialog(Course course) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set Reminder: ${course.title}'),
        content: const Text('When would you like to be reminded?'),
        actions: [
          TextButton(
            onPressed: () {
               // 1 Hour before
               final date = course.examDate.subtract(const Duration(hours: 1));
               if (date.isAfter(DateTime.now())) {
                 NotificationService().scheduleNotification(
                   course.id.hashCode * 10, 
                   'Study Time! 📚', 
                   '1 hour until exam: ${course.title}', 
                   date
                 );
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder set for 1 hour before.')));
               }
               Navigator.pop(ctx);
            },
            child: const Text('1 Hour Before'),
          ),
          TextButton(
             onPressed: () {
               // 1 Day before
               final date = course.examDate.subtract(const Duration(days: 1));
               NotificationService().scheduleNotification(
                   course.id.hashCode * 10 + 1, 
                   'Exam Tomorrow! 📝', 
                   'Prepare for ${course.title}', 
                   date
                 );
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder set for 1 day before.')));
               Navigator.pop(ctx);
            },
            child: const Text('24 Hours Before'),
          ),
        ],
      ),
    );
  }
}
