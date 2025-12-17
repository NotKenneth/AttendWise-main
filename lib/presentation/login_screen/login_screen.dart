import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './widgets/app_logo_widget.dart';
import './widgets/login_form_widget.dart';
import './widgets/role_selection_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Get the Supabase client
  final _supabase = Supabase.instance.client;

  String _selectedRole = 'Student';

  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Check if user is already logged in
  Future<void> _checkCurrentUser() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      if (session.user.email != null) {
        setState(() {
          _emailController.text = session.user.email!;
        });
      }
    }
  }

  bool _validateInputs() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    bool isValid = true;

    // Email validation
    if (_emailController.text.isEmpty) {
      setState(() => _emailError = 'Email is required');
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text)) {
      setState(() => _emailError = 'Please enter a valid email address');
      isValid = false;
    }

    // Password validation
    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      isValid = false;
    } else if (_passwordController.text.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleLogin() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
      _generalError = null;
    });

    try {
      // 1. Attempt to Sign In (Checks email/pass against Supabase Auth)
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user == null) {
        throw 'Login failed. User cannot be null';
      }

      final userId = response.user!.id;
      debugPrint('DEBUG: User ID from Auth is: $userId');

      // 2. Authorization Check based on Selected Role
      if (_selectedRole == 'Marshall') {
        // --- MARSHALL LOGIC ---
        // Check if this user exists in the 'event_marshalls' table
        final marshallData = await _supabase
            .from('event_marshalls')
            .select('id') // We just need to check if a row exists
            .eq('user_id', userId)
            .maybeSingle(); // Returns null if no record found

        if (marshallData == null) {
          // User authenticated, but is NOT in the marshall table
          await _supabase.auth.signOut();
          throw 'Access Denied: This account is not authorized as a Marshall.';
        }
      } else {
        // --- STUDENT LOGIC ---
        // Check profile role (Keep existing logic for students)
        final data = await _supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .single();

        final String dbRole = data['role'] ?? '';

        if (dbRole.toLowerCase() != 'student') {
          await _supabase.auth.signOut();
          throw 'Invalid role: This account is not a Student.';
        }
      }

      // 3. Success & Navigation
      HapticFeedback.lightImpact();
      if (!mounted) return;

      if (_selectedRole == 'Student') {
        Navigator.pushReplacementNamed(context, '/student-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/marshall-dashboard');
      }
    } on AuthException catch (e) {
      setState(() {
        _generalError = 'Auth Error: ${e.message}';
      });
    } on PostgrestException catch (e) {
      setState(() {
        _generalError =
            'DB Error: ${e.message}\nCode: ${e.code}\nDetails: ${e.details}';
      });
    } catch (e) {
      setState(() {
        _generalError = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'Please enter your email first';
      });
      return;
    }

    try {
      await _supabase.auth.resetPasswordForEmail(_emailController.text);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Check your inbox'),
          content: Text(
              'We have sent a password reset link to ${_emailController.text}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending reset email: ${e.toString()}')),
      );
    }
  }

  void _handleRoleChange(String role) {
    setState(() {
      _selectedRole = role;
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    const darkBlueBackground = Color(0xFF0F1A2A);
    return Scaffold(
      backgroundColor: darkBlueBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // Ensure status bar icons are light-colored for the dark background
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0, // Make the AppBar effectively invisible
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside of a text field
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // Ensure the SingleChildScrollView takes at least the full screen height
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 7.5.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // App Logo
                      const AppLogoWidget(),
                      SizedBox(height: 4.h),

                      // Role Selection
                      RoleSelectionWidget(
                        selectedRole: _selectedRole,
                        onRoleChanged: _handleRoleChange,
                      ),
                      SizedBox(height: 3.h),

                      // Login Form
                      LoginFormWidget(
                        emailController: _emailController,
                        passwordController: _passwordController,
                        isLoading: _isLoading,
                        emailError: _emailError,
                        passwordError: _passwordError,
                        onLogin: _handleLogin,
                        onForgotPassword: _handleForgotPassword,
                      ),

                      // Error Display (moved from the original code)
                      if (_generalError != null) ...[
                        SizedBox(height: 2.h),
                        Container(
                          width: 85.w,
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.bug_report,
                                  color: Colors.red, size: 20),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Text(
                                  _generalError!, // Shows exact error
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontSize: 10.sp,
                                    fontFamily: 'Courier',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const Spacer(flex: 1),
                    ],
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
