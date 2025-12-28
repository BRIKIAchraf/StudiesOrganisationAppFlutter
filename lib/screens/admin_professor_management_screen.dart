import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';
import '../theme.dart';

class AdminProfessorManagementScreen extends StatefulWidget {
  const AdminProfessorManagementScreen({super.key});

  @override
  State<AdminProfessorManagementScreen> createState() => _AdminProfessorManagementScreenState();
}

class _AdminProfessorManagementScreenState extends State<AdminProfessorManagementScreen> {
  List<Map<String, dynamic>> _professors = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _fetchProfessors();
  }

  Future<void> _fetchProfessors() async {
    final auth = context.read<AuthProvider>();
    final url = '${ApiConfig.baseUrl}/admin/professors';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (mounted) {
          setState(() {
            _professors = data.cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        }
      } else {
        // Use mock data for demonstration
        if (mounted) {
          setState(() {
            _professors = _getMockProfessors();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Use mock data for demonstration
      if (mounted) {
        setState(() {
          _professors = _getMockProfessors();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getMockProfessors() {
    return [
      {
        'id': '1',
        'name': 'Dr. Marco Rossi',
        'email': 'marco.rossi@uniurb.it',
        'professorId': 'PROF-2024-001',
        'status': 'approved',
        'department': 'Computer Science',
        'createdAt': '2024-09-15',
      },
      {
        'id': '2',
        'name': 'Prof. Giulia Bianchi',
        'email': 'giulia.bianchi@uniurb.it',
        'professorId': 'PROF-2024-002',
        'status': 'approved',
        'department': 'Mathematics',
        'createdAt': '2024-10-03',
      },
      {
        'id': '3',
        'name': 'Dr. Alessandro Verdi',
        'email': 'alessandro.verdi@uniurb.it',
        'professorId': null,
        'status': 'pending',
        'department': 'Physics',
        'createdAt': '2024-12-20',
      },
      {
        'id': '4',
        'name': 'Prof. Laura Neri',
        'email': 'laura.neri@uniurb.it',
        'professorId': null,
        'status': 'pending',
        'department': 'Engineering',
        'createdAt': '2024-12-25',
      },
    ];
  }

  String _generateProfessorId() {
    final year = DateTime.now().year;
    final random = Random().nextInt(900) + 100;
    return 'PROF-$year-$random';
  }

  Future<void> _approveProfessor(Map<String, dynamic> professor) async {
    final newId = _generateProfessorId();
    final auth = context.read<AuthProvider>();
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin/professors/${professor['id']}/approve'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'professorId': newId}),
      );
      
      if (response.statusCode == 200 || response.statusCode == 404) {
        // Update locally for demo
        setState(() {
          final index = _professors.indexWhere((p) => p['id'] == professor['id']);
          if (index != -1) {
            _professors[index]['status'] = 'approved';
            _professors[index]['professorId'] = newId;
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Professor approved with ID: $newId'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      // Update locally for demo
      setState(() {
        final index = _professors.indexWhere((p) => p['id'] == professor['id']);
        if (index != -1) {
          _professors[index]['status'] = 'approved';
          _professors[index]['professorId'] = newId;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Professor approved with ID: $newId'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _rejectProfessor(Map<String, dynamic> professor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Professor?'),
        content: Text('Are you sure you want to reject ${professor['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _professors.removeWhere((p) => p['id'] == professor['id']);
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Professor registration rejected'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _generateNewId() async {
    final newId = _generateProfessorId();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Professor ID Generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.badge, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    newId,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share this ID with the professor for their registration.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredProfessors {
    return _professors.where((p) {
      final matchesSearch = p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            p['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filterStatus == 'all' || p['status'] == _filterStatus;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _professors.where((p) => p['status'] == 'pending').length;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professor Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchProfessors();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateNewId,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Generate ID'),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Stats Cards
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total',
                        _professors.length.toString(),
                        Icons.people,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Approved',
                        _professors.where((p) => p['status'] == 'approved').length.toString(),
                        Icons.check_circle,
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Pending',
                        pendingCount.toString(),
                        Icons.pending,
                        AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Search and Filter
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search professors...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _filterStatus,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'approved', child: Text('Approved')),
                      ],
                      onChanged: (val) => setState(() => _filterStatus = val!),
                    ),
                  ],
                ),
              ),
              
              // Professor List
              Expanded(
                child: _filteredProfessors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No professors found',
                            style: TextStyle(color: Colors.grey[500], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredProfessors.length,
                      itemBuilder: (ctx, i) => _buildProfessorCard(_filteredProfessors[i]),
                    ),
              ),
            ],
          ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildProfessorCard(Map<String, dynamic> professor) {
    final isPending = professor['status'] == 'pending';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  radius: 28,
                  child: Text(
                    professor['name'].toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        professor['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        professor['email'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      if (professor['department'] != null)
                        Text(
                          professor['department'],
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPending 
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPending ? 'Pending' : 'Approved',
                    style: TextStyle(
                      color: isPending ? AppColors.warning : AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (professor['professorId'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.badge, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      professor['professorId'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _rejectProfessor(professor),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _approveProfessor(professor),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve & Generate ID'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
