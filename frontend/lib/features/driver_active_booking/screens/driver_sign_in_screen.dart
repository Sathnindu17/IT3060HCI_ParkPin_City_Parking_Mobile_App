import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/parking_ui.dart';

class DriverSignInScreen extends StatefulWidget {
  const DriverSignInScreen({super.key});

  @override
  State<DriverSignInScreen> createState() =>
      _DriverSignInScreenState();
}

class _DriverSignInScreenState extends State<DriverSignInScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _busy = false;
  bool _obscurePassword = true;

  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_busy) return;

    final form = _formKey.currentState;

    if (form == null || !form.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // The app's authentication gate will open the driver dashboard.
    } on AuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error =
            'Could not sign in. Check your connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParkingStyle.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: ParkingStyle.navy,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: const Icon(
                            Icons.local_parking_rounded,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Welcome to ParkPin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: ParkingStyle.navy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Sign in to manage your parking sessions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: ParkingStyle.muted,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ParkingCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Driver sign in',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: ParkingStyle.navy,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              enabled: !_busy,
                              keyboardType:
                                  TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              autofillHints: const [
                                AutofillHints.username,
                                AutofillHints.email,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Driver email',
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isEmpty ||
                                    !email.contains('@')) {
                                  return 'Enter your driver email.';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _passwordController,
                              enabled: !_busy,
                              obscureText: _obscurePassword,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [
                                AutofillHints.password,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: _busy
                                      ? null
                                      : () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons
                                            .visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter your password.';
                                }

                                return null;
                              },
                              onFieldSubmitted: (_) {
                                _signIn();
                              },
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEEEE),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Color(0xFFB42318),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 54,
                              child: FilledButton(
                                onPressed: _busy ? null : _signIn,
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      ParkingStyle.orange,
                                  foregroundColor:
                                      ParkingStyle.navy,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                ),
                                child: _busy
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: ParkingStyle.navy,
                                        ),
                                      )
                                    : const Text(
                                        'Sign in',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                          ],
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
    );
  }
}