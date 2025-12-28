import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/biometric_service.dart';
import '../theme.dart';

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
  bool _isLogin = true;
  bool _isLoading = false;
  String _selectedRole = 'student';
  bool _enableBiometric = false;
  bool _biometricAvailable = false;
  bool _canUseBiometricLogin = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final biometricService = BiometricService();
    final available = await biometricService.isBiometricAvailable();
    final canUse = await context.read<AuthProvider>().canUseBiometric();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _canUseBiometricLogin = canUse;
      });
    }
  }

  Future<void> _biometricLogin() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    
    try {
      final success = await auth.biometricLogin();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          enableBiometric: _enableBiometric,
        );
      } else {
        await auth.register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
          role: _selectedRole,
          professorId: _selectedRole == 'professor' ? _professorIdController.text : null,
        );
        // Automatically switch to login and show success
        setState(() => _isLogin = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please login.')),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // University Logo
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.primary,
                                    child: const Icon(
                                      Icons.school,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _isLogin ? 'Welcome Back' : 'Create Account',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLogin ? 'Sign in to continue' : 'Join the university community',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 28),
                          
                          // Biometric Login Button (only show on login with saved credentials)
                          if (_isLogin && _canUseBiometricLogin) ...[
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _biometricLogin,
                              icon: const Icon(Icons.fingerprint, size: 28),
                              label: const Text('Login with Biometrics'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                side: BorderSide(color: AppColors.primary, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey[300])),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('OR', style: TextStyle(color: Colors.grey[500])),
                                ),
                                Expanded(child: Divider(color: Colors.grey[300])),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: InputDecoration(
                                labelText: 'I am a...',
                                prefixIcon: const Icon(Icons.badge_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'student', child: Text('Student')),
                                DropdownMenuItem(value: 'professor', child: Text('Professor')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value!;
                                  if (_selectedRole != 'professor') {
                                    _professorIdController.clear();
                                  }
                                });
                              },
                            ),
                            if (_selectedRole == 'professor') ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _professorIdController,
                                decoration: InputDecoration(
                                  labelText: 'Professor ID',
                                  prefixIcon: const Icon(Icons.verified_user_outlined),
                                  hintText: 'e.g., PROF-2024-001',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                validator: (val) {
                                  if (_selectedRole == 'professor' && (val == null || val.isEmpty)) {
                                    return 'Professor ID is required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) => !val!.contains('@') ? 'Invalid email' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            obscureText: true,
                            validator: (val) => val!.length < 6 ? 'Password too short' : null,
                          ),
                          
                          // Enable biometric option on login
                          if (_isLogin && _biometricAvailable && !_canUseBiometricLogin) ...[
                            const SizedBox(height: 12),
                            CheckboxListTile(
                              value: _enableBiometric,
                              onChanged: (val) => setState(() => _enableBiometric = val!),
                              title: const Text('Enable biometric login'),
                              subtitle: const Text('Use fingerprint or face for future logins'),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ],
                          
                          const SizedBox(height: 28),
                          if (_isLoading)
                            const SizedBox(
                              height: 56,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 3,
                              ),
                              child: Text(
                                _isLogin ? 'SIGN IN' : 'CREATE ACCOUNT',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => setState(() {
                              _isLogin = !_isLogin;
                              _enableBiometric = false;
                            }),
                            child: Text(
                              _isLogin 
                                ? 'New here? Create an account' 
                                : 'Already have an account? Sign in',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
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
