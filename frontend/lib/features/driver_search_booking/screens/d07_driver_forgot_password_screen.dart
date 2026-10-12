import 'package:flutter/material.dart';
import 'package:parkpin/services/auth_service.dart';
import 'package:parkpin/services/supabase_service.dart';
import 'package:parkpin/features/driver_search_booking/screens/d08_driver_verify_otp_screen.dart';

class D07DriverForgotPasswordScreen extends StatefulWidget {
  const D07DriverForgotPasswordScreen({super.key});

  @override
  State<D07DriverForgotPasswordScreen> createState() =>
      _D07DriverForgotPasswordScreenState();
}

class _D07DriverForgotPasswordScreenState
    extends State<D07DriverForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  static const Color background = Color(0xFFF4F6FA);
  static const Color navy = Color(0xFF173F78);
  static const Color blue = Color(0xFF285E98);
  static const Color orange = Color(0xFFFFA51F);
  static const Color textDark = Color(0xFF172033);
  static const Color textGrey = Color(0xFF7A8494);
  static const Color border = Color(0xFFE5E9F0);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address.';
    }

    final email = value.trim();

    final emailPattern = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailPattern.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    if (_isLoading || !_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.resetPassword(email);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => D08DriverVerifyOtpScreen(email: email),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(SupabaseService.friendlyError(error)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _backToLogin() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).vertical -
                    34,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // HEADER
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(
                            18,
                            26,
                            18,
                            26,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFE4EFFF),
                                Color(0xFFFFF3DF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: navy.withValues(alpha: 0.08),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: -38,
                                top: -45,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: blue.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              Positioned(
                                right: -38,
                                bottom: -48,
                                child: Container(
                                  width: 105,
                                  height: 105,
                                  decoration: BoxDecoration(
                                    color: orange.withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              Positioned(
                                right: 28,
                                top: 3,
                                child: Container(
                                  width: 13,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    color: orange.withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 62,
                                      height: 62,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            blue,
                                            navy,
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: navy.withValues(
                                              alpha: 0.25,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.lock_reset_rounded,
                                        color: Colors.white,
                                        size: 31,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    const Text(
                                      'Reset password',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Enter your email and we\'ll send you\n'
                                      'a secure 6-digit verification code.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        height: 1.5,
                                        color: textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // BACK BUTTON
                        Positioned(
                          left: 9,
                          top: 9,
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.88),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _isLoading ? null : _backToLogin,
                              child: const SizedBox(
                                width: 38,
                                height: 38,
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: navy,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // EMAIL SECTION
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: blue,
                            size: 18,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Account email',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Enter the email address connected to your ParkPin account.',
                        style: TextStyle(
                          fontSize: 10,
                          color: textGrey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email address',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5F6B7B),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [
                        AutofillHints.email,
                      ],
                      enabled: !_isLoading,
                      onFieldSubmitted: (_) {
                        if (!_isLoading) {
                          _sendOtp();
                        }
                      },
                      validator: _validateEmail,
                      decoration: InputDecoration(
                        hintText: 'you@email.com',
                        hintStyle: const TextStyle(
                          color: Color(0xFFA1A8B3),
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: blue,
                          size: 19,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: blue,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1.3,
                          ),
                        ),
                        errorStyle: const TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // INFO BOX
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: blue.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: blue,
                            size: 17,
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'We\'ll send a 6-digit verification code '
                              'to your registered email address.',
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.4,
                                color: Color(0xFF526176),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),
                    const SizedBox(height: 40),

                    // SEND OTP
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        style: FilledButton.styleFrom(
                          backgroundColor: orange,
                          foregroundColor: textDark,
                          disabledBackgroundColor:
                              orange.withValues(alpha: 0.55),
                          elevation: 3,
                          shadowColor:
                              orange.withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.send_rounded,
                                    size: 17,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Send OTP',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 17),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Remembered it? ',
                          style: TextStyle(
                            fontSize: 11,
                            color: textGrey,
                          ),
                        ),
                        GestureDetector(
                          onTap:
                              _isLoading ? null : _backToLogin,
                          child: const Text(
                            'Back to login',
                            style: TextStyle(
                              fontSize: 11,
                              color: navy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}