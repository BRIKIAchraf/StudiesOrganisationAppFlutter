import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';

class ProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;
  final Widget? child;
  final bool showPercentage;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 12,
    this.color = const Color(0xFF2563EB),
    this.backgroundColor = const Color(0xFFE5E7EB),
    this.child,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: progress,
              strokeWidth: strokeWidth,
              color: color,
              backgroundColor: backgroundColor,
            ),
          ),
          if (child != null)
            child!
          else if (showPercentage)
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.outfit(
                fontSize: size * 0.2,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -pi / 2; // Start from top
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class ExamCountdownRing extends StatelessWidget {
  final DateTime examDate;
  final double size;

  const ExamCountdownRing({
    super.key,
    required this.examDate,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = examDate.difference(now);

    if (diff.isNegative) {
      return _buildFinishedState();
    }

    final totalDays = 30; // Assume 30 days preparation period
    final remainingDays = diff.inDays;
    final progress = (totalDays - remainingDays) / totalDays;

    Color ringColor;
    if (remainingDays <= 3) {
      ringColor = const Color(0xFFDC2626); // Red
    } else if (remainingDays <= 7) {
      ringColor = const Color(0xFFF59E0B); // Orange
    } else {
      ringColor = const Color(0xFF2563EB); // Blue
    }

    return ProgressRing(
      progress: progress.clamp(0.0, 1.0),
      size: size,
      color: ringColor,
      showPercentage: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            remainingDays.toString(),
            style: GoogleFonts.outfit(
              fontSize: size * 0.25,
              fontWeight: FontWeight.bold,
              color: ringColor,
            ),
          ),
          Text(
            remainingDays == 1 ? 'Day' : 'Days',
            style: GoogleFonts.inter(
              fontSize: size * 0.08,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${diff.inHours % 24}h ${diff.inMinutes % 60}m',
            style: GoogleFonts.inter(
              fontSize: size * 0.06,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedState() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: size * 0.3, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              'Finished',
              style: GoogleFonts.outfit(
                fontSize: size * 0.1,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudyProgressRing extends StatelessWidget {
  final int studiedMinutes;
  final int targetMinutes;
  final double size;

  const StudyProgressRing({
    super.key,
    required this.studiedMinutes,
    required this.targetMinutes,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final progress = targetMinutes > 0 ? (studiedMinutes / targetMinutes).clamp(0.0, 1.0) : 0.0;

    return ProgressRing(
      progress: progress,
      size: size,
      color: const Color(0xFF059669), // Green
      showPercentage: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            studiedMinutes.toString(),
            style: GoogleFonts.outfit(
              fontSize: size * 0.2,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF059669),
            ),
          ),
          Text(
            'of $targetMinutes min',
            style: GoogleFonts.inter(
              fontSize: size * 0.08,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
