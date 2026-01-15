import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/courses_provider.dart';
import '../models/course.dart';
import '../theme.dart';
import 'study_timer_screen.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning & Stats'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.indigo,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.indigo,
          tabs: const [
            Tab(text: 'Sessions'),
            Tab(text: 'Calendar'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SessionsList(),
          _CalendarView(),
          _StatsView(),
        ],
      ),
    );
  }
}

class _SessionsList extends StatelessWidget {
  const _SessionsList();

  @override
  Widget build(BuildContext context) {
    // Reusing logic from old StudySessionsScreen roughly
    return Consumer<CoursesProvider>(
      builder: (context, provider, child) {
        final courses = provider.courses;
        final allSessions = courses.expand((c) => c.sessions).toList();
        allSessions.sort((a, b) => b.date.compareTo(a.date));

        if (allSessions.isEmpty) {
          return const Center(
            child: Text('No study sessions recorded yet.', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allSessions.length,
          itemBuilder: (ctx, i) {
            final session = allSessions[i];
            final course = courses.firstWhere((c) => c.id == session.courseId, orElse: () => Course(id: '?', title: 'Unknown', professorId: '', professorName: '', examDate: DateTime.now(), description: '', sessions: []));
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: session.type == 'pomodoro' ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  child: Icon(
                    session.type == 'pomodoro' ? Icons.timer : Icons.watch_later_outlined,
                    color: session.type == 'pomodoro' ? Colors.red : Colors.blue,
                  ),
                ),
                title: Text(course.title),
                subtitle: Text(DateFormat.yMMMd().add_jm().format(session.date)),
                trailing: Text(
                  '${session.durationMinutes} min',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CalendarView extends StatefulWidget {
  const _CalendarView();

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoursesProvider>();
    final courses = provider.courses;

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2023, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
             setState(() => _calendarFormat = format);
          },
          eventLoader: (day) {
            return courses.where((c) => isSameDay(c.examDate, day)).toList();
          },
          calendarStyle: const CalendarStyle(
            markerDecoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _selectedDay == null 
            ? const Center(child: Text('Select a day to see exams'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Exams on ${DateFormat.yMMMd().format(_selectedDay!)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...courses.where((c) => isSameDay(c.examDate, _selectedDay)).map((c) => 
                    Card(
                      color: Colors.red.withOpacity(0.1),
                      child: ListTile(
                        leading: const Icon(Icons.event, color: Colors.red),
                        title: Text(c.title),
                        subtitle: Text('Prof. ${c.professorName}'),
                      ),
                    )
                  ).toList(),
                  if (courses.where((c) => isSameDay(c.examDate, _selectedDay)).isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No exams scheduled for this day.'),
                    )
                ],
              ),
        ),
      ],
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoursesProvider>();
    final data = provider.weeklyStudyData; // Map<int, int> weekday -> minutes
    
    // Prepare spots
    List<FlSpot> spots = [];
    for(int i=1; i<=7; i++) {
      spots.add(FlSpot(i.toDouble(), (data[i] ?? 0).toDouble()));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Study Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        int idx = value.toInt() - 1;
                        if(idx >= 0 && idx < days.length) return Text(days[idx]);
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.3))),
                minX: 1,
                maxX: 7,
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.indigo,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.indigo.withOpacity(0.2)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text('Course Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _buildPieChart(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(CoursesProvider provider) {
    final map = <String, int>{};
    for (var c in provider.courses) {
       for(var s in c.sessions) {
         map[c.title] = (map[c.title] ?? 0) + s.durationMinutes;
       }
    }
    
    if(map.isEmpty) return const Center(child: Text('No data'));

    return PieChart(
      PieChartData(
        sections: map.entries.map((e) {
           return PieChartSectionData(
             value: e.value.toDouble(),
             title: '${e.key}\n${e.value}m',
             color: Colors.primaries[e.key.hashCode % Colors.primaries.length],
             radius: 80,
             titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
           );
        }).toList(),
      ),
    );
  }
}
