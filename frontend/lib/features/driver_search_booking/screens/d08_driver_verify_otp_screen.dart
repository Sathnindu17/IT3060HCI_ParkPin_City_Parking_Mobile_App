import 'package:flutter/material.dart';
import 'package:parkpin/services/auth_service.dart';
import 'package:parkpin/services/supabase_service.dart';
import 'package:flutter/services.dart';
import 'package:parkpin/features/driver_search_booking/screens/d09_driver_new_password_screen.dart';

class D08DriverVerifyOtpScreen extends StatefulWidget {
  final String email;

  const D08DriverVerifyOtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<D08DriverVerifyOtpScreen> createState() =>
      _D08DriverVerifyOtpScreenState();
}

class _D08DriverVerifyOtpScreenState
    extends State<D08DriverVerifyOtpScreen> {
  final _otpController = TextEditingController();

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
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();
    if (_isLoading) return;
    final otp = _otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _showMessage('Please enter a valid 6-digit code.', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.verifyRecoveryOtp(
        email: widget.email,
        otp: otp,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => D09DriverNewPasswordScreen(email: widget.email),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(SupabaseService.friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    FocusScope.of(context).unfocus();
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.resetPassword(widget.email);
      if (!mounted) return;
      _otpController.clear();
      _showMessage('If the account exists, a new code has been requested. Check your email.', isError: false);
    } catch (error) {
      if (!mounted) return;
      _showMessage(SupabaseService.friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade600 : const Color(0xFF1B8A5A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
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
                          28,
                          18,
                          28,
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
                              left: -40,
                              top: -48,
                              child: Container(
                                width: 105,
                                height: 105,
                                decoration: BoxDecoration(
                                  color: blue.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              right: -40,
                              bottom: -52,
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color:
                                      orange.withValues(alpha: 0.14),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 27,
                              top: 2,
                              child: Container(
                                width: 13,
                                height: 13,
                                decoration: BoxDecoration(
                                  color:
                                      orange.withValues(alpha: 0.55),
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
                                      gradient:
                                          const LinearGradient(
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
                                          offset:
                                              const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons
                                          .mark_email_read_outlined,
                                      color: Colors.white,
                                      size: 31,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  const Text(
                                    'Check your email',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'We sent a 6-digit verification code to',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.email,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: navy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // BACK
                      Positioned(
                        left: 9,
                        top: 9,
                        child: Material(
                          color:
                              Colors.white.withValues(alpha: 0.88),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder:
                                const CircleBorder(),
                            onTap: _isLoading
                                ? null
                                : () =>
                                    Navigator.pop(context),
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

                  // VERIFICATION SECTION
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: blue,
                          size: 18,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'Verification code',
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
                      'Enter the 6-digit code sent to your email.',
                      style: TextStyle(
                        fontSize: 10,
                        color: textGrey,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    enabled: !_isLoading,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onSubmitted: (_) {
                      if (!_isLoading) {
                        _verifyOtp();
                      }
                    },
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 10,
                      color: textDark,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      hintStyle: const TextStyle(
                        color: Color(0xFFC8CDD5),
                        letterSpacing: 10,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: blue,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                   Container(
                     width: double.infinity,
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: const Color(0xFFEAF2FF),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: const Row(
                       children: [
                         Icon(Icons.info_outline_rounded, color: blue, size: 18),
                         SizedBox(width: 9),
                         Expanded(
                           child: Text(
                             'Enter the verification code from your email. Check spam if needed.',
                             style: TextStyle(fontSize: 10, color: textGrey),
                           ),
                         ),
                       ],
                     ),
                   ),

                  const Spacer(),

                  const SizedBox(height: 35),

                  // VERIFY
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed:
                          _isLoading ? null : _verifyOtp,
                      style: FilledButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: textDark,
                        disabledBackgroundColor:
                            orange.withValues(alpha: 0.55),
                        elevation: 3,
                        shadowColor:
                            orange.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(13),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Verify OTP',
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

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Didn\'t receive the code? ',
                        style: TextStyle(
                          fontSize: 11,
                          color: textGrey,
                        ),
                      ),
                      GestureDetector(
                        onTap:
                            _isLoading ? null : _resendOtp,
                        child: const Text(
                          'Resend OTP',
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
    );
  }
}