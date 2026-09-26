import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../models/api_error.dart';
import '../../../models/auth_models.dart';
import '../../../services/auth_service.dart';

/// Step 2 of password recovery: OTP verification + new password.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.challenge});

  final OtpChallenge? challenge;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _otp = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _loading = false;
  bool _resent = false;

  @override
  void dispose() {
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final OtpChallenge? challenge = widget.challenge;
    if (challenge == null) {
      context.go('/forgot-password');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final String resetToken = await AuthServiceFactory.instance.verifyOtp(
        VerifyOtpRequest(otpToken: challenge.otpToken, otp: _otp.text.trim()),
      );
      await AuthServiceFactory.instance.resetPassword(
        ResetPasswordRequest(
          resetToken: resetToken,
          newPassword: _password.text,
        ),
      );
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Password updated. Please sign in with your new password.');
      context.go('/login');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(AppStrings.genericError);
    }
  }

  void _resend() {
    setState(() => _resent = true);
    _snack('A new verification code has been sent.');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final OtpChallenge? challenge = widget.challenge;
    final String destination =
        challenge?.destination.isNotEmpty == true ? challenge!.destination : 'your registered number';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const AppHeader(showBack: true),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                width: 78,
                height: 78,
                margin: const EdgeInsets.only(top: 10, bottom: 18),
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pin_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              Text(
                AppStrings.resetTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.resetSubtitle.replaceFirst('{destination}', destination),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.55),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      AppTextField(
                        label: AppStrings.otpLabel,
                        hint: 'Enter 6 digit code',
                        controller: _otp,
                        prefixIcon: Icons.password_rounded,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[AutofillHints.oneTimeCode],
                        validator: Validators.otp,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resent ? null : _resend,
                          child: Text(
                            _resent ? 'Code sent' : AppStrings.resendCode,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AppTextField(
                        label: AppStrings.newPasswordLabel,
                        hint: AppStrings.createPasswordHint,
                        controller: _password,
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: Validators.newPassword,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: AppStrings.confirmPasswordLabel,
                        hint: 'Re-enter your password',
                        controller: _confirm,
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (String? value) =>
                            Validators.confirmPassword(value, _password.text),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: AppStrings.resetPassword,
                        icon: Icons.check_circle_outline_rounded,
                        loading: _loading,
                        onPressed: _loading ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
