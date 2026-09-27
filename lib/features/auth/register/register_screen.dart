import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../models/api_error.dart';
import '../../../models/auth_models.dart';
import '../../../services/auth_service.dart';

/// Customer registration (mockup screen 4).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _loading = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedTerms) {
      _snack(AppStrings.acceptTerms);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await AuthServiceFactory.instance.register(
        RegisterRequest(
          fullName: _name.text.trim(),
          mobile: Formatters.digitsOnly(_mobile.text),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          password: _password.text,
          acceptTerms: _acceptedTerms,
        ),
      );
      if (!mounted) return;
      _snack('Account created successfully. Welcome to PanditIndia!');
      context.go('/home');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (error.fieldErrors.containsKey('mobile')) {
        _formKey.currentState?.validate();
      }
      _snack(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(AppStrings.genericError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AuthScaffold(
      title: AppStrings.registerTitle,
      subtitle: AppStrings.registerSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AppTextField(
                            label: AppStrings.fullNameLabel,
                            hint: AppStrings.fullNameHint,
                            controller: _name,
                            prefixIcon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            autofillHints: const <String>[AutofillHints.name],
                            validator: Validators.name,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: AppStrings.mobileLabel,
                            hint: AppStrings.mobileHint,
                            controller: _mobile,
                            prefixIcon: Icons.phone_iphone_rounded,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            autofillHints: const <String>[
                              AutofillHints.telephoneNumber,
                            ],
                            suffix: Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: Center(
                                widthFactor: 1,
                                child: Text(
                                  Formatters.countryCode,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            validator: Validators.mobile,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: AppStrings.emailOptionalLabel,
                            hint: AppStrings.emailOptionalHint,
                            controller: _email,
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const <String>[AutofillHints.email],
                            validator: (String? value) =>
                                Validators.email(value, optional: true),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: AppStrings.passwordLabel,
                            hint: AppStrings.createPasswordHint,
                            controller: _password,
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: const <String>[
                              AutofillHints.newPassword,
                            ],
                            onFieldSubmitted: (_) => _submit(),
                            validator: Validators.newPassword,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: 26,
                                height: 26,
                                child: Checkbox(
                                  value: _acceptedTerms,
                                  onChanged: (bool? value) => setState(
                                    () => _acceptedTerms = value ?? false,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      AppStrings.termsPrefix,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    _LinkText(
                                      AppStrings.termsAndConditions,
                                      onTap: () => _showSheet(
                                        AppStrings.termsAndConditions,
                                        'These terms will be published with '
                                            'the first production release of '
                                            'the PanditIndia mobile apps.',
                                      ),
                                    ),
                                    Text(
                                      AppStrings.termsMiddle,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    _LinkText(
                                      AppStrings.privacyPolicy,
                                      onTap: () => _showSheet(
                                        AppStrings.privacyPolicy,
                                        'The privacy policy explains how '
                                            'PanditIndia handles your booking '
                                            'and contact details.',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          PrimaryButton(
                            label: AppStrings.createAccount,
                            icon: Icons.person_add_alt_1_rounded,
                            loading: _loading,
                            onPressed: _loading ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        AppStrings.existingAccount,
                        style: theme.textTheme.bodySmall,
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(AppStrings.signIn),
                      ),
                    ],
                  ),
        ],
      ),
    );
  }

  void _showSheet(String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LinkText extends StatelessWidget {
  const _LinkText(this.label, {required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        ),
      ),
    );
  }
}
