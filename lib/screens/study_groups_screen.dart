import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../providers/study_groups_provider.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';

class StudyGroupsScreen extends StatefulWidget {
  const StudyGroupsScreen({super.key});

  @override
  State<StudyGroupsScreen> createState() => _StudyGroupsScreenState();
}

class _StudyGroupsScreenState extends State<StudyGroupsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load groups on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudyGroupsProvider>().loadGroups();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Force rebuild on localization change if needed, but standard localized widgets handle it.
    // However, strings here should use AppLocalizations.
    final l10n = AppLocalizations.of(context);
    // If l10n is null (e.g. context not ready), fallback or simple English?
    // Providers handling data should use their own strings or just IDs.
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n?.studyGroups ?? 'Study Groups',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBrand,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryBrand,
          tabs: [
            Tab(text: 'My Groups'), // Could capitalize or localize
            Tab(text: 'Discover'),
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
          child: Consumer<StudyGroupsProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (provider.error != null) {
                return Center(child: Text(provider.error!, style: const TextStyle(color: Colors.red)));
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildMyGroups(provider.myGroups),
                  _buildDiscoverGroups(provider.availableGroups),
                ],
              );
            }
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        icon: const Icon(Icons.add),
        label: Text(l10n?.create ?? 'Create'),
        backgroundColor: AppColors.primaryBrand,
      ),
    );
  }

  Widget _buildMyGroups(List<StudyGroup> groups) {
    if (groups.isEmpty) {
      return _buildEmptyState(
        'No Groups Yet',
        'Create or join a study group to collaborate with classmates',
        Icons.groups_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        return _buildGroupCard(groups[index], true)
            .animate(delay: (index * 100).ms)
            .fadeIn()
            .slideX(begin: -0.2, end: 0);
      },
    );
  }

  Widget _buildDiscoverGroups(List<StudyGroup> groups) {
    if (groups.isEmpty) {
      return _buildEmptyState(
        'No Available Groups',
        'Be the first to create a study group!',
        Icons.search_off,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        return _buildGroupCard(groups[index], false)
            .animate(delay: (index * 100).ms)
            .fadeIn()
            .slideX(begin: -0.2, end: 0);
      },
    );
  }

  Widget _buildGroupCard(StudyGroup group, bool isMember) {
    final isFull = group.memberIds.length >= group.maxMembers;
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
           // Just a toast for now as detail implementation is separate task
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening ${group.name}...'))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBrand.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.groups,
                        color: AppColors.primaryBrand,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            group.courseName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isMember)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Member',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  group.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${group.memberIds.length}/${group.maxMembers} ${l10n?.members ?? "members"}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (!isMember)
                      ElevatedButton(
                        onPressed: isFull ? null : () => _joinGroup(group),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBrand,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isFull ? 'Full' : (l10n?.joinGroup ?? 'Join'),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ).animate().fadeIn().scale(),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String? selectedCourseId;
    String? selectedCourseName; // Capture name as well
    
    // Hardcoded for demo/simplicity or fetch from CoursesProvider
    // Ideally we should use CoursesProvider to list courses.
    // For now keeping dropdown with hardcoded values but mapped correctly could be verbose.
    // Let's assume we want to mock or just text input for now?
    // The previous implementation had hardcoded items.
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Create Study Group', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Course',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cs101', child: Text('Computer Science 101')),
                  DropdownMenuItem(value: 'math201', child: Text('Mathematics 201')),
                  DropdownMenuItem(value: 'phys101', child: Text('Physics 101')),
                ],
                onChanged: (value) {
                  selectedCourseId = value;
                  // Capture name based on value
                  if (value == 'cs101') selectedCourseName = 'Computer Science 101';
                  if (value == 'math201') selectedCourseName = 'Mathematics 201';
                  if (value == 'phys101') selectedCourseName = 'Physics 101';
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && selectedCourseId != null) {
                final success = await context.read<StudyGroupsProvider>().createGroup(
                  nameController.text,
                  selectedCourseId!,
                  selectedCourseName ?? 'Course',
                  descController.text,
                );
                
                if (ctx.mounted) {
                    Navigator.pop(ctx);
                    if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Study group created!')),
                        );
                    } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to create group')),
                        );
                    }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _joinGroup(StudyGroup group) async {
    final success = await context.read<StudyGroupsProvider>().joinGroup(group.id);
    if (mounted) {
        if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Joined ${group.name}!')),
            );
        } else {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to join group')),
            );
        }
    }
  }
}
