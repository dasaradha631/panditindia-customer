import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../models/api_error.dart';
import '../../../models/auth_models.dart';
import '../../../services/auth_service.dart';

/// Step 1 of password recovery: request an OTP (PDF section 11 flow).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _identifier = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _identifier.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final OtpChallenge challenge =
          await AuthServiceFactory.instance.forgotPassword(
        ForgotPasswordRequest(identifier: _identifier.text.trim()),
      );
      if (!mounted) return;
      setState(() => _loading = false);
      context.push('/reset-password', extra: challenge);
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

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: AppStrings.forgotTitle,
      subtitle: AppStrings.forgotSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            width: 78,
            height: 78,
            margin: const EdgeInsets.only(top: 4, bottom: 18),
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
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
                        label: AppStrings.identifierLabel,
                        hint: AppStrings.identifierHint,
                        controller: _identifier,
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _send(),
                        validator: Validators.identifier,
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: AppStrings.sendOtp,
                        icon: Icons.sms_outlined,
                        loading: _loading,
                        onPressed: _loading ? null : _send,
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
    );
  }
}
