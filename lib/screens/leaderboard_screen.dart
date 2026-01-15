import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../providers/courses_provider.dart';
import '../theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Leaderboard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBrand,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryBrand,
          tabs: const [
            Tab(text: 'Study Time'),
            Tab(text: 'Grades'),
            Tab(text: 'Streaks'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryBrand.withOpacity(0.05), Colors.white],
          ),
        ),
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStudyTimeLeaderboard(),
              _buildGradesLeaderboard(),
              _buildStreaksLeaderboard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudyTimeLeaderboard() {
    // Mock data - replace with real API call
    final leaderboard = [
      {'name': 'Alice Johnson', 'value': 1250, 'avatar': 'A', 'isMe': false},
      {'name': 'Bob Smith', 'value': 1180, 'avatar': 'B', 'isMe': false},
      {'name': 'You', 'value': 1050, 'avatar': 'Y', 'isMe': true},
      {'name': 'Charlie Brown', 'value': 980, 'avatar': 'C', 'isMe': false},
      {'name': 'Diana Prince', 'value': 920, 'avatar': 'D', 'isMe': false},
    ];

    return _buildLeaderboardList(
      leaderboard,
      'minutes',
      Icons.timer_outlined,
      const Color(0xFF2563EB),
    );
  }

  Widget _buildGradesLeaderboard() {
    final leaderboard = [
      {'name': 'Emma Watson', 'value': 95.5, 'avatar': 'E', 'isMe': false},
      {'name': 'Frank Miller', 'value': 92.3, 'avatar': 'F', 'isMe': false},
      {'name': 'You', 'value': 88.7, 'avatar': 'Y', 'isMe': true},
      {'name': 'Grace Lee', 'value': 85.2, 'avatar': 'G', 'isMe': false},
      {'name': 'Henry Ford', 'value': 82.1, 'avatar': 'H', 'isMe': false},
    ];

    return _buildLeaderboardList(
      leaderboard,
      'avg',
      Icons.grade_outlined,
      const Color(0xFFF59E0B),
    );
  }

  Widget _buildStreaksLeaderboard() {
    final leaderboard = [
      {'name': 'Ivy Chen', 'value': 45, 'avatar': 'I', 'isMe': false},
      {'name': 'You', 'value': 32, 'avatar': 'Y', 'isMe': true},
      {'name': 'Jack Ryan', 'value': 28, 'avatar': 'J', 'isMe': false},
      {'name': 'Kate Wilson', 'value': 21, 'avatar': 'K', 'isMe': false},
      {'name': 'Leo Martinez', 'value': 18, 'avatar': 'L', 'isMe': false},
    ];

    return _buildLeaderboardList(
      leaderboard,
      'days',
      Icons.local_fire_department_outlined,
      const Color(0xFFDC2626),
    );
  }

  Widget _buildLeaderboardList(
    List<Map<String, dynamic>> leaderboard,
    String unit,
    IconData icon,
    Color color,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaderboard.length + 1, // +1 for top 3 podium
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildPodium(leaderboard.take(3).toList(), unit, color);
        }

        final actualIndex = index - 1;
        if (actualIndex >= leaderboard.length) return const SizedBox();

        final entry = leaderboard[actualIndex];
        final rank = actualIndex + 1;

        return _buildLeaderboardCard(
          rank: rank,
          name: entry['name'] as String,
          value: entry['value'],
          unit: unit,
          avatar: entry['avatar'] as String,
          isMe: entry['isMe'] as bool,
          color: color,
          icon: icon,
        ).animate(delay: (actualIndex * 50).ms).fadeIn().slideX(begin: -0.2, end: 0);
      },
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> top3, String unit, Color color) {
    if (top3.length < 3) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPodiumPlace(top3[1], 2, unit, const Color(0xFF94A3B8), 100),
          _buildPodiumPlace(top3[0], 1, unit, const Color(0xFFFBBF24), 130),
          _buildPodiumPlace(top3[2], 3, unit, const Color(0xFFCD7F32), 80),
        ],
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildPodiumPlace(Map<String, dynamic> entry, int rank, String unit, Color medalColor, double height) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CircleAvatar(
              radius: rank == 1 ? 40 : 35,
              backgroundColor: medalColor.withOpacity(0.2),
              child: Text(
                entry['avatar'] as String,
                style: GoogleFonts.outfit(
                  fontSize: rank == 1 ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  color: medalColor,
                ),
              ),
            ),
            Positioned(
              bottom: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: medalColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#$rank',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          entry['name'] as String,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          '${entry['value']} $unit',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [medalColor, medalColor.withOpacity(0.6)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard({
    required int rank,
    required String name,
    required dynamic value,
    required String unit,
    required String avatar,
    required bool isMe,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMe ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isMe ? Border.all(color: color, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(rank).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: _getRankColor(rank),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Text(
              avatar,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (isMe)
                  Text(
                    'You',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                '$value $unit',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFBBF24); // Gold
    if (rank == 2) return const Color(0xFF94A3B8); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return AppColors.textSecondary;
  }
}
