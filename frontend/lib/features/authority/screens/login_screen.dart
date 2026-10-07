import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'authority_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // ✅ REAL Supabase login
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('⚠️ Please enter email and password', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Authenticate with Supabase
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed');
      }

      // 2. Verify the user has the "authority" role
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role, full_name')
          .eq('id', response.user!.id)
          .maybeSingle();

      if (profile == null) {
        await Supabase.instance.client.auth.signOut();
        throw Exception('No profile found. Contact your administrator.');
      }

      if (profile['role'] != 'authority') {
        await Supabase.instance.client.auth.signOut();
        throw Exception('Access denied: Not a Traffic Authority user.');
      }

      // 3. Navigate to Dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthorityDashboard()),
        );
      }
    } on AuthException catch (e) {
      _showSnack('❌ ${e.message}', Colors.red);
    } catch (e) {
      _showSnack('❌ $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3B5C),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 6))
                          ],
                        ),
                        child: const Text('TA',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3B5C),
                                letterSpacing: 1)),
                      ),
                      const SizedBox(height: 24),
                      const Text('Traffic Authority',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3)),
                      const SizedBox(height: 6),
                      const Text('City monitoring portal',
                          style: TextStyle(
                              fontSize: 13, color: Colors.white70)),
                      const SizedBox(height: 50),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Welcome back',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A3B5C))),
                              const SizedBox(height: 6),
                              const Text('Sign in to access the portal',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey)),
                              const SizedBox(height: 32),
                              _buildFieldLabel('Officer ID / email'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'officer@colombo.gov.lk',
                                  hintStyle: const TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                  prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFF1A3B5C),
                                      size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F7FA),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          vertical: 16),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildFieldLabel('Password'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  hintStyle: const TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                  prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFF1A3B5C),
                                      size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F7FA),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          vertical: 16),
                                ),
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFFEAA22F),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text('Log in',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward,
                                                color: Colors.white,
                                                size: 18),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8EDF2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shield_outlined,
                                          color: Color(0xFF1A3B5C), size: 14),
                                      SizedBox(width: 6),
                                      Text('Authorized access only',
                                          style: TextStyle(
                                              color: Color(0xFF1A3B5C),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Center(
                                child: Text('ParkPin Authority · v1.0',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A3B5C),
          letterSpacing: 0.3));
}