import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioController;
  late TextEditingController _uniController;
  late TextEditingController _deptController;
  late TextEditingController _yearController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _bioController = TextEditingController(text: user?.bio ?? '');
    _uniController = TextEditingController(text: user?.university ?? '');
    _deptController = TextEditingController(text: user?.department ?? '');
    _yearController = TextEditingController(text: user?.year ?? '');
  }

  @override
  void dispose() {
    _bioController.dispose();
    _uniController.dispose();
    _deptController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await context.read<AuthProvider>().updateProfile(
        bio: _bioController.text,
        university: _uniController.text,
        department: _deptController.text,
        year: _yearController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar Placeholder
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.indigo.withOpacity(0.1),
                child: const Icon(Icons.person, size: 50, color: Colors.indigo),
              ),
              TextButton.icon(
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar upload coming soon!')));
                }, 
                icon: const Icon(Icons.camera_alt), 
                label: const Text('Change Photo')
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _uniController,
                decoration: const InputDecoration(labelText: 'University', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _deptController,
                decoration: const InputDecoration(labelText: 'Department/Major', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Year of Study', border: OutlineInputBorder()),
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SAVE CHANGES'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
