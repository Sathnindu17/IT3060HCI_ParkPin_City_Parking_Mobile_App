import 'package:flutter/material.dart';
import 'package:parkpin/services/auth_service.dart';
import 'package:parkpin/services/supabase_service.dart';

class D06DriverSignUpScreen extends StatefulWidget {

  const D06DriverSignUpScreen({super.key});

  @override

  State<D06DriverSignUpScreen> createState() =>

      _D06DriverSignUpScreenState();

}

class _D06DriverSignUpScreenState extends State<D06DriverSignUpScreen> {

  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();

  final _phoneController = TextEditingController();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  final _vehicleController = TextEditingController();

  bool _obscurePassword = true;

  bool _isLoading = false;

  // ============================================================

  // COLORS

  // ============================================================

  static const Color background = Color(0xFFF4F6FA);

  static const Color navy = Color(0xFF173F78);

  static const Color blue = Color(0xFF285E98);

  static const Color orange = Color(0xFFFFA51F);

  static const Color textDark = Color(0xFF172033);

  static const Color textGrey = Color(0xFF7A8494);

  static const Color border = Color(0xFFE5E9F0);

  @override

  void dispose() {

    _fullNameController.dispose();

    _phoneController.dispose();

    _emailController.dispose();

    _passwordController.dispose();

    _vehicleController.dispose();

    super.dispose();

  }

  // ============================================================

  // CREATE ACCOUNT

  // ============================================================

  Future<void> _createAccount() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await AuthService.instance.signUpDriver(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        vehicleNumber: _vehicleController.text.trim(),
      );

      if (!mounted) return;
      final needsConfirmation = response.session == null;

      if (!needsConfirmation) {
        // Signup can establish a session when confirmation is disabled.
        // Return to D05 so the driver can sign in deliberately.
        await AuthService.instance.signOut();
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Account created'),
          content: Text(
            needsConfirmation
                ? 'Check your email for the confirmation message. '
                    'Confirm your address, then log in to ParkPin.'
                : 'Your driver account has been created. '
                    'You can now log in to ParkPin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(SupabaseService.friendlyError(error)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================

  void _goToLogin() {

    Navigator.of(context).pop();

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

            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),

            child: ConstrainedBox(

              constraints: BoxConstraints(

                minHeight:

                    MediaQuery.sizeOf(context).height -

                    MediaQuery.paddingOf(context).vertical -

                    34,

              ),

              child: IntrinsicHeight(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    // ==================================================

                    // COLORFUL HEADER

                    // ==================================================

                    Stack(

                      children: [

                        Container(

                          width: double.infinity,

                          padding: const EdgeInsets.fromLTRB(

                            18,

                            22,

                            18,

                            24,

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

                              // Large blue circle

                              Positioned(

                                left: -38,

                                top: -42,

                                child: Container(

                                  width: 95,

                                  height: 95,

                                  decoration: BoxDecoration(

                                    color: blue.withValues(alpha: 0.08),

                                    shape: BoxShape.circle,

                                  ),

                                ),

                              ),

                              // Large orange circle

                              Positioned(

                                right: -40,

                                bottom: -45,

                                child: Container(

                                  width: 105,

                                  height: 105,

                                  decoration: BoxDecoration(

                                    color: orange.withValues(alpha: 0.14),

                                    shape: BoxShape.circle,

                                  ),

                                ),

                              ),

                              // Orange small dot

                              Positioned(

                                right: 28,

                                top: 4,

                                child: Container(

                                  width: 13,

                                  height: 13,

                                  decoration: BoxDecoration(

                                    color: orange.withValues(alpha: 0.55),

                                    shape: BoxShape.circle,

                                  ),

                                ),

                              ),

                              // Blue small dot

                              Positioned(

                                left: 38,

                                bottom: 7,

                                child: Container(

                                  width: 9,

                                  height: 9,

                                  decoration: BoxDecoration(

                                    color: blue.withValues(alpha: 0.28),

                                    shape: BoxShape.circle,

                                  ),

                                ),

                              ),

                              // CENTER HEADER CONTENT

                              Center(

                                child: Column(

                                  children: [

                                    // Logo

                                    Container(

                                      width: 58,

                                      height: 58,

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

                                            BorderRadius.circular(16),

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

                                        Icons.person_add_alt_1_rounded,

                                        color: Colors.white,

                                        size: 29,

                                      ),

                                    ),

                                    const SizedBox(height: 14),

                                    const Text(

                                      'Create account',

                                      textAlign: TextAlign.center,

                                      style: TextStyle(

                                        fontSize: 24,

                                        fontWeight: FontWeight.w700,

                                        color: textDark,

                                      ),

                                    ),

                                    const SizedBox(height: 5),

                                    const Text(

                                      'Join ParkPin in under a minute',

                                      textAlign: TextAlign.center,

                                      style: TextStyle(

                                        fontSize: 12,

                                        color: textGrey,

                                      ),

                                    ),

                                  ],

                                ),

                              ),

                            ],

                          ),

                        ),

                        // ==============================================

                        // BACK BUTTON

                        // ==============================================

                        Positioned(

                          left: 9,

                          top: 9,

                          child: Material(

                            color: Colors.white.withValues(alpha: 0.88),

                            shape: const CircleBorder(),

                            child: InkWell(

                              customBorder: const CircleBorder(),

                              onTap: _goToLogin,

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

                    const SizedBox(height: 24),

                    // ==================================================

                    // FORM SECTION TITLE

                    // ==================================================

                    const Row(

                      children: [

                        Icon(

                          Icons.badge_outlined,

                          color: blue,

                          size: 18,

                        ),

                        SizedBox(width: 7),

                        Text(

                          'Your details',

                          style: TextStyle(

                            fontSize: 14,

                            fontWeight: FontWeight.w700,

                            color: textDark,

                          ),

                        ),

                      ],

                    ),

                    const SizedBox(height: 4),

                    const Text(

                      'Enter your details to create your driver account.',

                      style: TextStyle(

                        fontSize: 10,

                        color: textGrey,

                      ),

                    ),

                    const SizedBox(height: 18),

                    // ==================================================

                    // FULL NAME

                    // ==================================================

                    _fieldLabel('Full name'),

                    const SizedBox(height: 6),

                    TextFormField(

                      controller: _fullNameController,

                      textInputAction: TextInputAction.next,

                      textCapitalization: TextCapitalization.words,

                      decoration: _inputDecoration(

                        hint: 'Kavindu M.',

                        prefixIcon: Icons.person_outline,

                      ),

                      validator: (value) {

                        if (value == null || value.trim().isEmpty) {

                          return 'Please enter your full name.';

                        }

                        if (value.trim().length < 2) {

                          return 'Please enter a valid name.';

                        }

                        return null;

                      },

                    ),

                    const SizedBox(height: 14),

                    // ==================================================

                    // MOBILE NUMBER

                    // ==================================================

                    _fieldLabel('Mobile number'),

                    const SizedBox(height: 6),

                    TextFormField(

                      controller: _phoneController,

                      keyboardType: TextInputType.phone,

                      textInputAction: TextInputAction.next,

                      decoration: _inputDecoration(

                        hint: '+94 7•• ••• •••',

                        prefixIcon: Icons.phone_outlined,

                      ),

                      validator: (value) {

                        if (value == null || value.trim().isEmpty) {

                          return 'Please enter your mobile number.';

                        }

                        final digits =

                            value.replaceAll(RegExp(r'[^0-9]'), '');

                        if (digits.length < 9) {

                          return 'Please enter a valid mobile number.';

                        }

                        return null;

                      },

                    ),

                    const SizedBox(height: 14),

                    // ==================================================

                    // EMAIL

                    // ==================================================

                    _fieldLabel('Email'),

                    const SizedBox(height: 6),

                    TextFormField(

                      controller: _emailController,

                      keyboardType: TextInputType.emailAddress,

                      textInputAction: TextInputAction.next,

                      autofillHints: const [

                        AutofillHints.email,

                      ],

                      decoration: _inputDecoration(

                        hint: 'you@email.com',

                        prefixIcon: Icons.email_outlined,

                      ),

                      validator: (value) {

                        if (value == null || value.trim().isEmpty) {

                          return 'Please enter your email.';

                        }

                        final email = value.trim();

                        final emailPattern = RegExp(

                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',

                        );

                        if (!emailPattern.hasMatch(email)) {

                          return 'Please enter a valid email address.';

                        }

                        return null;

                      },

                    ),

                    const SizedBox(height: 14),

                    // ==================================================

                    // PASSWORD

                    // ==================================================

                    _fieldLabel('Password'),

                    const SizedBox(height: 6),

                    TextFormField(

                      controller: _passwordController,

                      obscureText: _obscurePassword,

                      textInputAction: TextInputAction.next,

                      autofillHints: const [

                        AutofillHints.newPassword,

                      ],

                      decoration: _inputDecoration(

                        hint: '••••••••',

                        prefixIcon: Icons.lock_outline,

                        suffixWidget: IconButton(

                          tooltip: _obscurePassword

                              ? 'Show password'

                              : 'Hide password',

                          onPressed: () {

                            setState(() {

                              _obscurePassword =

                                  !_obscurePassword;

                            });

                          },

                          icon: Icon(

                            _obscurePassword

                                ? Icons.visibility_outlined

                                : Icons.visibility_off_outlined,

                            size: 19,

                            color: textGrey,

                          ),

                        ),

                      ),

                      validator: (value) {

                        if (value == null || value.isEmpty) {

                          return 'Please enter a password.';

                        }

                        if (value.length < 6) {

                          return 'Password must be at least 6 characters.';

                        }

                        return null;

                      },

                    ),

                    const SizedBox(height: 14),

                    // ==================================================

                    // VEHICLE NUMBER

                    // ==================================================

                    _fieldLabel('Vehicle number'),

                    const SizedBox(height: 6),

                    TextFormField(

                      controller: _vehicleController,

                      textInputAction: TextInputAction.done,

                      textCapitalization: TextCapitalization.characters,

                      onFieldSubmitted: (_) {

                        if (!_isLoading) {

                          _createAccount();

                        }

                      },

                      decoration: _inputDecoration(

                        hint: 'CAB-1234',

                        prefixIcon: Icons.directions_car_outlined,

                      ),

                      validator: (value) {

                        if (value == null || value.trim().isEmpty) {

                          return 'Please enter your vehicle number.';

                        }

                        if (value.trim().length < 4) {

                          return 'Please enter a valid vehicle number.';

                        }

                        return null;

                      },

                    ),

                    const Spacer(),

                    const SizedBox(height: 34),

                    // ==================================================

                    // CREATE ACCOUNT BUTTON

                    // ==================================================

                    SizedBox(

                      width: double.infinity,

                      height: 52,

                      child: FilledButton(

                        onPressed:

                            _isLoading ? null : _createAccount,

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

                                    Icons.person_add_alt_1_rounded,

                                    size: 18,

                                  ),

                                  SizedBox(width: 8),

                                  Text(

                                    'Create account',

                                    style: TextStyle(

                                      fontSize: 13,

                                      fontWeight: FontWeight.w700,

                                    ),

                                  ),

                                ],

                              ),

                      ),

                    ),

                    const SizedBox(height: 13),

                    // ==================================================

                    // TERMS

                    // ==================================================

                    Row(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        Icon(

                          Icons.verified_user_outlined,

                          size: 12,

                          color: textGrey.withValues(alpha: 0.8),

                        ),

                        const SizedBox(width: 5),

                        const Flexible(

                          child: Text(

                            'By continuing you agree to our Terms & Privacy Policy',

                            textAlign: TextAlign.center,

                            style: TextStyle(

                              fontSize: 9,

                              color: textGrey,

                            ),

                          ),

                        ),

                      ],

                    ),

                    const SizedBox(height: 12),

                    // ==================================================

                    // LOGIN LINK

                    // ==================================================

                    Row(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        const Text(

                          'Have an account? ',

                          style: TextStyle(

                            fontSize: 11,

                            color: textGrey,

                          ),

                        ),

                        GestureDetector(

                          onTap: _isLoading ? null : _goToLogin,

                          child: const Text(

                            'Log in',

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

  // ============================================================

  // FIELD LABEL

  // ============================================================

  Widget _fieldLabel(String text) {

    return Text(

      text,

      style: const TextStyle(

        fontSize: 11,

        fontWeight: FontWeight.w600,

        color: Color(0xFF5F6B7B),

      ),

    );

  }

  // ============================================================

  // INPUT DECORATION

  // ============================================================

  InputDecoration _inputDecoration({

    required String hint,

    required IconData prefixIcon,

    Widget? suffixWidget,

  }) {

    return InputDecoration(

      hintText: hint,

      hintStyle: const TextStyle(

        color: Color(0xFFA1A8B3),

        fontSize: 12,

      ),

      filled: true,

      fillColor: Colors.white,

      prefixIcon: Icon(

        prefixIcon,

        size: 19,

        color: blue,

      ),

      suffixIcon: suffixWidget,

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

    );

  }

}