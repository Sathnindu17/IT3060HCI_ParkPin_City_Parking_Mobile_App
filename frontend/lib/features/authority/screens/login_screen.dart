import 'package:flutter/material.dart';
import 'authority_dashboard.dart'; // Make sure this points to your dashboard

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); 
    
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthorityDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3B5C),
      body: SafeArea(
        // LayoutBuilder gives us the exact dimensions of the screen
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('TA', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A3B5C))),
                      ),
                      const SizedBox(height: 16),
                      const Text('Traffic authority', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text('City monitoring portal', style: TextStyle(fontSize: 14, color: Colors.white70)),
                      const SizedBox(height: 40),
                      // Expanded now works safely because IntrinsicHeight gives it bounds
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Officer ID / email', style: TextStyle(fontSize: 14, color: Colors.black54)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController,
                                decoration: InputDecoration(hintText: 'officer@colombo.gov.lk', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                              ),
                              const SizedBox(height: 20),
                              const Text('Password', style: TextStyle(fontSize: 14, color: Colors.black54)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(hintText: '••••••••', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEAA22F),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: _isLoading 
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Log in', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Center(child: Text('Authorized access only', style: TextStyle(color: Colors.grey, fontSize: 12))),
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
}