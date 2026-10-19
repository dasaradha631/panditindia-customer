import 'dart:convert';

import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/location_detect.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/language_selector.dart';
import '../../models/ceremony.dart';
import '../../models/user_session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/profile_provider.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import 'family_members_screen.dart';
import 'india_states_data.dart';
import 'privacy_terms_screen.dart';
import 'saved_addresses_screen.dart';
import 'support_screen.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onTab});

  final void Function(int)? onTab;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) context.read<ProfileProvider>().load();
    });
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(context.tr('profile.signOutConfirm')),
        content: Text(context.tr('profile.signOutMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.tr('auth.signOut'),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profileP = context.watch<ProfileProvider>();
    final profile = profileP.profile;
    final session = auth.session;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => profileP.load(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    backgroundImage:
                        (profile?.profilePhotoUrl?.isNotEmpty ?? false)
                        ? NetworkImage(profile!.profilePhotoUrl!)
                        : null,
                    child: (profile?.profilePhotoUrl?.isNotEmpty ?? false)
                        ? null
                        : Text(
                            (session?.displayName ?? 'D')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile?.fullName ?? session?.name ?? 'Devotee',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      session?.email,
                      session?.phone,
                    ].where((s) => s != null && s.isNotEmpty).join(' • '),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StatusBadge(
                    label: context.tr('profile.vedicDevotee'),
                    color: AppColors.gold,
                    dense: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _buildSavedProfileCard(profile, session),
            const SizedBox(height: 18),
            _buildPersonalRecordsCard(profile, session),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(title: context.tr('profile.myAccount')),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _menu(
                      icon: Icons.badge_outlined,
                      label: context.tr('profile.personalInfo'),
                      subtitle: context.tr('profile.personalInfoSub'),
                      onTap: () => _editProfile(profile, session),
                    ),
                    _divider(),
                    _menu(
                      icon: Icons.translate_rounded,
                      label: context.tr('common.changeLanguage'),
                      subtitle: context
                          .read<LanguageProvider>()
                          .language
                          .nativeName,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LanguageSettingsScreen(),
                        ),
                      ),
                    ),
                    _divider(),
                    _menu(
                      icon: Icons.bookmark_border_rounded,
                      label: context.tr('profile.savedAddresses'),
                      subtitle: context.tr('profile.savedCount', {
                        'count': profileP.addresses.length,
                      }),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SavedAddressesScreen(),
                        ),
                      ),
                    ),
                    _divider(),
                    _menu(
                      icon: Icons.favorite_outline_rounded,
                      label: context.tr('profile.familyMembers'),
                      subtitle: context.tr('profile.membersCount', {
                        'count': profileP.familyMembers.length,
                      }),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FamilyMembersScreen(),
                        ),
                      ),
                    ),
                    _divider(),
                    _menu(
                      icon: Icons.notifications_none_rounded,
                      label: context.tr('nav.notifications'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(title: context.tr('nav.support')),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _menu(
                      icon: Icons.support_agent_rounded,
                      label: context.tr('support.helpSupport'),
                      subtitle: context.tr('support.raiseTicket'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SupportScreen(),
                        ),
                      ),
                    ),
                    _divider(),
                    _menu(
                      icon: Icons.privacy_tip_outlined,
                      label: context.tr('profile.privacy'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrivacyTermsScreen(),
                        ),
                      ),
                    ),
                    _divider(),
                    _menu(
                      icon: Icons.logout_rounded,
                      label: context.tr('auth.signOut'),
                      danger: true,
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Center(
              child: Text(
                'PanditIndia • v1.0.0',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(indent: 56, height: 1);

  Widget _buildSavedProfileCard(
    CustomerProfile? profile,
    UserSession? session,
  ) {
    final familyCount = _familyMemberCount(profile);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.08),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.success,
                  size: 16,
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'SAVED DEVOTEE PROFILE & GOTRA DETAILS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    context.tr('profile.savedInDatabase'),
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _profileField(
              'ANCESTRAL GOTRA',
              profile?.gotra ?? session?.gotra ?? 'Kashyapa',
            ),
            const SizedBox(height: 10),
            _profileField(
              'KULA DEVATA (DEITY)',
              profile?.kulaDevata ??
                  session?.kulaDevata ??
                  'Lord Shiva / Vishnu',
            ),
            const SizedBox(height: 10),
            _profileField(
              'DEVOTEE NAME',
              profile?.fullName ?? session?.name ?? 'Devotee',
            ),
            const SizedBox(height: 10),
            _profileField(
              'SANKALPA LANGUAGE',
              profile?.pujaLanguage ?? 'Hindi & Sanskrit',
            ),
            const SizedBox(height: 10),
            _profileField(
              'JANAM STHANA',
              (profile?.city?.isNotEmpty ?? false)
                  ? '${profile!.city}, ${profile.state ?? ''}'
                  : ((profile?.placeOfBirth?.isNotEmpty ?? false)
                        ? profile!.placeOfBirth!
                        : ((session?.city?.isNotEmpty ?? false)
                              ? '${session!.city}, ${session.state ?? ''}'
                              : 'Not Specified')),
            ),
            const SizedBox(height: 10),
            _profileField(
              'BIRTH DATE & TIME',
              (profile?.dateOfBirth?.isNotEmpty ?? false)
                  ? '${Fmt.date(profile!.dateOfBirth)}'
                        '${(profile.timeOfBirth?.isNotEmpty ?? false) ? ' (${profile.timeOfBirth})' : ''}'
                  : 'Not Specified',
            ),
            const SizedBox(height: 10),
            _profileField(
              'MOBILE NUMBER',
              profile?.phonenumber ?? session?.phone ?? 'Not Specified',
            ),
            const SizedBox(height: 10),
            _profileField(
              'FAMILY MEMBERS',
              '$familyCount Member${familyCount == 1 ? '' : 's'} Included',
            ),
          ],
        ),
      ),
    );
  }

  /// Saved-profile family count (web `familyMembersList.length`): prefers the
  /// loaded provider list, falling back to the raw `family_members` JSON on
  /// the profile itself.
  int _familyMemberCount(CustomerProfile? profile) {
    final fromProvider = context.read<ProfileProvider>().familyMembers.length;
    if (fromProvider > 0) return fromProvider;
    final raw = profile?.familyMembers?.trim();
    if (raw == null || raw.isEmpty) return 0;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.length;
    } catch (_) {
      // Not JSON — treat as unsaved/legacy data.
    }
    return 0;
  }

  Widget _profileField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalRecordsCard(
    CustomerProfile? profile,
    UserSession? session,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.info,
                  size: 16,
                ),
                const SizedBox(width: 7),
                const Text(
                  'PERSONAL & BIRTH RECORDS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _recordField(
                    'FULL NAME',
                    profile?.fullName ?? session?.name ?? 'Devotee',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _recordField(
                    'EMAIL ADDRESS',
                    profile?.email ?? session?.email ?? 'Not Specified',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _recordField(
                    'MOBILE NUMBER',
                    profile?.phonenumber ?? session?.phone ?? 'Not Specified',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _recordField(
                    'DATE OF BIRTH (DOB)',
                    (profile?.dateOfBirth?.isNotEmpty ?? false)
                        ? Fmt.date(profile!.dateOfBirth)
                        : 'Not Specified',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _recordField(
                    'TIME OF BIRTH (TOB)',
                    (profile?.timeOfBirth?.isNotEmpty ?? false)
                        ? profile!.timeOfBirth!
                        : 'Not Specified',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _recordField(
                    'STATE',
                    profile?.state ?? session?.state ?? 'Not Specified',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _recordField(
                    'CITY',
                    profile?.city ?? session?.city ?? 'Not Specified',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _recordField(
                    'PLACE OF BIRTH (CITY & STATE)',
                    (profile?.placeOfBirth?.isNotEmpty ?? false)
                        ? profile!.placeOfBirth!
                        : ((profile?.city?.isNotEmpty ?? false)
                              ? '${profile!.city}, ${profile.state ?? ''}'
                              : ((session?.city?.isNotEmpty ?? false)
                                    ? '${session!.city}, ${session.state ?? ''}'
                                    : 'Not Specified')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _recordField(
                    'LATITUDE (°N)',
                    (profile?.latitude?.isNotEmpty ?? false)
                        ? profile!.latitude!
                        : 'Not Specified',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _recordField(
                    'LONGITUDE (°E)',
                    (profile?.longitude?.isNotEmpty ?? false)
                        ? profile!.longitude!
                        : 'Not Specified',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _menu({
    required IconData icon,
    required String label,
    String? subtitle,
    VoidCallback? onTap,
    bool danger = false,
  }) {
    final color = danger ? AppColors.danger : AppColors.textDark;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (danger ? AppColors.danger : AppColors.accent).withValues(
            alpha: 0.1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: danger ? AppColors.danger : AppColors.accent,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
            ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: danger ? AppColors.danger : AppColors.textMuted,
      ),
    );
  }

  Future<void> _editProfile(
    CustomerProfile? profile,
    UserSession? session,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileEditSheet(profile: profile, session: session),
    );
    if (mounted) context.read<ProfileProvider>().load();
  }
}

class _ProfileEditSheet extends StatefulWidget {
  const _ProfileEditSheet({this.profile, this.session});

  final CustomerProfile? profile;
  final UserSession? session;

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  static final RegExp _tobPattern = RegExp(
    r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?$',
    caseSensitive: false,
  );

  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _dob;
  late final TextEditingController _gotra;
  late final TextEditingController _kula;
  late final TextEditingController _nakshatra;
  late final TextEditingController _rashi;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _placeOfBirth;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _address;
  String? _tobHour;
  String? _tobMinute;
  String? _tobPeriod;
  bool _gotraOther = false;
  late final TextEditingController _gotraManual;
  String? _pujaLanguage;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    final s = widget.session;
    _name = TextEditingController(text: p?.fullName ?? s?.name ?? '');
    _email = TextEditingController(text: p?.email ?? s?.email ?? '');
    _phone = TextEditingController(text: p?.phonenumber ?? s?.phone ?? '');
    _dob = TextEditingController(text: Fmt.dobInput(p?.dateOfBirth));
    _gotra = TextEditingController(text: p?.gotra ?? s?.gotra ?? '');
    _gotraManual = TextEditingController();
    // Ancestral gotra that isn't in the preset list (web parity: value falls
    // back to "Others" and reveals a manual-entry box).
    final savedGotra = _gotra.text.trim();
    if (savedGotra.isNotEmpty && !kGotras.contains(savedGotra)) {
      _gotraOther = true;
      _gotraManual.text = savedGotra;
    }
    _pujaLanguage =
        (p?.pujaLanguage ?? '').trim().isEmpty ? null : p!.pujaLanguage!.trim();
    _kula = TextEditingController(text: p?.kulaDevata ?? s?.kulaDevata ?? '');
    _nakshatra = TextEditingController(text: p?.nakshatra ?? '');
    _rashi = TextEditingController(text: p?.rashi ?? '');
    _city = TextEditingController(text: p?.city ?? s?.city ?? '');
    _state = TextEditingController(text: p?.state ?? s?.state ?? '');
    _placeOfBirth = TextEditingController(text: p?.placeOfBirth ?? '');
    _latitude = TextEditingController(text: p?.latitude ?? '');
    _longitude = TextEditingController(text: p?.longitude ?? '');
    _address = TextEditingController(text: p?.address ?? '');
    final tob = _parseTob(p?.timeOfBirth);
    _tobHour = tob[0];
    _tobMinute = tob[1];
    _tobPeriod = tob[2];
  }

  /// Hydrates the HH / MM / AM-PM dropdowns from either the 12-hr form the
  /// backend returns (`9:30 AM`) or a legacy 24-hr `HH:MM[:SS]` value.
  static List<String?> _parseTob(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return const <String?>[null, null, null];
    final m = _tobPattern.firstMatch(s);
    if (m == null) return const <String?>[null, null, null];
    var hour = int.tryParse(m.group(1) ?? '') ?? 0;
    final minute = int.tryParse(m.group(2) ?? '') ?? 0;
    final meridiem = (m.group(3) ?? '').toUpperCase();
    String period;
    if (meridiem.isNotEmpty) {
      if (hour < 1 || hour > 12 || minute > 59) {
        return const <String?>[null, null, null];
      }
      period = meridiem;
    } else {
      if (hour > 23 || minute > 59) {
        return const <String?>[null, null, null];
      }
      period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
    }
    return <String?>[
      hour.toString().padLeft(2, '0'),
      minute.toString().padLeft(2, '0'),
      period,
    ];
  }

  /// Saved as `07:35 AM` — the 12-hr form `PUT /user/profile` accepts.
  String get _timeOfBirth =>
      '${_tobHour ?? ''}:${_tobMinute ?? ''} ${_tobPeriod ?? ''}'.trim();

  bool get _timeOfBirthComplete =>
      (_tobHour?.isNotEmpty ?? false) &&
      (_tobMinute?.isNotEmpty ?? false) &&
      (_tobPeriod?.isNotEmpty ?? false);

  List<String> get _hourOptions => [
    for (var h = 1; h <= 12; h++) h.toString().padLeft(2, '0'),
  ];

  List<String> get _minuteOptions => [
    for (var m = 0; m < 60; m++) m.toString().padLeft(2, '0'),
  ];

  /// Every state/UT, plus whatever is currently selected so a saved value
  /// outside the table (e.g. a GPS geocode) still renders in the dropdown.
  List<String> get _stateOptions {
    final names = IndiaStatesData.stateNames;
    final current = _state.text;
    if (current.isEmpty || names.contains(current)) return names;
    return [current, ...names];
  }

  /// Cities of the selected state; a saved/GPS city outside the list stays
  /// selectable.
  List<String> get _cityOptions {
    final cities = IndiaStatesData.citiesOf(_state.text);
    final current = _city.text;
    if (current.isEmpty || cities.contains(current)) return cities;
    return [current, ...cities];
  }

  /// State changed (dropdown or the coordinates-panel input): clear a city
  /// that no longer belongs, then re-derive coordinates and place of birth.
  void _applyStateChange(String? next) {
    final state = (next ?? '').trim();
    if (_state.text != state) _state.text = state;
    // A free-typed state outside the table (mid-edit or a GPS geocode) keeps
    // the city and coordinates untouched so manual overrides survive.
    if (state.isNotEmpty && !IndiaStatesData.states.containsKey(state)) {
      return;
    }
    final city = _city.text.trim();
    if (city.isNotEmpty &&
        state.isNotEmpty &&
        !IndiaStatesData.cityInState(city, state)) {
      _city.text = '';
      _placeOfBirth.text = '';
      return;
    }
    _syncBirthGeo();
  }

  /// City changed (dropdown or the coordinates-panel input): auto-fill the
  /// ephemeris coordinates for a known city and refresh place of birth.
  void _applyCityChange(String next) {
    final city = next.trim();
    if (city.isEmpty) return;
    final state = _state.text.trim();
    final coords = IndiaStatesData.lookup(
      city,
      state: state.isEmpty ? null : state,
    );
    if (coords != null) {
      _latitude.text = '${coords.lat}';
      _longitude.text = '${coords.lon}';
    }
    var finalState = state;
    if (finalState.isEmpty) {
      finalState = IndiaStatesData.stateOfCity(city) ?? '';
      if (finalState.isNotEmpty) _state.text = finalState;
    }
    _placeOfBirth.text = finalState.isEmpty ? city : '$city, $finalState';
  }

  /// Mirrors the web dashboard's auto-fill: known city → its lat/lon, and
  /// place of birth derived from `City, State`.
  void _syncBirthGeo() {
    final city = _city.text.trim();
    if (city.isEmpty) return;
    final state = _state.text.trim();
    final coords = IndiaStatesData.lookup(
      city,
      state: state.isEmpty ? null : state,
    );
    if (coords != null) {
      _latitude.text = '${coords.lat}';
      _longitude.text = '${coords.lon}';
    }
    _placeOfBirth.text = state.isEmpty ? city : '$city, $state';
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _phone,
      _dob,
      _gotra,
      _gotraManual,
      _kula,
      _nakshatra,
      _rashi,
      _city,
      _state,
      _placeOfBirth,
      _latitude,
      _longitude,
      _address,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      showAppToast(
        context,
        context.tr('register.errName'),
        type: ToastType.warning,
        title: context.tr('profile.personalInfo'),
      );
      return;
    }
    // Web parity (`handleProfileSave`, UserDashboardPage.jsx): a valid date
    // of birth is the only other required field — city/state/coordinates
    // auto-fill through the known-city table and anything still blank keeps
    // its saved value, so a partial form never blocks saving.
    final dobRaw = _dob.text.trim();
    final dobIso = dobRaw.isEmpty ? '' : Fmt.dobToIso(dobRaw);
    if (dobRaw.isNotEmpty && dobIso.isEmpty) {
      showAppToast(
        context,
        'Enter a valid date as DD/month/YYYY, for example 06/october/2000.',
        type: ToastType.warning,
        title: context.tr('profile.personalInfo'),
      );
      return;
    }
    if (dobIso.isEmpty && (widget.profile?.dateOfBirth?.isEmpty ?? true)) {
      showAppToast(
        context,
        'Please enter your date of birth.',
        type: ToastType.warning,
        title: context.tr('profile.personalInfo'),
      );
      return;
    }
    if (_latitude.text.trim().isEmpty || _longitude.text.trim().isEmpty) {
      _syncBirthGeo();
    }
    final state = _state.text.trim();
    final city = _city.text.trim();
    final placeOfBirth = _placeOfBirth.text.trim();
    final latitude = _latitude.text.trim();
    final longitude = _longitude.text.trim();
    setState(() => saving = true);
    final existing = widget.profile;
    final updated = CustomerProfile(
      id: existing?.id,
      username: existing?.username,
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      phonenumber: _phone.text.trim(),
      dateOfBirth: dobIso.isNotEmpty ? dobIso : existing?.dateOfBirth,
      timeOfBirth: _timeOfBirthComplete ? _timeOfBirth : existing?.timeOfBirth,
      placeOfBirth: placeOfBirth.isNotEmpty
          ? placeOfBirth
          : existing?.placeOfBirth,
      pujaLanguage: (_pujaLanguage ?? '').isNotEmpty
          ? _pujaLanguage
          : existing?.pujaLanguage,
      gotra: (_gotraOther ? _gotraManual.text.trim() : _gotra.text.trim()),
      kulaDevata: _kula.text.trim(),
      nakshatra: _nakshatra.text.trim(),
      rashi: _rashi.text.trim(),
      city: city.isNotEmpty ? city : existing?.city,
      state: state.isNotEmpty ? state : existing?.state,
      address: _address.text.trim(),
      familyMembers: existing?.familyMembers,
      profilePhotoUrl: existing?.profilePhotoUrl,
      latitude: latitude.isNotEmpty ? latitude : existing?.latitude,
      longitude: longitude.isNotEmpty ? longitude : existing?.longitude,
      timezone: existing?.timezone ?? 'Asia/Kolkata',
    );
    final ok = await context.read<ProfileProvider>().save(updated);
    if (!mounted) return;
    setState(() => saving = false);
    if (!ok) {
      showAppToast(
        context,
        context.tr('profile.saveFailed'),
        type: ToastType.error,
        title: context.tr('profile.personalInfo'),
      );
      return;
    }
    if (mounted) context.read<AuthProvider>().applyProfile(updated);
    showAppToast(
      context,
      context.tr('profile.updated'),
      type: ToastType.success,
      title: context.tr('profile.personalInfo'),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('profile.personalInfo'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(label: 'Full Name', controller: _name),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Email',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Mobile',
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'ANCESTRAL GOTRA & SPIRITUAL DETAILS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _dropdownField(
                      label: 'Ancestral Gotra *',
                      value: _gotraOther
                          ? 'Others'
                          : (kGotras.contains(_gotra.text.trim())
                              ? _gotra.text.trim()
                              : null),
                      items: [
                        ...kGotras.where((g) => !g.startsWith('Other')),
                        'Others',
                      ],
                      hint: '--',
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          if (v == 'Others') {
                            _gotraOther = true;
                          } else {
                            _gotraOther = false;
                            _gotraManual.clear();
                            _gotra.text = v;
                          }
                        });
                      },
                    ),
                    if (_gotraOther) ...[
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Enter your gotra',
                        controller: _gotraManual,
                        hint: 'Type your ancestral gotra',
                        onChanged: (v) => _gotra.text = v.trim(),
                      ),
                    ],
                    const SizedBox(height: 14),
                    AppTextField(label: 'Kula Devata', controller: _kula),
                    const SizedBox(height: 14),
                    _dropdownField(
                      label: 'Preferred Puja Language',
                      value: kLanguages.contains(_pujaLanguage)
                          ? _pujaLanguage
                          : null,
                      items: kLanguages,
                      hint: '--',
                      onChanged: (v) => setState(() => _pujaLanguage = v),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Nakshatra',
                            controller: _nakshatra,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            label: 'Rashi',
                            controller: _rashi,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'TIME OF BIRTH (TOB)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _dropdownBox(
                            value: _tobHour,
                            items: _hourOptions,
                            hint: 'HH',
                            onChanged: (v) =>
                                setState(() => _tobHour = v),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _dropdownBox(
                            value: _tobMinute,
                            items: _minuteOptions,
                            hint: 'MM',
                            onChanged: (v) =>
                                setState(() => _tobMinute = v),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _dropdownBox(
                            value: _tobPeriod,
                            items: const ['AM', 'PM'],
                            hint: 'AM/PM',
                            onChanged: (v) =>
                                setState(() => _tobPeriod = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _dropdownField(
                      label: 'State',
                      value: _state.text.isEmpty ? null : _state.text,
                      items: _stateOptions,
                      hint: '--',
                      onChanged: (v) => setState(() => _applyStateChange(v)),
                    ),
                    const SizedBox(height: 14),
                    _dropdownField(
                      label: 'City',
                      value: _city.text.isEmpty ? null : _city.text,
                      items: _cityOptions,
                      hint: '--',
                      onChanged: (v) => setState(() => _applyCityChange(v ?? '')),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Place of Birth (City & State)',
                      controller: _placeOfBirth,
                      hint: 'e.g. Vijayawada, Andhra Pradesh',
                    ),
                    const SizedBox(height: 14),
                    _buildCoordinatesPanel(),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: context.tr('profile.savedAddresses'),
                      controller: _address,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    DetectLocationButton(
                      onDetected: (loc) => setState(() {
                        if ((loc.city ?? '').isNotEmpty) {
                          _city.text = loc.city!;
                        }
                        if ((loc.state ?? '').isNotEmpty) {
                          _state.text = loc.state!;
                        }
                        if (_address.text.trim().isEmpty &&
                            (loc.addressLine ?? '').isNotEmpty) {
                          _address.text = loc.addressLine!;
                        }
                        _latitude.text = loc.latitude.toStringAsFixed(4);
                        _longitude.text = loc.longitude.toStringAsFixed(4);
                        if (_placeOfBirth.text.trim().isEmpty &&
                            _city.text.trim().isNotEmpty) {
                          _placeOfBirth.text = _state.text.trim().isEmpty
                              ? _city.text.trim()
                              : '${_city.text.trim()}, ${_state.text.trim()}';
                        }
                      }),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: context.tr('profile.saveChanges'),
                      loading: saving,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinatesPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.public, size: 14, color: AppColors.info),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Geographic & Vedic Ephemeris Coordinates',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'Auto-Calculated',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _panelField(
                  label: 'City',
                  controller: _city,
                  hint: 'Birth city',
                  onChanged: (v) => setState(() => _applyCityChange(v)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _panelField(
                  label: 'State',
                  controller: _state,
                  hint: 'Birth state',
                  onChanged: (v) => setState(() => _applyStateChange(v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _panelField(
                  label: 'Latitude (°N)',
                  controller: _latitude,
                  hint: '16.5062',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _panelField(
                  label: 'Longitude (°E)',
                  controller: _longitude,
                  hint: '80.6480',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        _dropdownBox(
          value: value,
          items: items,
          hint: hint,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _dropdownBox({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: Text(
          hint,
          style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
        ),
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        items: [
          for (final option in items)
            DropdownMenuItem<String>(value: option, child: Text(option)),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _panelField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
