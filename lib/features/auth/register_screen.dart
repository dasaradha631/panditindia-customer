import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/l10n/localized_text.dart';
import '../../core/utils/dial_countries.dart';
import '../../core/widgets/common.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/kundli_service.dart';
import 'auth_design.dart';
import 'login_screen.dart';

/// Three-step Create Account flow shown over the shared auth canvas.
///
/// 1. Verify — OTP-verify an email or mobile number and set a strong password.
/// 2. Personal Details — name, the remaining contact field, birth data.
/// 3. Spiritual Details — gotra / nakshatra / rashi (auto-filled from birth
///    data when the kundli API answers) then Sign Up.
/// After a successful registration the screen switches to a success panel and
/// sends the user to Sign In (no session is persisted).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _green = Color(0xFF16A34A);
  static const _gotraSuggestions = [
    'Bharadwaja',
    'Vashista',
    'Kashyapa',
    'Atri',
    'Gautama',
    'Jamadagni',
    'Vishwamitra',
    'Shandilya',
  ];

  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _name = TextEditingController();
  final _otherEmail = TextEditingController();
  final _otherMobile = TextEditingController();
  final _place = TextEditingController();
  final _gotra = TextEditingController();
  final _nakshatra = TextEditingController();
  final _rashi = TextEditingController();

  /// 1 = Verify, 2 = Personal Details, 3 = Spiritual Details.
  int _step = 1;
  bool _success = false;

  // ---- step 1: contact verification -------------------------------------
  String _channel = 'email';
  DialCountry _country = kDefaultDialCountry;
  DialCountry _otherCountry = kDefaultDialCountry;
  bool _otpSent = false;
  bool _verified = false;
  String _verifiedIdentifier = '';
  String _verifiedChannel = '';
  int _resendIn = 0;
  Timer? _resendTimer;
  bool _sendingOtp = false;
  bool _verifyingOtp = false;

  // ---- step 1: password --------------------------------------------------
  bool _obscure = true;
  bool _obscureConfirm = true;

  // ---- step 2 ------------------------------------------------------------
  DateTime? _dob;
  String _birthHour = '';
  String _birthMinute = '';
  String _birthPeriod = '';

  // ---- step 3 ------------------------------------------------------------
  bool _spiritualFetching = false;
  bool _registering = false;

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in [
      _email,
      _mobile,
      _otp,
      _password,
      _confirm,
      _name,
      _otherEmail,
      _otherMobile,
      _place,
      _gotra,
      _nakshatra,
      _rashi,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------- helpers

  String get _mobileDigits => _mobile.text.replaceAll(RegExp(r'\D'), '');

  static String _digitsOf(TextEditingController c) =>
      c.text.replaceAll(RegExp(r'\D'), '');

  static bool _validEmail(String value) {
    final email = value.trim();
    return email.isNotEmpty &&
        email.contains('@') &&
        email.contains('.') &&
        !email.contains(' ');
  }

  String get _identifier => _channel == 'email'
      ? _email.text.trim().toLowerCase()
      : _mobileDigits;

  String get _contactDisplay {
    if (_channel == 'email') return _email.text.trim();
    if (_mobileDigits.isEmpty) return '';
    return '${_country.displayDialCode} $_mobileDigits';
  }

  String get _dobIso {
    final dob = _dob;
    if (dob == null) return '';
    return '${dob.year.toString().padLeft(4, '0')}'
        '-${dob.month.toString().padLeft(2, '0')}'
        '-${dob.day.toString().padLeft(2, '0')}';
  }

  String get _timeOfBirth24 {
    if (_birthHour.isEmpty || _birthMinute.isEmpty || _birthPeriod.isEmpty) {
      return '';
    }
    // Same conversion as the web register page: 12-hour clock + AM/PM → 24h.
    final hour = (int.parse(_birthHour) % 12) + (_birthPeriod == 'PM' ? 12 : 0);
    return '${hour.toString().padLeft(2, '0')}:$_birthMinute';
  }

  bool get _ruleLength => _password.text.length >= 8;
  bool get _ruleNumber => _password.text.contains(RegExp(r'\d'));
  bool get _ruleSpecial => _password.text.contains(RegExp(r'[^A-Za-z0-9]'));
  bool get _passwordOk => _ruleLength && _ruleNumber && _ruleSpecial;

  void _toast(String message, {ToastType type = ToastType.warning}) {
    showAppToast(
      context,
      message,
      type: type,
      title: context.tr('auth.register'),
    );
  }

  // ---------------------------------------------------------------- actions

  void _goBack() {
    if (_success) {
      _goToSignIn();
      return;
    }
    if (_step > 1) {
      setState(() => _step -= 1);
      return;
    }
    Navigator.of(context).pop();
  }

  void _goToSignIn() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _resetOtp() {
    _resendTimer?.cancel();
    _otp.clear();
    if (!mounted) return;
    setState(() {
      _otpSent = false;
      _verified = false;
      _resendIn = 0;
      _verifiedIdentifier = '';
      _verifiedChannel = '';
    });
  }

  void _switchChannel(String channel) {
    if (channel == _channel) return;
    _resetOtp();
    setState(() => _channel = channel);
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendIn = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendIn <= 1) {
        timer.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn -= 1);
      }
    });
  }

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    if (_channel == 'email') {
      if (!_validEmail(_email.text)) {
        _toast(context.tr('register.errEmail'));
        return;
      }
    } else {
      if (_mobileDigits.isEmpty) {
        _toast(context.tr('register.errMobileRequired'));
        return;
      }
      if (_mobileDigits.length != _country.nationalNumberLength) {
        _toast(context.tr('register.errMobileLength', {
          'count': _country.nationalNumberLength,
        }));
        return;
      }
    }
    setState(() => _sendingOtp = true);
    final error = await context.read<AuthProvider>().sendRegistrationOtp(
      identifier: _identifier,
      channel: _channel,
    );
    if (!mounted) return;
    setState(() => _sendingOtp = false);
    if (error != null) {
      _toast(error, type: ToastType.error);
      return;
    }
    setState(() {
      _otpSent = true;
      _verified = false;
      _verifiedIdentifier = '';
      _verifiedChannel = '';
      _otp.clear();
    });
    _startResendCountdown();
    showAppToast(
      context,
      context.tr('register.otpSentTo', {'contact': _contactDisplay}),
      type: ToastType.success,
      title: context.tr('register.otpTitle'),
    );
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();
    if (_otp.text.length != 6) {
      _toast(context.tr('register.errOtpLength'));
      return;
    }
    setState(() => _verifyingOtp = true);
    final error = await context.read<AuthProvider>().verifyRegistrationOtp(
      identifier: _identifier,
      channel: _channel,
      otp: _otp.text,
    );
    if (!mounted) return;
    setState(() => _verifyingOtp = false);
    if (error != null) {
      _toast(error, type: ToastType.error);
      return;
    }
    _resendTimer?.cancel();
    setState(() {
      _verified = true;
      _verifiedIdentifier = _identifier;
      _verifiedChannel = _channel;
      _resendIn = 0;
    });
    showAppToast(
      context,
      context.tr('register.contactVerified', {'contact': _contactDisplay}),
      type: ToastType.success,
      title: context.tr('register.verifiedBadge'),
    );
  }

  void _continueToPersonal() {
    FocusScope.of(context).unfocus();
    // Editing the field after verification invalidates the earlier check.
    if (_verified && _identifier != _verifiedIdentifier) {
      _resetOtp();
    }
    if (_channel == 'email') {
      if (!_validEmail(_email.text)) {
        _toast(context.tr('register.errEmail'));
        return;
      }
    } else {
      if (_mobileDigits.isEmpty) {
        _toast(context.tr('register.errMobileRequired'));
        return;
      }
      if (_mobileDigits.length != _country.nationalNumberLength) {
        _toast(context.tr('register.errMobileLength', {
          'count': _country.nationalNumberLength,
        }));
        return;
      }
    }
    if (!_otpSent) {
      _toast(context.tr('register.errSendOtpFirst'));
      return;
    }
    if (!_verified) {
      _toast(context.tr('register.errVerifyFirst'));
      return;
    }
    if (_password.text.isEmpty) {
      _toast(context.tr('register.errPassword'));
      return;
    }
    if (!_passwordOk) {
      _toast(context.tr('register.errPasswordRules'));
      return;
    }
    if (_confirm.text != _password.text) {
      _toast(context.tr('register.errPasswordMatch'));
      return;
    }
    setState(() => _step = 2);
  }

  void _continueToSpiritual() {
    FocusScope.of(context).unfocus();
    if (_name.text.trim().length < 2) {
      _toast(context.tr('register.errName'));
      return;
    }
    if (_channel == 'email') {
      final digits = _digitsOf(_otherMobile);
      if (digits.isEmpty) {
        _toast(context.tr('register.errMobileRequired'));
        return;
      }
      if (digits.length != _otherCountry.nationalNumberLength) {
        _toast(context.tr('register.errMobileLength', {
          'count': _otherCountry.nationalNumberLength,
        }));
        return;
      }
    } else {
      if (!_validEmail(_otherEmail.text)) {
        _toast(context.tr('register.errEmail'));
        return;
      }
    }
    if (_dob == null) {
      _toast(context.tr('register.errDobRequired'));
      return;
    }
    if (_dob!.isAfter(DateTime.now())) {
      _toast(context.tr('register.errDobFuture'));
      return;
    }
    setState(() => _step = 3);
    _fetchSpiritual();
  }

  /// Fills nakshatra / rashi from the kundli API when birth data is complete.
  Future<void> _fetchSpiritual() async {
    final dob = _dob;
    final place = _place.text.trim();
    if (dob == null || place.isEmpty) return;
    setState(() => _spiritualFetching = true);
    final summary = await KundliService().calculateBirthKundli(
      dateOfBirth: _dobIso,
      timeOfBirth: _timeOfBirth24,
      placeOfBirth: place,
    );
    if (!mounted) return;
    setState(() => _spiritualFetching = false);
    if (summary == null) return;
    final nak = (summary['nakshatra'] ?? '').toString().trim();
    final rashi = (summary['rashi'] ?? '').toString().trim();
    setState(() {
      if (_nakshatra.text.isEmpty && nak.isNotEmpty && nak != '—') {
        _nakshatra.text = nak;
      }
      if (_rashi.text.isEmpty && rashi.isNotEmpty && rashi != '—') {
        _rashi.text = rashi;
      }
    });
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    setState(() => _registering = true);
    final isEmailChannel = _channel == 'email';
    final phoneCountry = isEmailChannel ? _otherCountry : _country;
    final langCode = context.read<LanguageProvider>().language.code;
    final error = await context.read<AuthProvider>().register(
      {
        'username': _name.text.trim(),
        'email': isEmailChannel
            ? _email.text.trim().toLowerCase()
            : _otherEmail.text.trim().toLowerCase(),
        'password': _password.text,
        'role': 'user',
        // The backend validates the phone as a 10-digit national number, the
        // same shape the web app sends; country/dial code ride along too.
        'phonenumber': isEmailChannel
            ? _digitsOf(_otherMobile)
            : _mobileDigits,
        'country_code': phoneCountry.iso,
        'dial_code': phoneCountry.displayDialCode,
        'dob': _dobIso,
        'dateofbirth': _dobIso,
        'time_of_birth': _timeOfBirth24,
        'place_of_birth': _place.text.trim(),
        'gotra': _gotra.text.trim(),
        'nakshatra': _nakshatra.text.trim(),
        'rashi': _rashi.text.trim(),
        'verified_identifier': _verifiedIdentifier,
        'verified_channel': _verifiedChannel,
        'language': langCode,
        'preferred_language': langCode,
      },
      persistSession: false,
    );
    if (!mounted) return;
    setState(() => _registering = false);
    if (error != null) {
      _toast(error, type: ToastType.error);
      return;
    }
    _resendTimer?.cancel();
    showAppToast(
      context,
      context.tr('register.accountCreated'),
      type: ToastType.success,
      title: context.tr('register.welcome'),
    );
    if (!mounted) return;
    setState(() => _success = true);
  }

  // ---------------------------------------------------------------- pickers

  Future<void> _pickDob() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (picked != null && mounted) setState(() => _dob = picked);
  }

  String _dobLabel() {
    final dob = _dob;
    if (dob == null) return context.tr('register.selectDob');
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final day = dob.day.toString().padLeft(2, '0');
    return '$day/${months[dob.month - 1]}/${dob.year}';
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      fadeStart: 0.48,
      // Three numbered sections plus the stepper need more room than the
      // baseline auth canvas, so this screen compresses on short viewports.
      designHeight: 1240,
      minScale: 0.52,
      formPadding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      header: _buildHeader(context),
      formChildren: [
        _success ? _buildSuccessBody(context) : _buildCurrentStep(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Column(
        children: [
          Row(
            children: [
              _BackButton(onTap: _goBack),
              const Spacer(),
              const AuthLanguageDropdown(),
            ],
          ),
          SizedBox(height: AuthScale.gap(context, 8)),
          const Center(child: AuthBrandLogo(size: 64, minimum: 46)),
          if (!_success) ...[
            SizedBox(height: AuthScale.gap(context, 8)),
            AuthHeading(
              context.tr('register.title'),
              fontSize: 28,
              centered: true,
            ),
            SizedBox(height: AuthScale.gap(context, 6)),
            AuthSubtitle(
              context.tr('register.joinVerified'),
              fontSize: 13.5,
              centered: true,
            ),
            SizedBox(height: AuthScale.gap(context, 12)),
            _StepIndicator(current: _step),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_step) {
      case 2:
        return _buildPersonalStep(context);
      case 3:
        return _buildSpiritualStep(context);
      default:
        return _buildVerifyStep(context);
    }
  }

  // ------------------------------------------------------------- step 1

  Widget _buildVerifyStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionBadge(
          number: 1,
          title: context.tr('register.verifyContactTitle'),
          subtitle: context.tr('register.verifyContactSubtitle'),
        ),
        SizedBox(height: AuthScale.gap(context, 8)),
        _channelTabs(context),
        SizedBox(height: AuthScale.gap(context, 8)),
        if (_channel == 'email')
          AuthTextField(
            controller: _email,
            label: context.tr('register.emailAddress').toUpperCase(),
            hint: context.tr('register.hintEmail'),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          )
        else
          AuthMobileField(
            controller: _mobile,
            label: context.tr('register.mobileNumber').toUpperCase(),
            hint: context.tr('register.hintMobile', {
              'count': _country.nationalNumberLength,
            }),
            textInputAction: TextInputAction.next,
            onCountryChanged: (country) {
              _resetOtp();
              setState(() {
                _country = country;
                _mobile.clear();
              });
            },
          ),
        if (_verified) ...[
          SizedBox(height: AuthScale.gap(context, 8)),
          _verifiedRow(context),
        ],
        SizedBox(height: AuthScale.gap(context, 8)),
        AuthGradientButton(
          label: _sendingOtp
              ? context.tr('register.sendingOtp')
              : context.tr('register.sendOtp'),
          loading: _sendingOtp,
          onPressed: _sendOtp,
        ),

        // ---- section 2: OTP (appears once a code has been sent) ----------
        if (_otpSent) ...[
          SizedBox(height: AuthScale.gap(context, 10)),
          _SectionBadge(
            number: 2,
            title: context.tr('register.otpTitle'),
            subtitle: context.tr('register.otpSentTo', {
              'contact': _contactDisplay,
            }),
            trailing: InkWell(
              onTap: _resetOtp,
              child: Text(
                context.tr('register.changeContact'),
                style: TextStyle(
                  fontSize: AuthScale.font(context, 13, minimum: 11.5),
                  fontWeight: FontWeight.w700,
                  color: authPrimaryOrange,
                ),
              ),
            ),
          ),
          SizedBox(height: AuthScale.gap(context, 8)),
          AuthFieldLabel(context.tr('register.otpLabel').toUpperCase()),
          SizedBox(height: AuthScale.gap(context, 6)),
          _otpBoxes(context),
          SizedBox(height: AuthScale.gap(context, 10)),
          Row(
            children: [
              Text(
                context.tr('register.didNotReceive'),
                style: TextStyle(
                  fontSize: AuthScale.font(context, 12.5, minimum: 11),
                  color: authGreyText,
                ),
              ),
              const Spacer(),
              if (_resendIn > 0)
                Text(
                  context.tr('register.resendIn', {'time': '${_resendIn}s'}),
                  style: TextStyle(
                    fontSize: AuthScale.font(context, 12.5, minimum: 11),
                    fontWeight: FontWeight.w600,
                    color: authGreyText,
                  ),
                )
              else
                InkWell(
                  onTap: _sendingOtp ? null : _sendOtp,
                  child: Text(
                    context.tr('register.resendOtp'),
                    style: TextStyle(
                      fontSize: AuthScale.font(context, 13, minimum: 11.5),
                      fontWeight: FontWeight.w700,
                      color: authPrimaryOrange,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AuthScale.gap(context, 12)),
          if (_verified)
            _verifiedRow(context)
          else
            AuthGradientButton(
              label: _verifyingOtp
                  ? context.tr('register.verifying')
                  : context.tr('register.verifyCode'),
              loading: _verifyingOtp,
              onPressed: _verifyOtp,
            ),
        ],

        // ---- section 3: password ----------------------------------------
        SizedBox(height: AuthScale.gap(context, 10)),
        _SectionBadge(
          number: 3,
          title: context.tr('register.passwordTitle'),
          subtitle: context.tr('register.passwordSubtitle'),
        ),
        SizedBox(height: AuthScale.gap(context, 8)),
        AuthTextField(
          controller: _password,
          label: context.tr('auth.password').toUpperCase(),
          hint: context.tr('register.createPassword'),
          icon: Icons.lock_outline_rounded,
          obscureText: _obscure,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: authDarkText,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        SizedBox(height: AuthScale.gap(context, 6)),
        AuthTextField(
          controller: _confirm,
          label: context.tr('auth.confirmPassword').toUpperCase(),
          hint: context.tr('register.hintReenterPassword'),
          icon: Icons.lock_outline_rounded,
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: authDarkText,
            ),
            onPressed: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        SizedBox(height: AuthScale.gap(context, 8)),
        _passwordRules(context),
        SizedBox(height: AuthScale.gap(context, 10)),
        AuthGradientButton(
          label: context.tr('register.continue'),
          onPressed: _continueToPersonal,
        ),
      ],
    );
  }

  Widget _channelTabs(BuildContext context) {
    Widget tab(String value, String label) {
      final selected = _channel == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => _switchChannel(value),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: AuthScale.dim(context, 40, minimum: 36),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: selected
                    ? authPrimaryOrange.withValues(alpha: 0.35)
                    : Colors.transparent,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: AuthScale.font(context, 14, minimum: 12.5),
                fontWeight: FontWeight.w700,
                color: selected ? authPrimaryOrange : authGreyText,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          tab('email', context.tr('register.tabEmail')),
          tab('phone', context.tr('register.tabPhone')),
        ],
      ),
    );
  }

  Widget _verifiedRow(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.verified_rounded, color: _green, size: 17),
        SizedBox(width: AuthScale.gap(context, 6)),
        Expanded(
          child: Text(
            context.tr('register.contactVerified', {
              'contact': _contactDisplay,
            }),
            style: TextStyle(
              fontSize: AuthScale.font(context, 12.5, minimum: 11),
              fontWeight: FontWeight.w600,
              color: _green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _otpBoxes(BuildContext context) {
    final height = AuthScale.dim(context, 54, minimum: 46);
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _otp,
              builder: (context, value, _) {
                final digits = value.text;
                final activeIndex =
                    digits.length < 6 ? digits.length : 5;
                return Row(
                  children: [
                    for (var i = 0; i < 6; i++) ...[
                      if (i > 0) SizedBox(width: AuthScale.gap(context, 8)),
                      Expanded(
                        child: Container(
                          height: height,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: !_verified && i == activeIndex
                                  ? authPrimaryOrange
                                  : const Color(0xFFE1E3E8),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            i < digits.length ? digits[i] : '',
                            style: TextStyle(
                              fontSize: AuthScale.font(
                                context,
                                21,
                                minimum: 17,
                              ),
                              fontWeight: FontWeight.w700,
                              color: authDarkText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          // Transparent field that captures typing for the six boxes above.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _otp,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordRules(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _password,
      builder: (context, pw, _) {
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: _confirm,
          builder: (context, cf, _) {
            final hasNumber = pw.text.contains(RegExp(r'\d'));
            final hasSpecial = pw.text.contains(RegExp(r'[^A-Za-z0-9]'));
            final longEnough = pw.text.length >= 8;
            final matches =
                cf.text.isNotEmpty && cf.text == pw.text;
            return Container(
              padding: EdgeInsets.all(AuthScale.gap(context, 9)),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RuleRow(ok: longEnough, label: context.tr('register.ruleMin8')),
                  SizedBox(height: AuthScale.gap(context, 4)),
                  _RuleRow(ok: hasNumber, label: context.tr('register.ruleNumber')),
                  SizedBox(height: AuthScale.gap(context, 4)),
                  _RuleRow(ok: hasSpecial, label: context.tr('register.ruleSpecial')),
                  if (cf.text.isNotEmpty) ...[
                    SizedBox(height: AuthScale.gap(context, 4)),
                    _RuleRow(
                      ok: matches,
                      bad: !matches,
                      label: context.tr(
                        matches
                            ? 'register.passwordsMatch'
                            : 'register.passwordsMismatch',
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------- step 2

  Widget _buildPersonalStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeading(
          title: context.tr('register.personalTitle'),
          subtitle: context.tr('register.personalSubtitle'),
        ),
        SizedBox(height: AuthScale.gap(context, 10)),
        _verifiedRow(context),
        SizedBox(height: AuthScale.gap(context, 12)),
        AuthTextField(
          controller: _name,
          label: context.tr('register.fullName').toUpperCase(),
          hint: context.tr('register.devoteeName'),
          icon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: AuthScale.gap(context, 8)),
        if (_channel == 'email')
          AuthMobileField(
            controller: _otherMobile,
            label: context.tr('register.mobileNumber').toUpperCase(),
            hint: context.tr('register.hintMobile', {
              'count': _otherCountry.nationalNumberLength,
            }),
            textInputAction: TextInputAction.next,
            onCountryChanged: (country) =>
                setState(() => _otherCountry = country),
          )
        else
          AuthTextField(
            controller: _otherEmail,
            label: context.tr('register.emailAddress').toUpperCase(),
            hint: context.tr('register.hintEmail'),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
        SizedBox(height: AuthScale.gap(context, 8)),
        _pickerField(
          context,
          label: context.tr('register.dateOfBirth').toUpperCase(),
          value: _dobLabel(),
          picked: _dob != null,
          icon: Icons.calendar_month_outlined,
          suffixIcon: const Icon(
            Icons.calendar_month_outlined,
            color: authPrimaryOrange,
            size: 20,
          ),
          hint: context.tr('register.selectDob'),
          onTap: _pickDob,
        ),
        SizedBox(height: AuthScale.gap(context, 8)),
        _birthTimeDropdowns(context),
        SizedBox(height: AuthScale.gap(context, 8)),
        AuthTextField(
          controller: _place,
          label: context.tr('register.placeOfBirth').toUpperCase(),
          hint: context.tr('register.hintPlace'),
          icon: Icons.place_outlined,
          textInputAction: TextInputAction.done,
        ),
        SizedBox(height: AuthScale.gap(context, 14)),
        AuthGradientButton(
          label: context.tr('register.continue'),
          onPressed: _continueToSpiritual,
        ),
      ],
    );
  }

  // Web-style time of birth: three selects — Hour (01-12), Minute (00-59)
  // and AM/PM — matching the PanditIndia create-account step 2.
  Widget _birthTimeDropdowns(BuildContext context) {
    final hours =
        List.generate(12, (i) => (i + 1).toString().padLeft(2, '0'));
    final minutes =
        List.generate(60, (i) => i.toString().padLeft(2, '0'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthFieldLabel(context.tr('register.timeOfBirth').toUpperCase()),
        SizedBox(height: AuthScale.gap(context, 5)),
        Row(
          children: [
            Expanded(
              child: _timeDropdown(
                context,
                hint: context.tr('register.hour'),
                value: _birthHour,
                items: hours,
                onChanged: (v) => setState(() => _birthHour = v ?? ''),
              ),
            ),
            SizedBox(width: AuthScale.gap(context, 8)),
            Expanded(
              child: _timeDropdown(
                context,
                hint: context.tr('register.minute'),
                value: _birthMinute,
                items: minutes,
                onChanged: (v) => setState(() => _birthMinute = v ?? ''),
              ),
            ),
            SizedBox(width: AuthScale.gap(context, 8)),
            Expanded(
              child: _timeDropdown(
                context,
                hint: context.tr('register.amPm'),
                value: _birthPeriod,
                items: const ['AM', 'PM'],
                onChanged: (v) => setState(() => _birthPeriod = v ?? ''),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _timeDropdown(
    BuildContext context, {
    required String hint,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return AuthFieldShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value.isEmpty ? null : value,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: AuthScale.font(context, 14.5, minimum: 12.5),
              color: authHintGrey,
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: AuthScale.font(context, 14.5, minimum: 12.5),
                      color: const Color(0xFF293447),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _pickerField(
    BuildContext context, {
    required String label,
    required String value,
    required bool picked,
    required IconData icon,
    required Widget suffixIcon,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthFieldLabel(label),
        SizedBox(height: AuthScale.gap(context, 5)),
        AuthFieldShell(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: InputDecorator(
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(
                  icon,
                  color: const Color(0xFF293447),
                  size: AuthScale.dim(context, 22, minimum: 18),
                ),
                suffixIcon: suffixIcon,
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: AuthScale.font(context, 14.5, minimum: 12.5),
                  color: authHintGrey,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: AuthScale.gap(context, 13),
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: AuthScale.font(context, 16, minimum: 13.5),
                    fontWeight: FontWeight.w500,
                    color: picked ? authDarkText : authHintGrey,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- step 3

  Widget _buildSpiritualStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeading(
          title: context.tr('register.spiritualTitle'),
          subtitle: context.tr('register.spiritualSubtitle'),
        ),
        SizedBox(height: AuthScale.gap(context, 14)),
        AuthTextField(
          controller: _gotra,
          label: context.tr('register.gotra'),
          hint: context.tr('register.hintGotra'),
          icon: Icons.groups_2_outlined,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: AuthScale.gap(context, 8)),
        Wrap(
          spacing: AuthScale.gap(context, 7),
          runSpacing: AuthScale.gap(context, 6),
          children: [
            for (final gotra in _gotraSuggestions)
              InkWell(
                onTap: () => setState(() => _gotra.text = gotra),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: authPrimaryOrange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: authPrimaryOrange.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    gotra,
                    style: TextStyle(
                      fontSize: AuthScale.font(context, 12.5, minimum: 11),
                      fontWeight: FontWeight.w600,
                      color: authPrimaryOrange,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: AuthScale.gap(context, 10)),
        AuthTextField(
          controller: _nakshatra,
          label: context.tr('register.nakshatra'),
          hint: context.tr('register.hintNakshatra'),
          icon: Icons.star_border_rounded,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: AuthScale.gap(context, 8)),
        AuthTextField(
          controller: _rashi,
          label: context.tr('register.rashi'),
          hint: context.tr('register.hintRashi'),
          icon: Icons.brightness_3_rounded,
          textInputAction: TextInputAction.done,
        ),
        if (_spiritualFetching) ...[
          SizedBox(height: AuthScale.gap(context, 12)),
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: authPrimaryOrange,
                ),
              ),
              SizedBox(width: AuthScale.gap(context, 8)),
              Expanded(
                child: Text(
                  context.tr('register.fetchingSpiritual'),
                  style: TextStyle(
                    fontSize: AuthScale.font(context, 12.5, minimum: 11),
                    color: authGreyText,
                  ),
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: AuthScale.gap(context, 12)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: AuthScale.dim(context, 15, minimum: 13),
              color: authGreyText,
            ),
            SizedBox(width: AuthScale.gap(context, 6)),
            Expanded(
              child: Text(
                context.tr('register.spiritualInfo'),
                style: TextStyle(
                  fontSize: AuthScale.font(context, 11.5, minimum: 10),
                  height: 1.4,
                  color: authGreyText,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AuthScale.gap(context, 16)),
        AuthGradientButton(
          label: context.tr('register.signUp'),
          loading: _registering,
          onPressed: _register,
        ),
      ],
    );
  }

  // ------------------------------------------------------------- success

  Widget _buildSuccessBody(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: AuthScale.gap(context, 26)),
        Container(
          width: AuthScale.dim(context, 116, minimum: 96),
          height: AuthScale.dim(context, 116, minimum: 96),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: AuthScale.dim(context, 76, minimum: 62),
              height: AuthScale.dim(context, 76, minimum: 62),
              decoration: const BoxDecoration(
                color: _green,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: AuthScale.dim(context, 44, minimum: 36),
              ),
            ),
          ),
        ),
        SizedBox(height: AuthScale.gap(context, 22)),
        Text(
          context.tr('register.successTitle'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AuthScale.font(context, 25, minimum: 21),
            fontWeight: FontWeight.w800,
            color: authDarkText,
          ),
        ),
        SizedBox(height: AuthScale.gap(context, 12)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AuthScale.gap(context, 6)),
          child: Text(
            context.tr('register.successBody'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AuthScale.font(context, 14.5, minimum: 12.5),
              height: 1.6,
              color: authGreyText,
            ),
          ),
        ),
        SizedBox(height: AuthScale.gap(context, 28)),
        AuthGradientButton(
          label: context.tr('register.goToSignIn'),
          onPressed: _goToSignIn,
        ),
        SizedBox(height: AuthScale.gap(context, 18)),
      ],
    );
  }
}

// ============================================================
// shared building blocks
// ============================================================

/// Numbered orange badge + title/subtitle used for the step 1 sections.
class _SectionBadge extends StatelessWidget {
  const _SectionBadge({
    required this.number,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final int number;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final d = AuthScale.dim(context, 32, minimum: 28);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: d,
          height: d,
          decoration: const BoxDecoration(
            color: authPrimaryOrange,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: AuthScale.font(context, 15, minimum: 13),
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(width: AuthScale.gap(context, 10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: AuthScale.font(context, 17, minimum: 15),
                  fontWeight: FontWeight.w800,
                  color: authDarkText,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: AuthScale.gap(context, 3)),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AuthScale.font(context, 12.5, minimum: 11),
                    height: 1.35,
                    color: authGreyText,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: AuthScale.gap(context, 8)),
          trailing!,
        ],
      ],
    );
  }
}

/// Plain title + subtitle heading used on steps 2 and 3.
class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AuthScale.font(context, 19, minimum: 16),
            fontWeight: FontWeight.w800,
            color: authDarkText,
          ),
        ),
        SizedBox(height: AuthScale.gap(context, 4)),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: AuthScale.font(context, 13, minimum: 11.5),
            height: 1.4,
            color: authGreyText,
          ),
        ),
      ],
    );
  }
}

/// One satisfied / unsatisfied password rule line.
class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.ok, required this.label, this.bad = false});

  final bool ok;
  final bool bad;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = ok
        ? const Color(0xFF16A34A)
        : (bad ? authFieldError : Colors.grey.shade400);
    return Row(
      children: [
        Icon(
          ok
              ? Icons.check_circle_rounded
              : (bad ? Icons.close_rounded : Icons.radio_button_unchecked_rounded),
          size: AuthScale.dim(context, 15, minimum: 13),
          color: color,
        ),
        SizedBox(width: AuthScale.gap(context, 7)),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AuthScale.font(context, 12.5, minimum: 11),
              fontWeight: ok ? FontWeight.w600 : FontWeight.w500,
              color: ok
                  ? authDarkText
                  : (bad ? authFieldError : authGreyText),
            ),
          ),
        ),
      ],
    );
  }
}

/// Verify / Personal Details / Spiritual Details progress header.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.tr('register.stepVerify'),
      context.tr('register.stepPersonal'),
      context.tr('register.stepSpiritual'),
    ];

    Widget item(int index) {
      final number = index + 1;
      final done = number < current;
      final active = number == current;
      final d = AuthScale.dim(context, 30, minimum: 26);
      return Column(
        children: [
          Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              color: (done || active) ? authPrimaryOrange : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: (done || active)
                    ? Colors.white
                    : const Color(0xFFDDDDDD),
                width: active ? 3 : 1.5,
              ),
              boxShadow: (done || active)
                  ? [
                      BoxShadow(
                        color: authPrimaryOrange.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: done
                  ? Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: d * 0.55,
                    )
                  : Text(
                      '$number',
                      style: TextStyle(
                        fontSize: AuthScale.font(context, 14, minimum: 12),
                        fontWeight: FontWeight.w800,
                        color: (done || active)
                            ? Colors.white
                            : authGreyText,
                      ),
                    ),
            ),
          ),
          SizedBox(height: AuthScale.gap(context, 5)),
          Text(
            labels[index],
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AuthScale.font(context, 10.5, minimum: 9.5),
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: (done || active) ? authDarkText : authGreyText,
            ),
          ),
        ],
      );
    }

    Widget line(int index) {
      final reached = index < current;
      return Padding(
        padding: EdgeInsets.only(top: AuthScale.dim(context, 14, minimum: 12)),
        child: Container(
          height: 2.5,
          decoration: BoxDecoration(
            color: reached
                ? authPrimaryOrange
                : const Color(0xFFE4E4E4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: item(0)),
        Expanded(child: line(1)),
        Expanded(child: item(1)),
        Expanded(child: line(2)),
        Expanded(child: item(2)),
      ],
    );
  }
}

/// Circular white back button used on Create Account.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = AuthScale.dim(context, 40, minimum: 36);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: d * 0.54,
          color: authDarkText,
        ),
      ),
    );
  }
}
