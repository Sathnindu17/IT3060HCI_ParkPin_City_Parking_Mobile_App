import 'package:flutter/material.dart';
import 'package:parkpin/services/auth_service.dart';
import 'package:parkpin/services/supabase_service.dart';
import 'package:parkpin/features/driver_search_booking/screens/d05_driver_login_screen.dart';

class D09DriverNewPasswordScreen extends StatefulWidget {
  final String email;

  const D09DriverNewPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<D09DriverNewPasswordScreen> createState() =>
      _D09DriverNewPasswordScreenState();
}

class _D09DriverNewPasswordScreenState
    extends State<D09DriverNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;

  static const Color background = Color(0xFFF4F6FA);
  static const Color navy = Color(0xFF173F78);
  static const Color blue = Color(0xFF285E98);
  static const Color orange = Color(0xFFFFA51F);
  static const Color textDark = Color(0xFF172033);
  static const Color textGrey = Color(0xFF7A8494);
  static const Color border = Color(0xFFE5E9F0);
  static const Color successGreen = Color(0xFF1B8A5A);

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // PASSWORD VALIDATION
  // ============================================================

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password.';
    }

    if (value.length < 8) {
      return 'Password must contain at least 8 characters.';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Include at least one uppercase letter.';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Include at least one lowercase letter.';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Include at least one number.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your new password.';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }

    return null;
  }

  // Update the password only after a successful recovery OTP verification.
  Future<void> _updatePassword() async {
    FocusScope.of(context).unfocus();
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.updatePassword(_passwordController.text);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(SupabaseService.friendlyError(error)),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }
    // The password has been updated. End the temporary recovery session.
    try {
      await AuthService.instance.signOut();
    } catch (_) {
      // Password update succeeded, but sign-out must be retried before login.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated, but sign-out failed. Please try again.')),
      );
      setState(() => _isLoading = false);
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);

    // Show success dialog
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            28,
            24,
            22,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: const BoxDecoration(
                  color: Color(0xFFE7F7EF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: successGreen,
                  size: 40,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Password updated!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Your password has been changed successfully. '
                'You can now log in with your new password.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: textGrey,
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: textDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to login',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    // Remove forgot password / OTP / new password screens
    // and return directly to Driver Login.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const D05DriverLoginScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              18,
              16,
              18,
              18,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).vertical -
                    34,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // ==================================================
                    // HEADER
                    // ==================================================

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
                                color: navy.withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Blue decorative circle
                              Positioned(
                                left: -40,
                                top: -48,
                                child: Container(
                                  width: 105,
                                  height: 105,
                                  decoration: BoxDecoration(
                                    color: blue.withValues(
                                      alpha: 0.08,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              // Orange decorative circle
                              Positioned(
                                right: -40,
                                bottom: -52,
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: orange.withValues(
                                      alpha: 0.14,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              // Small orange dot
                              Positioned(
                                right: 27,
                                top: 2,
                                child: Container(
                                  width: 13,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    color: orange.withValues(
                                      alpha: 0.55,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              // Center content
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 62,
                                      height: 62,
                                      decoration: BoxDecoration(
                                        gradient:
                                            const LinearGradient(
                                          begin:
                                              Alignment.topLeft,
                                          end:
                                              Alignment.bottomRight,
                                          colors: [
                                            blue,
                                            navy,
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(
                                          18,
                                        ),
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
                                        Icons.lock_outline_rounded,
                                        color: Colors.white,
                                        size: 31,
                                      ),
                                    ),

                                    const SizedBox(height: 15),

                                    const Text(
                                      'Create new password',
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
                                      'Create a strong password for\n'
                                      'your ParkPin account.',
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
                            color: Colors.white.withValues(
                              alpha: 0.88,
                            ),
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

                    // ==================================================
                    // PASSWORD SECTION TITLE
                    // ==================================================

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(
                            Icons.security_rounded,
                            color: blue,
                            size: 18,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Secure your account',
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

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Changing password for ${widget.email}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: textGrey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ==================================================
                    // NEW PASSWORD
                    // ==================================================

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'New password',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5F6B7B),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      enabled: !_isLoading,
                      textInputAction: TextInputAction.next,
                      validator: _validatePassword,
                      onChanged: (_) {
                        // Refresh confirm password validation
                        // when needed.
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter new password',
                        hintStyle: const TextStyle(
                          color: Color(0xFFA1A8B3),
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: blue,
                          size: 19,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _hidePassword =
                                  !_hidePassword;
                            });
                          },
                          icon: Icon(
                            _hidePassword
                                ? Icons
                                    .visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: textGrey,
                            size: 19,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: blue,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                          ),
                        ),
                        focusedErrorBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
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

                    const SizedBox(height: 17),

                    // ==================================================
                    // CONFIRM PASSWORD
                    // ==================================================

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Confirm new password',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5F6B7B),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    TextFormField(
                      controller:
                          _confirmPasswordController,
                      obscureText: _hideConfirmPassword,
                      enabled: !_isLoading,
                      textInputAction: TextInputAction.done,
                      validator: _validateConfirmPassword,
                      onFieldSubmitted: (_) {
                        if (!_isLoading) {
                          _updatePassword();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Confirm new password',
                        hintStyle: const TextStyle(
                          color: Color(0xFFA1A8B3),
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: blue,
                          size: 19,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _hideConfirmPassword =
                                  !_hideConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _hideConfirmPassword
                                ? Icons
                                    .visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: textGrey,
                            size: 19,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: blue,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                          ),
                        ),
                        focusedErrorBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
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

                    // ==================================================
                    // PASSWORD REQUIREMENTS
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: blue.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: blue,
                                size: 17,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'Password requirements',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: navy,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 8),

                          Text(
                            '• At least 8 characters\n'
                            '• At least one uppercase letter\n'
                            '• At least one lowercase letter\n'
                            '• At least one number',
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.6,
                              color: Color(0xFF526176),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    const SizedBox(height: 35),

                    // ==================================================
                    // UPDATE PASSWORD BUTTON
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed:
                            _isLoading ? null : _updatePassword,
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
                                    Icons
                                        .lock_reset_rounded,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Update password',
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

                    const SizedBox(height: 15),

                    const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: textGrey,
                          size: 13,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Your password is securely protected',
                          style: TextStyle(
                            fontSize: 9,
                            color: textGrey,
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