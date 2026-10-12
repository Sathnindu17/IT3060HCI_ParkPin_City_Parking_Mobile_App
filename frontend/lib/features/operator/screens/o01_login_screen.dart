import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parkpin/core/constants/app_colors.dart';
import 'package:parkpin/core/utils/validators.dart';
import 'package:parkpin/features/operator/operator_routes.dart';
import 'package:parkpin/features/operator/services/operator_service.dart';
import 'package:parkpin/features/operator/widgets/operator_ui.dart';
import 'package:parkpin/services/supabase_service.dart';

/// O01 – Operator login (Figma "Operator · Login").
/// Checks the account role so drivers/authority cannot open the operator portal.
class OperatorLoginScreen extends StatefulWidget {
  const OperatorLoginScreen({super.key});

  @override
  State<OperatorLoginScreen> createState() => _OperatorLoginScreenState();
}

class _OperatorLoginScreenState extends State<OperatorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;
  bool _checkingSession = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryRestore();
  }

  /// Skip the form if this phone is already signed in as an operator.
  Future<void> _tryRestore() async {
    final ok = await OperatorService.instance.restoreSession();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed(OperatorRoutes.dashboard);
    } else {
      setState(() => _checkingSession = false);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await OperatorService.instance.signIn(_email.text, _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(OperatorRoutes.dashboard);
    } catch (e) {
      if (mounted) setState(() => _error = SupabaseService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: _checkingSession
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Navy header with logo
                  Container(
                    width: double.infinity,
                    color: AppColors.primary,
                    padding: EdgeInsets.fromLTRB(20, top + 36, 20, 40),
                    child: Column(
                      children: [
                        if (Navigator.of(context).canPop())
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              tooltip: 'Back',
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                            ),
                          ),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6)),
                            ],
                          ),
                          child: const Icon(Icons.local_parking, color: AppColors.primary, size: 36),
                        ),
                        const SizedBox(height: 14),
                        const Text('Operator portal',
                            style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text('Publish bays · take bookings',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 0.6),
                          boxShadow: OpStyle.shadow,
                        ),
                        child: Form(
                          key: _formKey,
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('Welcome back', style: OpStyle.pageTitle),
                                const SizedBox(height: 4),
                                const Text('Log in to manage your car park.', style: OpStyle.pageSubtitle),
                                const SizedBox(height: 20),
                                OpField(
                                  label: 'Email',
                                  controller: _email,
                                  hint: 'operator@parkpin.lk',
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  validator: Validators.email,
                                ),
                                const SizedBox(height: 16),
                                OpField(
                                  label: 'Password',
                                  controller: _password,
                                  hint: '••••••••',
                                  obscureText: _hidePassword,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  validator: Validators.password,
                                  onSubmitted: (_) => _submit(),
                                  suffix: IconButton(
                                    tooltip: _hidePassword ? 'Show password' : 'Hide password',
                                    onPressed: () => setState(() => _hidePassword = !_hidePassword),
                                    icon: Icon(
                                      _hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      size: 18,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.dangerBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(_error!,
                                              style: const TextStyle(fontSize: 13.5, color: AppColors.danger)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                OpButton(label: 'Log in', loading: _loading, onPressed: _submit),
                                const SizedBox(height: 18),
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.neutralBg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.shield_outlined, size: 15, color: AppColors.textMuted),
                                        SizedBox(width: 6),
                                        Text('Authorized access only',
                                            style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('ParkPin · car-park operators',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
