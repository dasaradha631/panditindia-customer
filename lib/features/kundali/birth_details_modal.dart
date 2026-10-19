import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/user_session.dart';
import '../../providers/profile_provider.dart';
import '../../services/kundli_service.dart';
import 'kundali_data.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

/// In-app birth-details editor (web birth modal, `PersonalizedKundliMuhurthamSection.jsx`
/// lines 1224-1477): full name, DOB, TOB, state/city/place, Gotra and the
/// Vedic ephemeris coordinate readout, persisted to `PUT /user/profile`.
Future<void> showBirthDetailsModal(
  BuildContext context, {
  CustomerProfile? profile,
  VoidCallback? onSaved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => BirthDetailsSheet(profile: profile, onSaved: onSaved),
  );
}

class BirthDetailsSheet extends StatefulWidget {
  const BirthDetailsSheet({super.key, this.profile, this.onSaved});

  final CustomerProfile? profile;
  final VoidCallback? onSaved;

  @override
  State<BirthDetailsSheet> createState() => _BirthDetailsSheetState();
}

class _BirthDetailsSheetState extends State<BirthDetailsSheet> {
  final KundliService _service = KundliService();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _dob = TextEditingController();
  final TextEditingController _tob = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _place = TextEditingController();
  final TextEditingController _gotra = TextEditingController();

  String? _stateValue;
  String? _latitude;
  String? _longitude;
  String? _timezone;
  Timer? _debounce;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name.text = p?.fullName ?? '';
    _dob.text = Fmt.dobInput(p?.dateOfBirth);
    _tob.text = p?.timeOfBirth ?? '';
    _city.text = p?.city ?? '';
    _state.text = p?.state ?? '';
    _place.text = p?.placeOfBirth ?? '';
    _gotra.text = p?.gotra ?? '';
    _stateValue = (p?.state?.isNotEmpty ?? false) ? p!.state : null;
    _latitude = p?.latitude;
    _longitude = p?.longitude;
    _timezone = p?.timezone ?? 'Asia/Kolkata';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [
      _name,
      _dob,
      _tob,
      _state,
      _city,
      _place,
      _gotra,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _scheduleGeoLookup() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final res = await _service.geoLookup(
        city: _city.text.trim(),
        state: _stateValue ?? _state.text.trim(),
        place: _place.text.trim(),
      );
      if (!mounted || res == null) return;
      setState(() {
        if (res.latitude != null) {
          _latitude = res.latitude!.toStringAsFixed(4);
        }
        if (res.longitude != null) {
          _longitude = res.longitude!.toStringAsFixed(4);
        }
        if (res.timezone?.isNotEmpty ?? false) _timezone = res.timezone;
        if ((res.state?.isNotEmpty ?? false) && _stateValue == null) {
          _state.text = res.state!;
        }
      });
    });
  }

  Future<void> _pickDob() async {
    final initial = DateTime.tryParse(Fmt.dobToIso(_dob.text));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(1995, 6, 15),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _dob.text = Fmt.dobInput(picked.toIso8601String()));
    _scheduleGeoLookup();
  }

  Future<void> _save() async {
    final dob = Fmt.dobToIso(_dob.text);
    final tob = _tob.text.trim();
    final place = _place.text.trim();
    if (dob.isEmpty || tob.isEmpty || place.isEmpty) {
      showAppToast(
        context,
        context.tr('kundali.birth.validation'),
        type: ToastType.warning,
        title: 'Birth Details',
      );
      return;
    }

    final provider = context.read<ProfileProvider>();
    final p = widget.profile;
    setState(() => _saving = true);

    final updated = CustomerProfile(
      id: p?.id,
      username: p?.username,
      fullName: _name.text.trim().isEmpty ? p?.fullName : _name.text.trim(),
      email: p?.email,
      phonenumber: p?.phonenumber,
      dateOfBirth: dob,
      timeOfBirth: tob,
      placeOfBirth: place,
      pujaLanguage: p?.pujaLanguage,
      gotra: _gotra.text.trim().isEmpty ? p?.gotra : _gotra.text.trim(),
      kulaDevata: p?.kulaDevata,
      nakshatra: p?.nakshatra,
      rashi: p?.rashi,
      city: _city.text.trim().isEmpty ? p?.city : _city.text.trim(),
      state: _stateValue ?? p?.state,
      address: p?.address,
      familyMembers: p?.familyMembers,
      profilePhotoUrl: p?.profilePhotoUrl,
      latitude: _latitude,
      longitude: _longitude,
      timezone: _timezone ?? p?.timezone ?? 'Asia/Kolkata',
    );

    final ok = await provider.save(updated);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      showAppToast(
        context,
        context.tr('kundali.birth.saved'),
        type: ToastType.success,
        title: 'Janam Kundali',
      );
      widget.onSaved?.call();
      Navigator.of(context).pop();
    } else {
      showAppToast(
        context,
        context.tr('kundali.birth.saveFailed'),
        type: ToastType.error,
        title: 'Birth Details',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(18, 14, 18, 18 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_calendar_outlined,
                    size: 19,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('kundali.birth.title'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        context.tr('kundali.birth.subtitle'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey<String>('birth-modal-close'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _field(
              label: context.tr('kundali.birth.fullName'),
              controller: _name,
              hint: 'e.g. Ravi Kumar',
              fieldKey: 'birth-name',
            ),
            Row(
              children: [
                Expanded(
                  child: _field(
                    label: context.tr('kundali.birth.dob'),
                    controller: _dob,
                    hint: 'DD/Month/YYYY',
                    readOnly: true,
                    fieldKey: 'birth-dob',
                    suffixIcon: IconButton(
                      key: const ValueKey<String>('birth-dob-picker'),
                      onPressed: _pickDob,
                      icon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 17,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    label: context.tr('kundali.birth.tob'),
                    controller: _tob,
                    hint: context.tr('kundali.birth.tobHint'),
                    fieldKey: 'birth-tob',
                    onChanged: (_) => _scheduleGeoLookup(),
                  ),
                ),
              ],
            ),
            _dropdownField(
              label: context.tr('kundali.birth.state'),
              value: _stateValue,
              hint: context.tr('kundali.engine.chooseFromList'),
              fieldKey: 'birth-state',
              onChanged: (v) {
                setState(() {
                  _stateValue = v;
                  _state.text = v ?? '';
                });
                _scheduleGeoLookup();
              },
            ),
            _field(
              label: context.tr('kundali.birth.city'),
              controller: _city,
              hint: context.tr('kundali.birth.cityHint'),
              fieldKey: 'birth-city',
              onChanged: (_) => _scheduleGeoLookup(),
            ),
            _field(
              label: context.tr('kundali.birth.place'),
              controller: _place,
              hint: context.tr('kundali.birth.placeHint'),
              fieldKey: 'birth-place',
              onChanged: (_) => _scheduleGeoLookup(),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('kundali.birth.coordinates'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _coordCell('Lat', _latitude),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _coordCell('Lon', _longitude),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _coordCell('Tz', _timezone),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.my_location,
                        size: 13,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          context.tr('kundali.birth.autoFetched'),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _field(
              label: context.tr('kundali.birth.gotra'),
              controller: _gotra,
              hint: context.tr('kundali.birth.gotraHint'),
              fieldKey: 'birth-gotra',
            ),
            const SizedBox(height: 16),
            AppButton(
              key: const ValueKey<String>('birth-modal-save'),
              label: _saving
                  ? context.tr('kundali.birth.saving')
                  : context.tr('kundali.birth.save'),
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _coordCell(String label, String? value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
        ),
      ),
      Text(
        value == null || value.isEmpty ? '-' : value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    ],
  );

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? fieldKey,
    bool readOnly = false,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            key: fieldKey == null ? null : ValueKey<String>(fieldKey),
            controller: controller,
            readOnly: readOnly,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.cream,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required String hint,
    required ValueChanged<String?> onChanged,
    String? fieldKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButton<String>(
              key: fieldKey == null ? null : ValueKey<String>(fieldKey),
              value: value,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              hint: Text(
                hint,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              items: [
                for (final s in kIndianStates)
                  DropdownMenuItem<String>(value: s, child: Text(s)),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
