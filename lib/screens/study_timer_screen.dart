import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/courses_provider.dart';
import '../models/study_session.dart';
import '../models/course.dart';
import '../services/notification_service.dart';

class StudyTimerScreen extends StatefulWidget {
  final Course course;
  const StudyTimerScreen({super.key, required this.course});

  @override
  State<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

enum TimerMode { stopwatch, pomodoro }
enum PomodoroPhase { focus, breakTime }

class _StudyTimerScreenState extends State<StudyTimerScreen> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  TimerMode _mode = TimerMode.stopwatch;
  PomodoroPhase _phase = PomodoroPhase.focus;
  int _pomodoroCycles = 0;

  static const int focusDuration = 25 * 60;
  static const int breakDuration = 5 * 60;

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_mode == TimerMode.stopwatch) {
            _seconds++;
          } else {
            if (_seconds > 0) {
              _seconds--;
            } else {
              _handlePomodoroTransition();
            }
          }
        });
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  void _handlePomodoroTransition() {
    if (_phase == PomodoroPhase.focus) {
      _phase = PomodoroPhase.breakTime;
      _seconds = breakDuration;
      _pomodoroCycles++;
      NotificationService().showInstantNotification('Focus Session Complete!', 'Time for a 5 minute break. Good job!');
    } else {
      _phase = PomodoroPhase.focus;
      _seconds = focusDuration;
      NotificationService().showInstantNotification('Break Over!', 'Time to focus again. Let\'s go!');
    }
    _timer?.cancel();
    _isRunning = false; 
  }

  void _switchMode(TimerMode newMode) {
    if (_isRunning) return;
    setState(() {
      _mode = newMode;
      _seconds = _mode == TimerMode.pomodoro ? focusDuration : 0;
      _phase = PomodoroPhase.focus;
    });
  }

  void _finishSession() async {
    _timer?.cancel();
    final minutes = _mode == TimerMode.stopwatch 
        ? (_seconds / 60).ceil() 
        : (_pomodoroCycles * 25);
        
    if (minutes < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session too short!')));
      Navigator.pop(context);
      return;
    }

    final session = StudySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      durationMinutes: minutes,
      notes: _mode == TimerMode.pomodoro ? 'Pomodoro session ($_pomodoroCycles cycles)' : 'Timed session',
      type: _mode == TimerMode.stopwatch ? 'stopwatch' : 'pomodoro',
    );

    await context.read<CoursesProvider>().addSession(widget.course.id, session);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logged $minutes minutes!')));
      Navigator.pop(context);
    }
  }

  String _formatTime(int totalSeconds) {
    final hours = (totalSeconds / 3600).floor();
    final minutes = ((totalSeconds % 3600) / 60).floor();
    final seconds = totalSeconds % 60;
    return '${hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : ''}${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isPomodoro = _mode == TimerMode.pomodoro;
    Color themeColor = isPomodoro 
        ? (_phase == PomodoroPhase.focus ? Colors.indigo : Colors.teal) 
        : Colors.indigo;

    return Scaffold(
      appBar: AppBar(title: const Text('Focus Timer')),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(widget.course.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Mode Toggle
            Container(
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(25)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   _buildModeButton(TimerMode.stopwatch, 'Stopwatch'),
                   _buildModeButton(TimerMode.pomodoro, 'Pomodoro'),
                ],
              ),
            ),
            
            const Spacer(),
            
            if (isPomodoro) 
              Text(_phase == PomodoroPhase.focus ? 'FOCUSING' : 'BREAK TIME', 
                   style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            
            const SizedBox(height: 20),
            
            // Timer Ring
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: isPomodoro ? (_seconds / (_phase == PomodoroPhase.focus ? focusDuration : breakDuration)) : null,
                    strokeWidth: 10,
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    backgroundColor: themeColor.withOpacity(0.1),
                  ),
                ),
                Text(_formatTime(_seconds), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
              ],
            ),
            
            const Spacer(),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton.large(
                  onPressed: _toggleTimer,
                  backgroundColor: themeColor,
                  child: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                ),
                if (_seconds > 0 || _pomodoroCycles > 0) ...[
                  const SizedBox(width: 30),
                  FloatingActionButton(
                    onPressed: _finishSession,
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.stop_rounded, color: Colors.white),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(TimerMode mode, String label) {
    bool selected = _mode == mode;
    return GestureDetector(
      onTap: () => _switchMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.indigo : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey)),
      ),
    );
  }
}
