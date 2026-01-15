import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

class IntegrationsService {
  static final IntegrationsService _instance = IntegrationsService._internal();
  factory IntegrationsService() => _instance;
  IntegrationsService._internal();

  // ===== GOOGLE CALENDAR INTEGRATION =====
  
  Future<void> addToCalendar(
      String title, String description, DateTime startTime, DateTime endTime) async {
    return addToGoogleCalendar(
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
    );
  }

  Future<void> addToGoogleCalendar({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
  }) async {
    final String startFormatted = startTime.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.')[0] + 'Z';
    final String endFormatted = endTime.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.')[0] + 'Z';
    
    final String calendarUrl = 'https://calendar.google.com/calendar/render?action=TEMPLATE'
        '&text=${Uri.encodeComponent(title)}'
        '&dates=$startFormatted/$endFormatted'
        '${description != null ? '&details=${Uri.encodeComponent(description)}' : ''}'
        '${location != null ? '&location=${Uri.encodeComponent(location)}' : ''}';
    
    final uri = Uri.parse(calendarUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch Google Calendar');
    }
  }

  // ===== EXPORT PDF =====
  
  Future<void> exportStudyReportToPDF({
    required String studentName,
    required List<Map<String, dynamic>> courses,
    required int totalStudyTime,
    required double averageGrade,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Study Report',
                style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Student: $studentName', style: const pw.TextStyle(fontSize: 16)),
              pw.Text('Generated: ${DateTime.now().toString().split('.')[0]}', style: const pw.TextStyle(fontSize: 12)),
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              // Summary
              pw.Text('Summary', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Total Study Time: $totalStudyTime minutes'),
              pw.Text('Average Grade: ${averageGrade.toStringAsFixed(1)}'),
              pw.Text('Total Courses: ${courses.length}'),
              pw.SizedBox(height: 20),
              
              // Courses
              pw.Text('Courses', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              
              ...courses.map((course) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(course['title'] ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Professor: ${course['professor'] ?? 'N/A'}'),
                    pw.Text('Grade: ${course['grade'] ?? 'N/A'}'),
                    pw.Text('Exam Date: ${course['examDate'] ?? 'N/A'}'),
                  ],
                ),
              )).toList(),
            ],
          );
        },
      ),
    );

    // Save and share
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'study_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // ===== SOCIAL MEDIA SHARING =====
  
  Future<void> shareAchievement({
    required String achievementName,
    required String description,
  }) async {
    final String text = '🎉 I just unlocked "$achievementName" on UniConnect!\n\n$description\n\n#UniConnect #StudyGoals';
    
    await Share.share(
      text,
      subject: 'Achievement Unlocked!',
    );
  }

  Future<void> shareStudyStats({
    required int studyTime,
    required int streak,
    required double averageGrade,
  }) async {
    final String text = '''
📚 My Study Stats on UniConnect:
⏱️ Study Time: $studyTime minutes
🔥 Streak: $streak days
📊 Average Grade: ${averageGrade.toStringAsFixed(1)}

Join me on UniConnect! #StudyMotivation #UniConnect
''';
    
    await Share.share(text);
  }

  Future<void> shareCourse({
    required String courseName,
    required String professorName,
  }) async {
    final String text = 'Check out this course on UniConnect: $courseName by $professorName!\n\n#UniConnect #Learning';
    
    await Share.share(text);
  }

  // ===== ZOOM/TEAMS INTEGRATION =====
  
  Future<void> joinZoomMeeting(String meetingUrl) async {
    final uri = Uri.parse(meetingUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch Zoom meeting');
    }
  }

  Future<void> joinTeamsMeeting(String meetingUrl) async {
    final uri = Uri.parse(meetingUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch Teams meeting');
    }
  }

  Future<void> scheduleZoomMeeting({
    required String topic,
    required DateTime startTime,
    required int durationMinutes,
  }) async {
    // This would typically use Zoom API
    // For now, open Zoom web scheduler
    final uri = Uri.parse('https://zoom.us/meeting/schedule');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ===== EMAIL INTEGRATION =====
  
  Future<void> sendEmailToProf({
    required String professorEmail,
    required String subject,
    String? body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: professorEmail,
      query: 'subject=${Uri.encodeComponent(subject)}'
          '${body != null ? '&body=${Uri.encodeComponent(body)}' : ''}',
    );
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not launch email client');
    }
  }

  // ===== EXTERNAL LINKS =====
  
  Future<void> openExternalLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch URL: $url');
    }
  }

  Future<void> openCourseWebsite(String courseUrl) async {
    await openExternalLink(courseUrl);
  }

  Future<void> openUniversityPortal(String portalUrl) async {
    await openExternalLink(portalUrl);
  }
}

// Widget helper for integrations
class IntegrationsMenu extends StatelessWidget {
  final String? courseId;
  final String? courseName;

  const IntegrationsMenu({
    super.key,
    this.courseId,
    this.courseName,
  });

  @override
  Widget build(BuildContext context) {
    final integrations = IntegrationsService();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.share),
      onSelected: (value) async {
        try {
          switch (value) {
            case 'calendar':
              await integrations.addToGoogleCalendar(
                title: courseName ?? 'Study Session',
                startTime: DateTime.now(),
                endTime: DateTime.now().add(const Duration(hours: 1)),
                description: 'Study session for $courseName',
              );
              break;
            case 'share':
              await integrations.shareCourse(
                courseName: courseName ?? 'Course',
                professorName: 'Professor',
              );
              break;
            case 'export':
              await integrations.exportStudyReportToPDF(
                studentName: 'Student',
                courses: [],
                totalStudyTime: 0,
                averageGrade: 0.0,
              );
              break;
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Action completed!')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'calendar',
          child: Row(
            children: [
              Icon(Icons.calendar_today),
              SizedBox(width: 8),
              Text('Add to Google Calendar'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share),
              SizedBox(width: 8),
              Text('Share on Social Media'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf),
              SizedBox(width: 8),
              Text('Export to PDF'),
            ],
          ),
        ),
      ],
    );
  }
}
