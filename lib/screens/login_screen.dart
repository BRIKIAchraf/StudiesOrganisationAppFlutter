import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

import '../theme.dart';
import '../services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _professorIdController = TextEditingController();
  
  bool _isObscure = true;
  bool _isLoading = false;
  bool _isLogin = true;
  String _selectedRole = 'student';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _professorIdController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    try {
      if (_isLogin) {
        await auth.login(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        await auth.register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
          role: _selectedRole,
          professorId: _selectedRole == 'professor' ? _professorIdController.text : null,
        );
        setState(() => _isLogin = true);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful! Please login.')));
        }
      }
    } catch (error) {
       // ... existing error handling
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // LOGO
                        Container(
                             width: 100,
                             height: 100,
                             decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.1)),
                             child: Icon(Icons.school, size: 50, color: AppColors.primary)
                        ),
                        const SizedBox(height: 20),
                        
                        // TITLE
                        Text(
                          _isLogin ? 'Welcome Back!' : 'Join Us Today',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(height: 20),
                        
                        // REGISTRATION FIELDS
                        if (!_isLogin) ...[
                             TextFormField(
                               controller: _nameController,
                               decoration: InputDecoration(
                                 labelText: 'Full Name', 
                                 prefixIcon: const Icon(Icons.person),
                                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
                               ),
                               validator: (v) => v!.isEmpty ? 'Required' : null,
                             ),
                             const SizedBox(height: 16),
                             DropdownButtonFormField<String>(
                               value: _selectedRole,
                               decoration: InputDecoration(
                                  labelText: 'I am a...',
                                  prefixIcon: const Icon(Icons.badge),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
                               ),
                               items: const [
                                 DropdownMenuItem(value: 'student', child: Text('Student')),
                                 DropdownMenuItem(value: 'professor', child: Text('Professor')),
                               ],
                               onChanged: (v) => setState(() => _selectedRole = v!),
                             ),
                             if (_selectedRole == 'professor') ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                   controller: _professorIdController,
                                   decoration: InputDecoration(
                                     labelText: 'Professor ID (Admin provided)',
                                     prefixIcon: const Icon(Icons.admin_panel_settings),
                                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
                                   ),
                                   validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                             ],
                             const SizedBox(height: 16),
                        ],
                        
                        // COMMON FIELDS (Email/Pass)
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                             labelText: 'Email Address', 
                             prefixIcon: const Icon(Icons.email),
                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => !v!.contains('@') ? 'Invalid Email' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _isObscure,
                          decoration: InputDecoration(
                             labelText: 'Password', 
                             prefixIcon: const Icon(Icons.lock),
                             suffixIcon: IconButton(
                               icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
                               onPressed: () => setState(() => _isObscure = !_isObscure),
                             ),
                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
                          ),
                          validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
                        ),
                        const SizedBox(height: 24),
                        
                        // ACTION BUTTON
                        if (_isLoading) 
                          const CircularProgressIndicator()
                        else 
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                               backgroundColor: AppColors.primary,
                               foregroundColor: Colors.white,
                               minimumSize: const Size(double.infinity, 50),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                            ),
                            child: Text(
                               _isLogin ? 'LOGIN' : 'REGISTER', 
                               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                          ),
                          
                        // SWITCH MODE text
                        const SizedBox(height: 16),
                        TextButton(
                           onPressed: () => setState(() { _isLogin = !_isLogin; _formKey.currentState?.reset(); }),
                           child: Text(
                              _isLogin ? "No account? Create one." : "Have an account? Login.",
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)
                           )
                        ),
                        
                        // BIOMETRIC (Login Only)
                        if (_isLogin) 
                           Padding(
                             padding: const EdgeInsets.only(top: 10),
                             child: IconButton(
                               icon: const Icon(Icons.fingerprint, size: 40, color: Colors.grey),
                               onPressed: () async {
                                 // Biometric Logic (same as before)
                                 final bioService = BiometricService();
                                 if (await bioService.isBiometricAvailable()) {
                                    if(await bioService.authenticate() && context.mounted) {
                                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authenticated!')));
                                       // In real app, load secure credentials here
                                    }
                                 }
                               },
                             ),
                           )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
