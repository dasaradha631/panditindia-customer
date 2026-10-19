import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/location_detect.dart';
import '../../core/widgets/common.dart';
import '../../models/catalogue_data.dart';
// The legacy `MuhuratSlot` (name/description pair) of the catalogue is
// hidden here — step 2 uses the date-driven engine in `muhurat_slots.dart`.
import '../../models/ceremony.dart' hide MuhuratSlot;
import '../../models/ceremony_samagri_data.dart';
import '../../services/kundli_service.dart';
import 'muhurat_slots.dart';
import '../../providers/booking_provider.dart';

import 'confirmation_screen.dart';
import 'samagri_kit_editor.dart';
import 'samagri_kit_sheets.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({super.key});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  final _formKey = GlobalKey<FormState>();
  bool submitting = false;

  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _special = TextEditingController();
  final _samagriNotes = TextEditingController();
  final _gotraManual = TextEditingController();
  bool _gotraOther = false;
  final _ceremonySearch = TextEditingController();
  String _ceremonyCategory = 'All';
  int _ceremonyPage = 1;
  static const int _ceremoniesPerPage = 6;

  // Step 2 (Muhurat): date-driven Vedic windows + Skyfield ephemeris.
  String _slotFilter = 'all';
  List<MuhuratSlot> _slots = const [];
  Map<String, dynamic>? _celestial;
  bool _loadingCelestial = false;
  String? _celestialError;

  @override
  void initState() {
    super.initState();
    final draft = context.read<BookingProvider>().draft;
    _name.text = draft.devoteeName;
    _mobile.text = draft.mobile;
    _email.text = draft.email;
    _address.text = draft.address;
    _city.text = draft.cityText;
    _state.text = draft.stateText;
    _pincode.text = draft.pincode;
    _special.text = draft.specialRequests;
    _samagriNotes.text = draft.samagriNotes;
    final g = draft.gothram;
    if (g == kGotras.last || (g.isNotEmpty && !kGotras.contains(g))) {
      _gotraOther = true;
      if (!kGotras.contains(g)) _gotraManual.text = g;
    }
    // Load the production `GET /pujas` catalogue (falls back to the baked-in
    // list when offline) — the step-1 picker mirrors the web booking page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<BookingProvider>();
      p.ensureCeremoniesLoaded();
      _reloadMuhurat(p);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    _special.dispose();
    _samagriNotes.dispose();
    _gotraManual.dispose();
    _ceremonySearch.dispose();
    super.dispose();
  }

  void _persistDetails(BookingProvider p) {
    p.updateDraft((d) {
      d.devoteeName = _name.text.trim();
      d.mobile = _mobile.text.trim();
      d.email = _email.text.trim();
      d.address = _address.text.trim();
      d.cityText = _city.text.trim();
      d.stateText = _state.text.trim();
      d.pincode = _pincode.text.trim();
      d.specialRequests = _special.text.trim();
    });
  }

  // ─── Venue GPS + travel distance (web parity: StepDevotee
  //     handleRecalculateDistance / geoRouting.js) ─────────────────────────
  //
  // Explicit GPS coordinates win as-is; otherwise the address / city /
  // state / pincode are resolved through the same coordinate tables and
  // lookup order as the web flow. Distance = haversine × 1.25 road
  // curvature, clamped to [3.5, 60] km and rounded to 1 decimal.
  void _applyVenueDistance(
    BookingProvider p, {
    required String address,
    required String city,
    required String state,
    required String pincode,
    double? explicitLat,
    double? explicitLon,
    bool keepExistingOnFail = false,
  }) {
    List<double>? coords;
    if (explicitLat != null &&
        explicitLon != null &&
        (explicitLat != 0 || explicitLon != 0)) {
      coords = <double>[explicitLat, explicitLon];
    } else {
      coords = _resolveVenueCoordinates(
        address: address,
        city: city,
        state: state,
        pincode: pincode,
      );
    }
    if (coords == null) {
      // Unresolvable venue → web falls back to 4.5 km + null coords. At
      // submit time we instead keep whatever the draft already captured.
      if (keepExistingOnFail) return;
      p.updateDraft((x) {
        x.distanceKm = 4.5;
        x.latitude = null;
        x.longitude = null;
      });
      return;
    }
    final venue = coords;
    final hub = _priestHubForCity(city.trim().isEmpty ? p.draft.city : city);
    final dist = _haversineDistanceKm(hub[0], hub[1], venue[0], venue[1]);
    final clamped = math.min(60.0, math.max(3.5, dist));
    final realistic = double.parse(clamped.toStringAsFixed(1));
    p.updateDraft((x) {
      x.distanceKm = realistic;
      x.latitude = venue[0];
      x.longitude = venue[1];
    });
  }

  /// Manual address / city / state edits recompute on every keystroke;
  /// pincode recomputes once 6 digits are typed (web parity).
  void _onVenueChanged(BookingProvider p) {
    _applyVenueDistance(
      p,
      address: _address.text,
      city: _city.text,
      state: _state.text,
      pincode: _pincode.text,
    );
  }

  Future<void> _openSamagriEditor(BookingProvider p) async {
    final d = p.draft;
    final result = await SamagriKitEditor.open(
      context,
      ceremonyId: d.ceremonyId,
      ceremonyName: d.ceremonyName,
      packageId: d.samagriPackageId,
      initialItems: List<SamagriItem>.of(d.samagriKitItems),
      initialNotes: d.samagriNotes,
    );
    if (result == null || !mounted) return;
    // The editor's kit-grade toggle may switch Premium ↔ Standard.
    if (result.packageId != d.samagriPackageId) {
      for (final pkg in CeremonyCatalogue.samagriPackages) {
        if (pkg.id == result.packageId) {
          p.selectSamagri(pkg); // resets any previous customization
          break;
        }
      }
    }
    final notes = result.notes.trim();
    if (notes.isNotEmpty && notes != d.samagriNotes) {
      p.updateDraft((x) => x.samagriNotes = notes);
      _samagriNotes.text = notes;
    }
    // Applying a cart identical to the (possibly new) package default keeps
    // the default pricing — never flag a non-edit as customized.
    final defaultKit = CeremonyCatalogue.samagriKitItems(
      ceremonyId: p.draft.ceremonyId,
      packageId: result.packageId,
      ceremonyName: p.draft.ceremonyName,
    );
    if (_sameKit(result.items, defaultKit)) {
      p.updateDraft((x) => x.samagriCustomized = false);
      return;
    }
    p.applyCustomSamagriKit(packageId: result.packageId, items: result.items);
  }

  static bool _sameKit(List<SamagriItem> a, List<SamagriItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].qty != b[i].qty) return false;
    }
    return true;
  }

  bool get _validateDetails {
    if (_name.text.trim().isEmpty) {
      showAppToast(
        context,
        'Please enter the devotee full name.',
        type: ToastType.warning,
        title: 'Details',
      );
      return false;
    }
    if (_mobile.text.trim().length < 10) {
      showAppToast(
        context,
        'Please enter a valid mobile number.',
        type: ToastType.warning,
        title: 'Details',
      );
      return false;
    }
    if (!_email.text.trim().contains('@')) {
      showAppToast(
        context,
        'Please enter a valid email address.',
        type: ToastType.warning,
        title: 'Details',
      );
      return false;
    }
    if (_address.text.trim().isEmpty) {
      showAppToast(
        context,
        'Please enter the ceremony address.',
        type: ToastType.warning,
        title: 'Details',
      );
      return false;
    }
    if (_city.text.trim().isEmpty || _state.text.trim().isEmpty) {
      showAppToast(
        context,
        'Please enter city and state.',
        type: ToastType.warning,
        title: 'Details',
      );
      return false;
    }
    if (_pincode.text.trim().length != 6) {
      showAppToast(
        context,
        'Please enter a valid 6-digit pincode.',
        type: ToastType.warning,
        title: 'Details',
      );
      return false;
    }
    return true;
  }

  void _next(BookingProvider p) {
    if (p.currentStep == 1 && p.draft.ceremonyId.isEmpty) {
      showAppToast(
        context,
        'Please choose a ceremony to continue.',
        type: ToastType.warning,
        title: 'Ceremony',
      );
      return;
    }
    if (p.currentStep == 2 && p.draft.date.isEmpty) {
      showAppToast(
        context,
        'Please choose a ceremony date to see the day\u2019s Muhurats.',
        type: ToastType.warning,
        title: 'Muhurat',
      );
      return;
    }
    if (p.currentStep < 4) p.setStep(p.currentStep + 1);
  }

  void _back(BookingProvider p) {
    if (p.currentStep > 1) p.setStep(p.currentStep - 1);
  }

  Future<void> _submit(BookingProvider p) async {
    if (!_validateDetails) {
      p.setStep(4);
      return;
    }
    _persistDetails(p);
    // Web parity (OrderSummary submit): make sure `latitude` / `longitude`
    // are resolved right before the payload is built — existing GPS wins,
    // otherwise resolve from the typed address, otherwise keep as-is.
    _applyVenueDistance(
      p,
      address: p.draft.address,
      city: p.draft.cityText,
      state: p.draft.stateText,
      pincode: p.draft.pincode,
      explicitLat: p.draft.latitude,
      explicitLon: p.draft.longitude,
      keepExistingOnFail: true,
    );
    if (p.draft.date.isEmpty) {
      showAppToast(
        context,
        'Please choose a ceremony date.',
        type: ToastType.warning,
        title: 'Muhurat',
      );
      p.setStep(2);
      return;
    }
    setState(() => submitting = true);
    final result = await p.submitBooking();
    if (!mounted) return;
    setState(() => submitting = false);
    if (!result.success) {
      showAppToast(
        context,
        result.message ?? 'Booking failed. Please try again.',
        type: ToastType.error,
        title: 'Booking Failed',
      );
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          bookingId: result.bookingId,
          message: result.message,
          draft: p.draft,
        ),
      ),
    );
    p.resetDraft();
  }

  Future<void> _pickDate(BookingProvider p) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(p.draft.date) ?? now.add(const Duration(days: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.accent,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    p.updateDraft((d) => d.date = picked.toIso8601String().split('T').first);
    _reloadMuhurat(p);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BookingProvider>();
    final d = p.draft;
    final steps = ['Ceremony', 'Muhurat', 'Samagri', 'Devotee'];

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: GradientAppBar(
        title: 'Book a Ceremony',
        actions: [
          Text(
            '₹${d.breakdown.totalFormatted.replaceAll('₹', '')}',
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const DashboardActionButton(),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: List.generate(steps.length, (i) {
                final num = i + 1;
                final active = num <= p.currentStep;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: num <= p.currentStep
                        ? () => p.setStep(num)
                        : null,
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active
                                ? AppColors.accent
                                : Colors.white.withValues(alpha: 0.15),
                            border: Border.all(
                              color: active
                                  ? AppColors.accent
                                  : Colors.white.withValues(alpha: 0.4),
                              width: 1.6,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$num',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: active
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            steps[i],
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Divider(
                              indent: 5,
                              endIndent: 5,
                              thickness: 1.4,
                              color: num < p.currentStep
                                  ? AppColors.accent
                                  : Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: switch (p.currentStep) {
                  1 => _stepCeremony(p),
                  2 => _stepMuhurat(p),
                  3 => _stepSamagri(p),
                  _ => _stepFinal(p),
                },
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            if (p.currentStep > 1)
              OutlinedButton(
                onPressed: () => _back(p),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textDark,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                child: const Text('Back'),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: p.currentStep == 4
                  ? AppButton(
                      label: 'Confirm Booking • ${d.breakdown.totalFormatted}',
                      onPressed: () => _submit(p),
                      loading: submitting,
                    )
                  : AppButton(label: 'Continue', onPressed: () => _next(p)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepCeremony(BookingProvider p) {
    final d = p.draft;
    final query = _ceremonySearch.text.trim().toLowerCase();
    final filtered = p.ceremonies.where((c) {
      final matchesQuery =
          query.isEmpty ||
          c.name.toLowerCase().contains(query) ||
          c.description.toLowerCase().contains(query);
      final matchesCategory =
          _ceremonyCategory == 'All' || c.category == _ceremonyCategory;
      return matchesQuery && matchesCategory;
    }).toList();
    final totalPages = (filtered.length / _ceremoniesPerPage).ceil();
    final pages = totalPages < 1 ? 1 : totalPages;
    final page = _ceremonyPage > pages ? pages : _ceremonyPage;
    final start = (page - 1) * _ceremoniesPerPage;
    final visible = filtered.skip(start).take(_ceremoniesPerPage).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your ceremony',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ceremonySearch,
          onChanged: (_) => setState(() => _ceremonyPage = 1),
          style: const TextStyle(fontSize: 13.5, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'Search pujas (e.g. Griha Pravesh, Rudrabhishek)...',
            hintStyle: const TextStyle(fontSize: 12.5),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _ceremonySearch.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _ceremonySearch.clear();
                      setState(() => _ceremonyPage = 1);
                    },
                    icon: const Icon(Icons.clear, size: 18),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final cat in ['All', ...p.ceremonyCategories])
              ChoiceChip(
                label: Text(
                  cat,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                selected: _ceremonyCategory == cat,
                selectedColor: AppColors.accent,
                backgroundColor: Colors.white,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: _ceremonyCategory == cat
                      ? Colors.white
                      : AppColors.textDark,
                ),
                side: BorderSide(
                  color: _ceremonyCategory == cat
                      ? AppColors.accent
                      : AppColors.border,
                ),
                onSelected: (_) => setState(() {
                  _ceremonyCategory = cat;
                  _ceremonyPage = 1;
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (p.loadingCeremonies && p.ceremonies.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          )
        else if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Text(
              'No ceremonies match your search. Try a different term or category.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
          )
        else
          ...visible.map((c) {
            final selected = c.id == d.ceremonyId;
            return GestureDetector(
              onTap: () => p.selectCeremony(c),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.accent : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    CeremonyImage(
                      assetPath: c.image,
                      emoji: '🪔',
                      height: 46,
                      width: 46,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${c.duration} • ${c.panditType}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Fmt.inr(c.price),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accent,
                              ),
                            ),
                            if (c.hasOfferPrice) ...[
                              const SizedBox(width: 4),
                              Text(
                                Fmt.inr(c.originalPrice),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (c.hasOfferPrice && c.discountPct > 0)
                          Text(
                            '${c.discountPct}% OFF',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.danger,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected ? AppColors.accent : AppColors.border,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }),
        if (totalPages > 1) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: page > 1
                    ? () => setState(() => _ceremonyPage = page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 26),
                color: AppColors.accent,
                disabledColor: AppColors.border,
              ),
              Text(
                'Page $page of $pages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              IconButton(
                onPressed: page < pages
                    ? () => setState(() => _ceremonyPage = page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 26),
                color: AppColors.accent,
                disabledColor: AppColors.border,
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ─── Step 2: date & Muhurat (web parity: StepMuhurat.jsx) ──────────────

  /// Recomputes the nine Vedic windows for the draft's date/city and refreshes
  /// the Skyfield ephemeris, then keeps the chosen slot in sync exactly like
  /// the web `ceremonySlots` memo + synchronization `useEffect`.
  void _reloadMuhurat(BookingProvider p) {
    final d = p.draft;
    if (d.date.isEmpty) {
      setState(() {
        _celestial = null;
        _loadingCelestial = false;
        _celestialError = null;
        _slots = computeMuhuratSlots(dateStr: '', cityStr: d.city);
      });
      _syncDraftSlot(p, _slots);
      return;
    }
    _syncLocalSlots(p);
    _fetchCelestial(p);
  }

  void _syncLocalSlots(BookingProvider p) {
    final d = p.draft;
    final slots = computeMuhuratSlots(
      dateStr: d.date,
      cityStr: d.city,
      celestial: _celestial,
    );
    setState(() => _slots = slots);
    _syncDraftSlot(p, slots);
  }

  /// Web synchronization `useEffect` — keeps the devotee's chosen window tied
  /// to the currently rendered date/city slots (custom slots stay untouched).
  void _syncDraftSlot(BookingProvider p, List<MuhuratSlot> slots) {
    if (slots.isEmpty) return;
    final current = p.draft.timeSlot;
    if (slots.any((s) => s.slotName == current)) return;
    final replacement = syncSelectedSlot(current, slots);
    if (replacement != null && replacement != p.draft.timeSlot) {
      p.updateDraft((x) => x.timeSlot = replacement);
    }
  }

  /// `GET /kundli/celestial-times` (web `kundliService.getCelestialTimes`).
  /// Any failure keeps the deterministic local solar windows instead.
  Future<void> _fetchCelestial(BookingProvider p) async {
    final date = p.draft.date;
    if (date.isEmpty) return;
    setState(() {
      _loadingCelestial = true;
      _celestialError = null;
    });
    final data = await KundliService().getCelestialTimes(
      date,
      city: p.draft.city,
    );
    if (!mounted || p.draft.date != date) return;
    setState(() {
      _loadingCelestial = false;
      if (data != null) {
        _celestial = data;
        _celestialError = null;
      } else {
        _celestialError =
            'Skyfield service unavailable — showing Surya Siddhanta calculated windows.';
      }
    });
    _syncLocalSlots(p);
  }

  List<MuhuratSlot> _visibleSlots() => _slotFilter == 'all'
      ? _slots
      : _slots.where((s) => s.category == _slotFilter).toList();

  Widget _stepMuhurat(BookingProvider p) {
    final d = p.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Auspicious Date & Muhurat',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Astronomically aligned timings according to Skyfield JPL DE421 '
          'Ephemeris & Surya Siddhanta Vedic Panchang',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _dateField(p)),
            const SizedBox(width: 12),
            Expanded(child: _cityField(p)),
          ],
        ),
        const SizedBox(height: 18),
        _ephemerisPanel(p),
        const SizedBox(height: 18),
        _slotsSection(p),
        const SizedBox(height: 18),
        _languageSection(p),
        const SizedBox(height: 20),
        const Text(
          'Travel Distance (for allowance)',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              height: 1.3,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Priest Travel Distance: ',
                              ),
                              TextSpan(
                                text:
                                    '${d.distanceKm.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.accent,
                                ),
                              ),
                              const TextSpan(text: ' from Priest Hub'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _travelTierCaption(
                            d.distanceKm,
                            d.breakdown.travelPrice,
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'TRAVEL ALLOWANCE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        d.breakdown.travelPrice == 0
                            ? 'FREE'
                            : '+${Fmt.inr(d.breakdown.travelPrice)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: d.breakdown.travelPrice == 0
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Slider(
                value: d.distanceKm.clamp(0, 60),
                max: 60,
                divisions: 60,
                activeColor: AppColors.accent,
                onChanged: (v) => p.updateDraft((x) => x.distanceKm = v),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Estimated distance',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    '${d.distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 90),
      ],
    );
  }

  Widget _dateField(BookingProvider p) {
    final d = p.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ceremony Date',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickDate(p),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    Fmt.date(d.date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pick today or any future day — Muhurats recompute for that date.',
          style: TextStyle(fontSize: 9.5, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _cityField(BookingProvider p) {
    final d = p.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'City & Region',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: kCities.contains(d.city) ? d.city : null,
          isExpanded: true,
          hint: const Text(
            'Select City & Region',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          items: [
            for (final c in kCities)
              DropdownMenuItem(
                value: c,
                child: _cityOption(c),
              ),
          ],
          onChanged: (c) {
            if (c == null) return;
            p.updateDraft((x) => x.city = c);
            if (_city.text.trim().isEmpty) {
              _city.text = c.split('(').first.trim();
            }
            _reloadMuhurat(p);
          },
        ),
        const SizedBox(height: 4),
        const Text(
          'Solar & lunar windows are calculated for the selected region.',
          style: TextStyle(fontSize: 9.5, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _cityOption(String city) {
    final open = city.indexOf('(');
    final name = open == -1 ? city : city.substring(0, open).trim();
    final areas = open == -1 || !city.endsWith(')')
        ? ''
        : city.substring(open + 1, city.length - 1).trim();
    // Tight line heights: the closed DropdownButton gives this content only
    // ~24px (48px item minus the field's vertical contentPadding), so default
    // text heights would overflow the RenderFlex by ~10px.
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.05,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        if (areas.isNotEmpty)
          Text(
            areas,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              height: 1.05,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }

  /// Web "Astronomical Solar & Lunar Ephemeris" panel — four highlight
  /// cards fed by the Skyfield endpoint, with Surya Siddhanta local solar
  /// arithmetic as the always-available fallback.
  Widget _ephemerisPanel(BookingProvider p) {
    final d = p.draft;
    if (d.date.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 26,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 6),
            Text(
              'Please select a ceremony date above to view precise '
              'astronomical timings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    final c = _celestial;
    final solar = getCalculatedSolarTimes(d.date, d.city);
    String pick(String key, String fallback) {
      final v = c?[key]?.toString();
      if (v != null && v.isNotEmpty && v != 'N/A') return v;
      return fallback;
    }

    final sunrise = pick(
      'sunrise',
      formatDecimalToTime(solar.sunriseHour),
    );
    final sunset = pick('sunset', formatDecimalToTime(solar.sunsetHour));
    final moon = nightMoonrise(c);
    final moonset = pick('moonset', '');
    final hasMoonset = moonset.isNotEmpty;
    String abhijitWindow() {
      final slot = _celestialSlotOf('abhijit_muhurat');
      if (slot != null) return slot;
      final dayDuration = (solar.sunsetHour - solar.sunriseHour)
          .clamp(10.0, 14.0);
      final len = dayDuration / 15;
      return '${formatDecimalToTime(solar.sunriseHour + 7 * len)} - '
          '${formatDecimalToTime(solar.sunriseHour + 8 * len)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Astronomical Solar & Lunar Ephemeris',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (_loadingCelestial)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: c != null
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: c != null
                        ? const Color(0xFF6EE7B7)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  c != null
                      ? 'Skyfield JPL DE421'
                      : 'Surya Siddhanta Calculated',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: c != null
                        ? const Color(0xFF065F46)
                        : AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_loadingCelestial && c == null)
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                const Expanded(child: _EphemerisSkeleton()),
              ],
            ],
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _ephemerisCard(
                  label: 'Sunrise (Surya Udaya)',
                  value: sunrise,
                  sub: 'Pratah Kaal Dawn',
                  icon: Icons.wb_sunny_rounded,
                  bg: const Color(0xFFFFFBEB),
                  border: const Color(0xFFFDE68A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ephemerisCard(
                  label: 'Sunset (Surya Asta)',
                  value: sunset,
                  sub: 'Sandhya Kaal Dusk',
                  icon: Icons.wb_twilight_rounded,
                  bg: const Color(0xFFFFF7ED),
                  border: const Color(0xFFFED7AA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ephemerisCard(
                  label: 'Moonrise (Chandrodaya)',
                  value: moon.time,
                  sub: moon.badge,
                  icon: Icons.nightlight_round,
                  bg: const Color(0xFFEEF2FF),
                  border: const Color(0xFFC7D2FE),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ephemerisCard(
                  label: hasMoonset
                      ? 'Moonset (Chandra Asta)'
                      : 'Golden Abhijit',
                  value: hasMoonset ? moonset : abhijitWindow(),
                  sub: hasMoonset
                      ? 'Lunar Setting Time'
                      : 'Supreme Vishnu Muhurat',
                  icon: hasMoonset
                      ? Icons.dark_mode_rounded
                      : Icons.star_rounded,
                  bg: const Color(0xFFECFDF5),
                  border: const Color(0xFFA7F3D0),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFC7D2FE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_rounded,
                size: 13,
                color: Color(0xFF4338CA),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Chandrodaya Night Ephemeris: ${moon.desc}.'
                  '${hasMoonset ? ' Moon remains set by $moonset.' : ''}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF312E81),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_celestialError != null && c == null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 13,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _celestialError!,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF92400E),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            'Astronomical coordinates for '
            '${(c?['city'] ?? d.city.split('(').first.trim()).toString()} '
            '(Lat ${c?['latitude'] ?? solar.latitude}°, '
            'Lon ${c?['longitude'] ?? solar.longitude}°)',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String? _celestialSlotOf(String key) {
    final block = _celestial?[key];
    if (block is Map) {
      final slot = block['slot']?.toString();
      if (slot != null && slot.isNotEmpty) return slot;
    }
    return null;
  }

  Widget _ephemerisCard({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color bg,
    required Color border,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: border,
                  ),
                ),
              ),
              Icon(icon, size: 14, color: border),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: const Color(0xFF0F172A).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Web "Auspicious Ceremony Muhurat Time Slots" — filter chips, chosen-slot
  /// bar and the nine date-driven window cards.
  Widget _slotsSection(BookingProvider p) {
    final d = p.draft;
    final filtered = _visibleSlots();
    int countOf(String cat) => _slots.where((s) => s.category == cat).length;

    Widget chip(String key, String label) {
      final active = _slotFilter == key;
      return GestureDetector(
        onTap: () => setState(() => _slotFilter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: active ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Auspicious Ceremony Muhurat Time Slots',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Choose from traditional Vedic-approved Muhurat windows before, '
          'during, and after prime hours',
          style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 2,
            runSpacing: 2,
            children: [
              chip('all', 'All Slots (${_slots.length})'),
              chip('morning', '🌅 Morning (${countOf('morning')})'),
              chip('afternoon', '☀️ Afternoon (${countOf('afternoon')})'),
              chip('evening', '🌙 Evening (${countOf('evening')})'),
            ],
          ),
        ),
        if (d.timeSlot.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFFF7ED)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CHOSEN CEREMONY SLOT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        d.timeSlot,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Text(
                    'Acharya arrives 30m prior',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        ...filtered.map((slot) => _slotCard(p, slot)),
      ],
    );
  }

  Widget _slotCard(BookingProvider p, MuhuratSlot slot) {
    final selected = slot.slotName == p.draft.timeSlot;
    final style = _slotBadgeStyle(slot.id);
    return GestureDetector(
      onTap: () => p.updateDraft((x) => x.timeSlot = slot.slotName),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : slot.isPopular
                ? const Color(0xFFFCD34D)
                : AppColors.border,
            width: selected ? 2 : 1.4,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x14FF8C00),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_slotIcon(slot.id), size: 17, color: style.$2),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    slot.title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      height: 1.2,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_off,
                  size: 17,
                  color: selected ? AppColors.accent : AppColors.border,
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              slot.timeWindow,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                height: 1.1,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: style.$1,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: style.$3),
              ),
              child: Text(
                slot.badge,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: style.$2,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              slot.desc,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 8),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.label_rounded,
                  size: 11,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Best for: ${slot.recommendedFor}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _slotIcon(String id) => switch (id) {
    'brahma' => Icons.nightlight_round,
    'pratah-shubh' => Icons.wb_sunny_rounded,
    'morning-amrit' => Icons.star_rounded,
    'morning-labha' => Icons.currency_rupee_rounded,
    'abhijit' => Icons.verified_rounded,
    'vijaya' => Icons.emoji_events_rounded,
    'sayankal-shubh' => Icons.wb_twilight_rounded,
    'godhuli-pradosham' => Icons.local_fire_department_rounded,
    _ => Icons.dark_mode_rounded,
  };

  (Color, Color, Color) _slotBadgeStyle(String id) => switch (id) {
    'brahma' => (
        const Color(0xFFF3E8FF),
        const Color(0xFF7E22CE),
        const Color(0xFFE9D5FF),
      ),
    'pratah-shubh' => (
        const Color(0xFFFFFBEB),
        const Color(0xFFB45309),
        const Color(0xFFFDE68A),
      ),
    'morning-amrit' => (
        const Color(0xFFD1FAE5),
        const Color(0xFF065F46),
        const Color(0xFF6EE7B7),
      ),
    'morning-labha' => (
        const Color(0xFFEFF6FF),
        const Color(0xFF1D4ED8),
        const Color(0xFFBFDBFE),
      ),
    'abhijit' => (
        const Color(0xFFFEF3C7),
        const Color(0xFF92400E),
        const Color(0xFFFCD34D),
      ),
    'vijaya' => (
        const Color(0xFFE0E7FF),
        const Color(0xFF3730A3),
        const Color(0xFFC7D2FE),
      ),
    'sayankal-shubh' => (
        const Color(0xFFFFEDD5),
        const Color(0xFFC2410C),
        const Color(0xFFFED7AA),
      ),
    'godhuli-pradosham' => (
        const Color(0xFFFFE4E6),
        const Color(0xFF9F1239),
        const Color(0xFFFECDD3),
      ),
    _ => (
        const Color(0xFFF1F5F9),
        const Color(0xFF334155),
        const Color(0xFFCBD5E1),
      ),
  };

  Widget _languageSection(BookingProvider p) {
    final d = p.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priest / Acharya Preferred Language',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue:
              kLanguages.contains(d.language) ? d.language : kLanguages.first,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          items: kLanguages
              .map((l) => DropdownMenuItem(value: l, child: Text(l)))
              .toList(),
          onChanged: (l) {
            if (l != null) p.updateDraft((x) => x.language = l);
          },
        ),
        const SizedBox(height: 5),
        const Text(
          'Acharyas will chant sacred Sanskrit shlokas and explain ritual '
          'meanings in your chosen regional language.',
          style: TextStyle(fontSize: 9.5, color: AppColors.textMuted),
        ),
      ],
    );
  }

  String _travelTierCaption(double km, double price) {
    if (km <= 8) {
      return '✓ Local Area (Within 8 km) — Travel Dakshina is 100% FREE & Included';
    }
    if (km <= 20) {
      return 'Extended City Transit (8-20 km) — Nominal ₹150 priest fuel/travel allowance';
    }
    return 'Outstation / Outer Suburb (${km.toStringAsFixed(1)} km) — '
        '${Fmt.inr(price)} travel allowance';
  }

  Widget _stepDevotee(BookingProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Devotee & ceremony details',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Devotee Full Name *',
          controller: _name,
          hint: 'Enter name as per tradition',
          prefix: const Icon(
            Icons.person_outline,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Mobile Number *',
                controller: _mobile,
                hint: '10-digit mobile',
                keyboardType: TextInputType.phone,
                prefix: const Icon(
                  Icons.phone_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'Pincode *',
                controller: _pincode,
                hint: '6 digits',
                keyboardType: TextInputType.number,
                prefix: const Icon(
                  Icons.pin_drop_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onChanged: (v) {
                  if (v.trim().length == 6) _onVenueChanged(p);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Email Address *',
          controller: _email,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          prefix: const Icon(
            Icons.email_outlined,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Ceremony Address *',
          controller: _address,
          hint: 'House / Street / Landmark',
          maxLines: 2,
          prefix: const Icon(
            Icons.home_outlined,
            size: 20,
            color: AppColors.textMuted,
          ),
          onChanged: (_) => _onVenueChanged(p),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'City *',
                controller: _city,
                hint: 'City',
                prefix: const Icon(
                  Icons.location_city_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onChanged: (_) => _onVenueChanged(p),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'State *',
                controller: _state,
                hint: 'State',
                prefix: const Icon(
                  Icons.map_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onChanged: (_) => _onVenueChanged(p),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        DetectLocationButton(
          onDetected: (loc) => setState(() {
            if ((loc.city ?? '').isNotEmpty) _city.text = loc.city!;
            if ((loc.state ?? '').isNotEmpty) _state.text = loc.state!;
            if ((loc.pincode ?? '').isNotEmpty) _pincode.text = loc.pincode!;
            // Web parity (`StepDevotee.handleDetectLocation`): the detected
            // full address (display name + exact GPS) always replaces whatever
            // was typed, so the venue is never left as a short stub.
            if ((loc.addressLine ?? '').isNotEmpty) {
              _address.text = loc.addressLine!;
            }
            // Real GPS fix wins over text resolution (web parity:
            // StepDevotee.handleRecalculateDistance explicit-coords branch).
            _applyVenueDistance(
              p,
              address: _address.text,
              city: _city.text,
              state: _state.text,
              pincode: _pincode.text,
              explicitLat: loc.latitude,
              explicitLon: loc.longitude,
            );
          }),
        ),
        const SizedBox(height: 20),
        const Text(
          'Ritual-specific information (optional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        _DropdownField(
          label: 'Gothram',
          value: _gotraOther
              ? kGotras.last
              : (kGotras.contains(p.draft.gothram) ? p.draft.gothram : null),
          items: kGotras,
          onChanged: (v) {
            if (v == null) return;
            if (v == kGotras.last) {
              setState(() => _gotraOther = true);
              p.updateDraft((x) => x.gothram = kGotras.last);
            } else {
              setState(() {
                _gotraOther = false;
                _gotraManual.clear();
              });
              p.updateDraft((x) => x.gothram = v);
            }
          },
        ),
        if (_gotraOther) ...[
          const SizedBox(height: 10),
          AppTextField(
            label: 'Enter your gotra',
            controller: _gotraManual,
            hint: 'Type your gotra manually',
            prefix: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: AppColors.textMuted,
            ),
            onChanged: (v) => p.updateDraft(
              (x) => x.gothram = v.trim().isEmpty ? kGotras.last : v.trim(),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _DropdownField(
                label: 'Nakshatra',
                value: p.draft.nakshatra.isEmpty ? null : p.draft.nakshatra,
                items: kNakshatras,
                onChanged: (v) => p.updateDraft((x) => x.nakshatra = v ?? ''),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DropdownField(
                label: 'Rashi',
                value: p.draft.rashi.isEmpty ? null : p.draft.rashi,
                items: kRashis,
                onChanged: (v) => p.updateDraft((x) => x.rashi = v ?? ''),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppTextField(
          label: 'Special Requests',
          controller: _special,
          hint: 'Any specific mantras, prasad or timing preferences',
          maxLines: 3,
          prefix: const Icon(
            Icons.edit_note_outlined,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Step 3 — the web `StepSamagri` panel: package picker, kit previews,
  /// customize editor and the Vedic quality guarantee banner.
  Widget _stepSamagri(BookingProvider p) {
    final d = p.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'Choose Pure Eco-Samagri Kit',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF6EE7B7)),
                ),
                child: Text(
                  'Ceremony: ${d.ceremonyName.isEmpty ? 'Selected Puja' : d.ceremonyName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          '100% Unadulterated Organic Ghee, Certified Himalayan '
          'Herbs, and Consecrated Supplies priced by ritual items.',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Samagri Package',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              ...CeremonyCatalogue.samagriPackages.map(
                (pkg) => _samagriPackageCard(p, pkg),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Samagri Kit Notes (optional)',
                controller: _samagriNotes,
                maxLines: 2,
                hint: 'Custom instructions for the Acharya about kit items...',
                prefix: const Icon(
                  Icons.edit_note_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onChanged: (v) => p.updateDraft((x) => x.samagriNotes = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 15,
                    color: Color(0xFF047857),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'PURE VEDIC QUALITY GUARANTEE & ITEM PRICE TRANSPARENCY',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: const [
                  Text(
                    '✓ A2 Organic Cow Ghee',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF064E3B),
                    ),
                  ),
                  Text(
                    '✓ Certified Pure Camphor',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF064E3B),
                    ),
                  ),
                  Text(
                    '✓ Himalayan Hawan Herbs',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF064E3B),
                    ),
                  ),
                  Text(
                    '✓ Brass/Copper Kalash & Supplies',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF064E3B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  /// Step 4 — devotee form followed by the order review (web step 4 shows
  /// `StepDevotee` fields beside `OrderSummary`; mobile stacks them).
  Widget _stepFinal(BookingProvider p) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepDevotee(p),
          const SizedBox(height: 6),
          _stepConfirm(p),
        ],
      );

  Widget _stepConfirm(BookingProvider p) {
    final d = p.draft;
    final b = d.breakdown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review & confirm',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _summaryRow('Ceremony', d.ceremonyName),
              _summaryRow('Date', Fmt.date(d.date)),
              _summaryRow('Time Slot', d.timeSlot),
              _summaryRow('Language', d.language),
              _summaryRow('City', d.cityText.isNotEmpty ? d.cityText : d.city),
              _summaryRow('Samagri Kit', _samagriPackageName(d)),
              const Divider(height: 22),
              _summaryRow('Devotee', d.devoteeName),
              _summaryRow('Mobile', d.mobile),
              _summaryRow(
                'Address',
                '${d.address}, ${d.cityText} ${d.pincode}',
              ),
              if (d.gothram.isNotEmpty) _summaryRow('Gothram', d.gothram),
              if (d.nakshatra.isNotEmpty) _summaryRow('Nakshatra', d.nakshatra),
              if (d.specialRequests.isNotEmpty)
                _summaryRow('Notes', d.specialRequests),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Price Breakdown',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _priceRow('Ceremony charges', Fmt.inr(b.ceremonyPrice)),
              if (b.panditTierPrice > 0)
                _priceRow('Pandit tier', Fmt.inr(b.panditTierPrice)),
              _priceRow(
                'Travel allowance (${d.distanceKm.toStringAsFixed(1)} km)',
                Fmt.inr(b.travelPrice),
              ),
              _samagriPriceRow(d, b),
              _priceRow('Dakshina & platform fee', Fmt.inr(b.dakshinaTrustFee)),
              const Divider(color: Colors.white24, height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total Payable',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (d.ceremonySavings > 0) ...[
                    Text(
                      Fmt.inr(b.total + d.ceremonySavings),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white54,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    b.totalFormatted,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              if (d.ceremonySavings > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'You save ${Fmt.inr(d.ceremonySavings)} on this ceremony',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6EE7B7),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                'Pay in cash or UPI to the Acharya after the ceremony. No online payment required.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: AppColors.accent,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'A verified Acharya will be assigned and will accept your booking. You can cancel free of cost until acceptance.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textDark,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 76),
      ],
    );
  }

  Widget _samagriPriceRow(BookingDraft d, PriceBreakdown b) {
    final count = d.samagriKitItems.length;
    return _priceRow(
      count == 0 ? 'Eco-Samagri kit' : 'Eco-Samagri kit ($count items)',
      Fmt.inr(b.samagriPrice),
    );
  }

  /// One selectable samagri package card (web `StepSamagri` parity): radio,
  /// name + badge, live price, description, priced item rows and the two
  /// actions — Cost Breakdown + Customize Items (+ Add/Remove).
  Widget _samagriPackageCard(BookingProvider p, SamagriPackage pkg) {
    final d = p.draft;
    final selected = pkg.id == d.samagriPackageId;
    final isNone = pkg.id == 'none';
    // The selected package reflects any customized cart (items + price come
    // from the draft getters); unselected packages keep showing defaults.
    final kitPrice = selected
        ? d.samagriPrice
        : CeremonyCatalogue.samagriKitPrice(
            ceremonyId: d.ceremonyId,
            packageId: pkg.id,
            ceremonyName: d.ceremonyName,
          );
    final kitItems = selected
        ? d.samagriKitItems
        : CeremonyCatalogue.samagriKitItems(
            ceremonyId: d.ceremonyId,
            packageId: pkg.id,
            ceremonyName: d.ceremonyName,
          );
    final customized = selected && d.samagriCustomized;
    return GestureDetector(
      onTap: () => p.selectSamagri(pkg),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 19,
                  color: selected ? AppColors.accent : AppColors.border,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            pkg.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          _pkgBadge(pkg.badge),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pkg.description,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isNone ? '₹0' : Fmt.inr(kitPrice),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                      ),
                    ),
                    if (isNone)
                      const Text(
                        '(Free Checklist)',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      )
                    else if (kitItems.isNotEmpty)
                      Text(
                        'Calculated from ${kitItems.length} items',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (!isNone && kitItems.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_rounded,
                    size: 13,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Includes ${kitItems.length} Sacred Items for '
                      '${d.ceremonyName.isEmpty ? 'your ceremony' : d.ceremonyName}:',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentHover,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._kitItemRows(kitItems),
            ],
            if (!isNone) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _kitAction(
                      label: 'Cost Breakdown',
                      icon: Icons.receipt_long_rounded,
                      filled: false,
                      onTap: () => _openBreakdownFor(
                        pkg,
                        kitPrice: kitPrice,
                        kitItems: kitItems,
                        customized: customized,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _kitAction(
                      label: customized
                          ? 'Edit Customized Kit (${kitItems.length} Items)'
                          : 'Customize Items (+ Add/Remove)',
                      icon: customized
                          ? Icons.edit_rounded
                          : Icons.tune_rounded,
                      filled: true,
                      onTap: () => _openSamagriEditor(p),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: _kitAction(
                  label: 'View Vedic Checklist',
                  icon: Icons.checklist_rounded,
                  filled: false,
                  onTap: () => _openVedicChecklist(pkg),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pkgBadge(String badge) {
    final recommended = badge.toLowerCase().contains('recommend');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: recommended ? const Color(0xFFFFF3C4) : AppColors.cream,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: recommended ? const Color(0xFFF59E0B) : AppColors.border,
        ),
      ),
      child: Text(
        badge,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
          color: recommended ? const Color(0xFF92400E) : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _kitAction({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: filled ? kKitGreen : Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: filled ? null : Border.all(color: kKitGreen),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: filled ? Colors.white : kKitGreen),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: filled ? Colors.white : kKitGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Up to four priced item rows + "+N more" chip (web list style).
  List<Widget> _kitItemRows(List<SamagriItem> items) {
    const maxRows = 4;
    final shown = items.take(maxRows).toList();
    final remaining = items.length - shown.length;
    return [
      for (final item in shown)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Fmt.inr(item.price),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      if (remaining > 0)
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '+$remaining more',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ),
        ),
    ];
  }

  void _openBreakdownFor(
    SamagriPackage pkg, {
    required double kitPrice,
    required List<SamagriItem> kitItems,
    required bool customized,
  }) {
    final d = context.read<BookingProvider>().draft;
    SamagriCostBreakdownSheet.open(
      context,
      ceremonyName: d.ceremonyName.isEmpty ? 'Selected Puja' : d.ceremonyName,
      packageName: pkg.name,
      items: kitItems,
      fallbackPrice: kitPrice,
      customized: customized,
    );
  }

  void _openVedicChecklist(SamagriPackage pkg) {
    final d = context.read<BookingProvider>().draft;
    final names = <String>{
      for (final tier in const ['premium', 'standard'])
        ...CeremonyCatalogue.samagriKitItems(
          ceremonyId: d.ceremonyId,
          packageId: tier,
          ceremonyName: d.ceremonyName,
        ).map((i) => i.name),
    };
    VedicChecklistSheet.open(
      context,
      ceremonyName: d.ceremonyName.isEmpty ? 'Selected Puja' : d.ceremonyName,
      itemNames: names.toList(),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  String _samagriPackageName(BookingDraft d) {
    if (d.samagriPackageId == 'none') return 'Devotee will arrange';
    for (final pkg in CeremonyCatalogue.samagriPackages) {
      if (pkg.id == d.samagriPackageId) return pkg.name;
    }
    return 'Eco-Samagri Kit';
  }
}

/// Pulse-style placeholder for the four ephemeris cards while the Skyfield
/// endpoint is loading (web `StepMuhurat` skeleton grid parity).
class _EphemerisSkeleton extends StatelessWidget {
  const _EphemerisSkeleton();

  static const _bar = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: _bar,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(46, 9),
          const SizedBox(height: 8),
          bar(74, 13),
          const SizedBox(height: 6),
          bar(double.infinity, 7),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                'Select $label',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
              items: items
                  .map(
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(i, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Venue coordinate resolution & travel distance ────────────────────────
// 1:1 Dart port of the web reference `frontend/src/utils/geoRouting.js`
// (CITY_COORDINATES, PINCODE_EXACT_COORDS, PINCODE_PREFIX_COORDS,
// resolveAddressCoordinates, isValidIndiaCoordinate,
// calculateHaversineDistanceKm) plus the priest-hub origin selection from
// `StepDevotee.jsx handleRecalculateDistance`, so mobile checkout distances
// match the web booking flow for the same inputs.

const Set<String> _stateNames = {
  'andhra pradesh',
  'andhra',
  'ఆంధ్ర ప్రదేశ్',
  'ఆంధ్రప్రదేశ్',
  'telangana',
  'తెలంగాణ',
  'karnataka',
  'tamil nadu',
  'maharashtra',
  'uttar pradesh',
  'west bengal',
  'gujarat',
  'rajasthan',
  'kerala',
  'punjab',
  'madhya pradesh',
  'bihar',
  'odisha',
  'uttarakhand',
  'arunachal pradesh',
  'assam',
  'chhattisgarh',
  'goa',
  'himachal pradesh',
  'jharkhand',
  'manipur',
  'meghalaya',
  'mizoram',
  'nagaland',
  'sikkim',
  'tripura',
  'haryana',
  'delhi',
};

const Map<String, List<double>> _cityCoordinates = {
  // Hyderabad & Telangana Localities
  'hyderabad': [17.3850, 78.4867],
  'secunderabad': [17.4399, 78.4983],
  'hitech city': [17.4486, 78.3741],
  'hitechcity': [17.4486, 78.3741],
  'hi tech city': [17.4486, 78.3741],
  'madhapur': [17.4483, 78.3915],
  'gachibowli': [17.4401, 78.3489],
  'banjara hills': [17.4156, 78.4357],
  'jubilee hills': [17.4319, 78.4073],
  'kukatpally': [17.4947, 78.3996],
  'kphb': [17.4930, 78.4018],
  'kphb colony': [17.4930, 78.4018],
  'kondapur': [17.4699, 78.3578],
  'manikonda': [17.4018, 78.3887],
  'puppalguda': [17.4040, 78.3750],
  'narsingi': [17.3820, 78.3610],
  'kokapet': [17.3890, 78.3300],
  'gandipet': [17.3920, 78.3050],
  'financial district': [17.4170, 78.3440],
  'nanakramguda': [17.4190, 78.3470],
  'begumpet': [17.4447, 78.4664],
  'ameerpet': [17.4375, 78.4482],
  'punjagutta': [17.4260, 78.4520],
  'panjagutta': [17.4260, 78.4520],
  'somajiguda': [17.4265, 78.4600],
  'khairatabad': [17.4110, 78.4600],
  'lakdikapul': [17.4050, 78.4650],
  'abids': [17.3910, 78.4770],
  'koti': [17.3840, 78.4830],
  'himayatnagar': [17.4020, 78.4870],
  'narayanguda': [17.3980, 78.4900],
  'mehdipatnam': [17.3916, 78.4416],
  'tolichowki': [17.4010, 78.4120],
  'shaikpet': [17.4100, 78.3980],
  'raidurg': [17.4280, 78.3820],
  'raidurgam': [17.4280, 78.3820],
  'charminar': [17.3616, 78.4747],
  'dilsukhnagar': [17.3688, 78.5247],
  'lb nagar': [17.3457, 78.5522],
  'lbnagar': [17.3457, 78.5522],
  'kothapet': [17.3700, 78.5380],
  'nagole': [17.3760, 78.5670],
  'vanasthalipuram': [17.3320, 78.5680],
  'hayathnagar': [17.3270, 78.6040],
  'uppal': [17.4018, 78.5602],
  'tarnaka': [17.4280, 78.5300],
  'sriramnagar': [17.4100, 78.4665],
  'sainagar': [17.4148, 78.4717],
  'bachupally': [17.5332, 78.3770],
  'బాచుపల్లి': [17.5332, 78.3770],
  'హైదరాబాద్': [17.3850, 78.4867],
  'కూకట్‌పల్లి': [17.4947, 78.3996],
  'మియాపూర్': [17.4968, 78.3614],
  'నిజాంపేట్': [17.5186, 78.3845],
  'గచ్చిబౌలి': [17.4401, 78.3489],
  'మాదాపూర్': [17.4483, 78.3915],
  'సికింద్రాబాద్': [17.4399, 78.4983],
  'aparna paradise road': [17.5340, 78.3760],
  'aparna paradise rd': [17.5340, 78.3760],
  'aparna paradise': [17.5340, 78.3760],
  'aparanaparadise': [17.5340, 78.3760],
  'aparanaparadise rd': [17.5340, 78.3760],
  'aparanaparadise road': [17.5340, 78.3760],
  'aparna kanopy': [17.5580, 78.3650],
  'aparna hillpark': [17.4980, 78.3320],
  'nizampet': [17.5186, 78.3845],
  'pragathi nagar': [17.5190, 78.3950],
  'pragathinagar': [17.5190, 78.3950],
  'bowrampet': [17.5520, 78.3850],
  'mallampet': [17.5450, 78.3680],
  'miyapur': [17.4968, 78.3614],
  'chandanagar': [17.4935, 78.3284],
  'madinaguda': [17.4950, 78.3440],
  'hafeezpet': [17.4850, 78.3440],
  'lingampally': [17.4890, 78.3180],
  'bhel': [17.4890, 78.3180],
  'tellapur': [17.4630, 78.2910],
  'nallagandla': [17.4720, 78.3080],
  'patancheru': [17.5280, 78.2670],
  'ameenpur': [17.5250, 78.3280],
  'beeramguda': [17.5180, 78.3050],
  'kompally': [17.5376, 78.4854],
  'medchal': [17.6297, 78.4814],
  'dundigal': [17.5730, 78.4050],
  'alwal': [17.5028, 78.5042],
  'bowenpally': [17.4690, 78.4870],
  'bolarum': [17.5180, 78.5120],
  'yapral': [17.5120, 78.5380],
  'sainikpuri': [17.4940, 78.5480],
  'ecil': [17.4680, 78.5680],
  'kapra': [17.4890, 78.5620],
  'moula ali': [17.4620, 78.5520],
  'nacharam': [17.4290, 78.5680],
  'mallapur': [17.4450, 78.5750],
  'cherlapally': [17.4720, 78.6010],
  'ghatkesar': [17.4450, 78.6830],
  'pocharam': [17.4680, 78.6750],
  'jeedimetla': [17.5180, 78.4480],
  'gajularamaram': [17.5200, 78.4200],
  'suraram': [17.5300, 78.4400],
  'quthbullapur': [17.5050, 78.4610],
  'chintal': [17.5080, 78.4480],
  'malkajgiri': [17.4520, 78.5320],
  'shamshabad': [17.2543, 78.4311],
  'rajendranagar': [17.3180, 78.4020],
  'attapur': [17.3620, 78.4320],
  'yousufguda': [17.4350, 78.4350],
  'sangareddy': [17.6327, 78.0798],

  // Bengaluru & Karnataka Localities
  'bengaluru': [12.9716, 77.5946],
  'bangalore': [12.9716, 77.5946],
  'whitefield': [12.9698, 77.7500],
  'indiranagar': [12.9784, 77.6408],
  'koramangala': [12.9352, 77.6245],
  'electronic city': [12.8399, 77.6770],
  'hsr layout': [12.9121, 77.6446],
  'jayanagar': [12.9308, 77.5838],
  'mysuru': [12.2958, 76.6394],
  'mysore': [12.2958, 76.6394],

  // Mumbai & Maharashtra Localities
  'mumbai': [19.0760, 72.8777],
  'bombay': [19.0760, 72.8777],
  'andheri': [19.1136, 72.8697],
  'bandra': [19.0596, 72.8295],
  'borivali': [19.2288, 72.8541],
  'powai': [19.1176, 72.9060],
  'pune': [18.5204, 73.8567],
  'hinjewadi': [18.5913, 73.7389],
  'wakad': [18.5987, 73.7688],
  'kothrud': [18.5074, 73.8077],
  'thane': [19.2183, 72.9781],
  'navi mumbai': [19.0330, 73.0297],
  'vashi': [19.0771, 72.9986],
  'nagpur': [21.1458, 79.0882],
  'nashik': [19.9975, 73.7898],

  // Chennai & Tamil Nadu Localities
  'chennai': [13.0827, 80.2707],
  'madras': [13.0827, 80.2707],
  't nagar': [13.0418, 80.2341],
  'adyar': [13.0012, 80.2565],
  'velachery': [12.9815, 80.2180],
  'coimbatore': [11.0168, 76.9558],
  'madurai': [9.9252, 78.1198],

  // Delhi NCR & North
  'gurugram': [28.4595, 77.0266],
  'gurgaon': [28.4595, 77.0266],
  'sector 54': [28.4355, 77.1050],
  'sector 14': [28.4750, 77.0120],
  'dlf phase': [28.4870, 77.0880],
  'cyber city': [28.4950, 77.0890],
  'delhi': [28.6139, 77.2090],
  'new delhi': [28.6139, 77.2090],
  'dwarka': [28.5823, 77.0500],
  'saket': [28.5245, 77.2066],
  'rohini': [28.7495, 77.0736],
  'noida': [28.5355, 77.3910],
  'greater noida': [28.4744, 77.5040],
  'faridabad': [28.4089, 77.3178],
  'ghaziabad': [28.6692, 77.4538],
  'chandigarh': [30.7333, 76.7794],
  'amritsar': [31.6340, 74.8723],
  'dehradun': [30.3165, 78.0322],
  'haridwar': [29.9457, 78.1642],
  'rishikesh': [30.0869, 78.2676],
  'lucknow': [26.8467, 80.9462],
  'varanasi': [25.3176, 82.9739],
  'kashi': [25.3176, 82.9739],
  'kanpur': [26.4499, 80.3319],
  'jaipur': [26.9124, 75.7873],
  'ahmedabad': [23.0225, 72.5714],
  'surat': [21.1702, 72.8311],
  'kolkata': [22.5726, 88.3639],
  'salt lake': [22.5867, 88.4178],
  'new town': [22.5897, 88.4744],
  'patna': [25.5941, 85.1376],
  'bhubaneswar': [20.2961, 85.8245],
  'kochi': [9.9312, 76.2673],
  'thiruvananthapuram': [8.5241, 76.9366],

  // Andhra Pradesh Major Cities, Districts & Pilgrimage Centers
  'andhra pradesh': [16.5062, 80.6480],
  'andhra': [16.5062, 80.6480],
  'ఆంధ్ర ప్రదేశ్': [16.5062, 80.6480],
  'ఆంధ్రప్రదేశ్': [16.5062, 80.6480],
  'vijayawada': [16.5062, 80.6480],
  'విజయవాడ': [16.5062, 80.6480],
  'amaravati': [16.5131, 80.5165],
  'అమరావతి': [16.5131, 80.5165],
  'guntur': [16.3067, 80.4365],
  'గుంటూరు': [16.3067, 80.4365],
  'mangalagiri': [16.4300, 80.5500],
  'tenali': [16.2430, 80.6400],
  'visakhapatnam': [17.6868, 83.2185],
  'విశాఖపట్నం': [17.6868, 83.2185],
  'vizag': [17.6868, 83.2185],
  'వైజాగ్': [17.6868, 83.2185],
  'gajuwaka': [17.6900, 83.2000],
  'madhurawada': [17.8000, 83.3500],
  'simhachalam': [17.7667, 83.2500],
  'anakapalle': [17.6913, 83.0039],
  'bheemili': [17.8900, 83.4500],
  'bheemunipatnam': [17.8900, 83.4500],
  'tirupati': [13.6288, 79.4192],
  'తిరుపతి': [13.6288, 79.4192],
  'tirumala': [13.6833, 79.3500],
  'తిరుమల': [13.6833, 79.3500],
  'chittoor': [13.2172, 79.1003],
  'చిత్తూరు': [13.2172, 79.1003],
  'srikalahasti': [13.7500, 79.7000],
  'శ్రీకాళహస్తి': [13.7500, 79.7000],
  'kanipakam': [13.2800, 79.0300],
  'కాణిపాకం': [13.2800, 79.0300],
  'madanapalle': [13.5500, 78.5000],
  'rajahmundry': [17.0005, 81.8040],
  'rajamahendravaram': [17.0005, 81.8040],
  'రాజమండ్రి': [17.0005, 81.8040],
  'kakinada': [16.9891, 82.2475],
  'కాకినాడ': [16.9891, 82.2475],
  'eluru': [16.7107, 81.0952],
  'ఏలూరు': [16.7107, 81.0952],
  'bhimavaram': [16.5449, 81.5212],
  'భీమవరం': [16.5449, 81.5212],
  'amalapuram': [16.5787, 82.0061],
  'palakollu': [16.5333, 81.7333],
  'tanuku': [16.7565, 81.6811],
  'tadepalligudem': [16.8139, 81.5269],
  'annavaram': [17.2800, 82.4000],
  'అన్నవరం': [17.2800, 82.4000],
  'draksharamam': [16.7900, 82.0600],
  'samalkot': [17.0500, 82.1700],
  'kurnool': [15.8281, 78.0373],
  'కర్నూలు': [15.8281, 78.0373],
  'srisailam': [16.0740, 78.8680],
  'శ్రీశైలం': [16.0740, 78.8680],
  'mantralayam': [15.9390, 77.4290],
  'మంత్రాలయం': [15.9390, 77.4290],
  'ahobilam': [15.1333, 78.7167],
  'అహోబిలం': [15.1333, 78.7167],
  'yaganti': [15.3500, 78.1300],
  'kadapa': [14.4673, 78.8242],
  'cuddapah': [14.4673, 78.8242],
  'కడప': [14.4673, 78.8242],
  'proddatur': [14.7300, 78.5500],
  'anantapur': [14.6819, 77.6006],
  'అనంతపురం': [14.6819, 77.6006],
  'dharmavaram': [14.4142, 77.7212],
  'hindupur': [13.8290, 77.4930],
  'puttaparthi': [14.1650, 77.8110],
  'lepakshi': [13.8040, 77.6070],
  'nellore': [14.4426, 79.9865],
  'నెల్లూరు': [14.4426, 79.9865],
  'gudur': [14.1500, 79.8500],
  'kavali': [14.9130, 79.9900],
  'ongole': [15.5057, 80.0499],
  'ఒంగోలు': [15.5057, 80.0499],
  'chirala': [15.8246, 80.3522],
  'markapur': [15.7350, 79.2700],
  'srikakulam': [18.2949, 83.8938],
  'శ్రీకాకుళం': [18.2949, 83.8938],
  'arasavalli': [18.3000, 83.9100],
  'vizianagaram': [18.1067, 83.3956],
  'విజయనగరం': [18.1067, 83.3956],
  'machilipatnam': [16.1875, 81.1389],
  'bobbili': [18.5700, 83.3700],
  'nandyal': [15.4800, 78.4800],
  'నంద్యాల': [15.4800, 78.4800],
  'parvathipuram': [18.7800, 83.4300],
  'palasa': [18.7700, 84.4100],

  // Other States
  'haryana': [28.4595, 77.0266],
  'telangana': [17.3850, 78.4867],
  'karnataka': [12.9716, 77.5946],
  'maharashtra': [19.0760, 72.8777],
  'tamil nadu': [13.0827, 80.2707],
  'uttar pradesh': [26.8467, 80.9462],
  'west bengal': [22.5726, 88.3639],
  'gujarat': [23.0225, 72.5714],
  'rajasthan': [26.9124, 75.7873],
  'kerala': [9.9312, 76.2673],
  'punjab': [30.7333, 76.7794],
  'madhya pradesh': [23.2599, 77.4126],
  'bihar': [25.5941, 85.1376],
  'odisha': [20.2961, 85.8245],
  'uttarakhand': [30.3165, 78.0322],
};

const Map<String, List<double>> _pincodeExactCoords = {
  // Hyderabad & Telangana
  '500090': [17.5332, 78.3770], // Bachupally / Bowrampet / Pragathi Nagar
  '500072': [17.4947, 78.3996], // Kukatpally / KPHB
  '500049': [17.4968, 78.3614], // Miyapur
  '500081': [17.4483, 78.3915], // Madhapur / Hitech City
  '500084': [17.4699, 78.3578], // Kondapur
  '500032': [17.4401, 78.3489], // Gachibowli
  '500089': [17.4018, 78.3887], // Manikonda / Puppalguda
  '500075': [17.3820, 78.3610], // Narsingi / Gandipet / Kokapet
  '500050': [17.4935, 78.3284], // Chandanagar
  '500019': [17.4890, 78.3180], // Lingampally / BHEL
  '500034': [17.4156, 78.4357], // Banjara Hills
  '500033': [17.4319, 78.4073], // Jubilee Hills
  '500003': [17.4399, 78.4983], // Secunderabad
  '500016': [17.4447, 78.4664], // Begumpet
  '500060': [17.3688, 78.5247], // Dilsukhnagar
  '500074': [17.3457, 78.5522], // LB Nagar
  '500039': [17.4018, 78.5602], // Uppal
  '500014': [17.4280, 78.5300], // Tarnaka
  '500010': [17.5180, 78.5120], // Bolarum
  '500015': [17.4610, 78.5020], // Trimulgherry / Karkhana
  '500087': [17.5120, 78.5380], // Yapral / Sainikpuri
  '500047': [17.5028, 78.5042], // Alwal
  '500055': [17.5180, 78.4480], // Jeedimetla / Chintal
  '500067': [17.5730, 78.4050], // Dundigal
  '500043': [17.5450, 78.3680], // Mallampet
  '500100': [17.5376, 78.4854], // Kompally
  '500001': [17.3910, 78.4770], // Abids / Koti
  '500002': [17.3616, 78.4747], // Charminar
  '500004': [17.4080, 78.4620], // Khairatabad / Lakdikapul
  '500028': [17.3916, 78.4416], // Mehdipatnam
  '500008': [17.3833, 78.4011], // Golconda / Tolichowki
  '501401': [17.6297, 78.4814], // Medchal
  '502032': [17.5280, 78.2670], // Patancheru
  '502319': [17.5250, 78.3280], // Ameenpur / Beeramguda
  '500077': [17.2543, 78.4311], // Shamshabad
  '500030': [17.3180, 78.4020], // Rajendranagar
  '500048': [17.3620, 78.4320], // Attapur
  '500070': [17.3320, 78.5680], // Vanasthalipuram
  '500068': [17.3760, 78.5670], // Nagole
  '500076': [17.4290, 78.5680], // Nacharam
  '500051': [17.4620, 78.5520], // Moula Ali
  '500062': [17.4680, 78.5680], // ECIL / Kapra
  '500096': [17.5050, 78.4610], // Quthbullapur

  // Bengaluru
  '560001': [12.9716, 77.5946], // Bangalore GPO
  '560066': [12.9698, 77.7500], // Whitefield
  '560038': [12.9784, 77.6408], // Indiranagar
  '560034': [12.9352, 77.6245], // Koramangala
  '560100': [12.8399, 77.6770], // Electronic City
  '560102': [12.9121, 77.6446], // HSR Layout
  '560041': [12.9308, 77.5838], // Jayanagar

  // Mumbai & Pune
  '400001': [19.0760, 72.8777], // Mumbai Fort
  '400053': [19.1136, 72.8697], // Andheri West
  '400050': [19.0596, 72.8295], // Bandra West
  '400076': [19.1176, 72.9060], // Powai
  '400092': [19.2288, 72.8541], // Borivali West
  '411057': [18.5987, 73.7688], // Wakad Pune (web duplicate key: last wins)

  // Chennai
  '600017': [13.0418, 80.2341], // T Nagar
  '600020': [13.0012, 80.2565], // Adyar
  '600042': [12.9815, 80.2180], // Velachery

  // Andhra Pradesh Exact 6-Digit Pincodes
  '520001': [16.5062, 80.6480], // Vijayawada City
  '520002': [16.5150, 80.6300], // Vijayawada Governorpet
  '520008': [16.5000, 80.6600], // Vijayawada Patamata
  '520010': [16.5060, 80.6400], // Vijayawada Benz Circle
  '522001': [16.3067, 80.4365], // Guntur Head Post Office
  '522002': [16.3100, 80.4400], // Guntur Arundelpet
  '522006': [16.2900, 80.4500], // Guntur Brodipet
  '522503': [16.4300, 80.5500], // Mangalagiri
  '530001': [17.6868, 83.2185], // Visakhapatnam Town
  '530017': [17.7200, 83.3100], // Visakhapatnam MVP Colony
  '530026': [17.6900, 83.2000], // Gajuwaka
  '530041': [17.8000, 83.3500], // Madhurawada
  '530028': [17.7667, 83.2500], // Simhachalam
  '517501': [13.6288, 79.4192], // Tirupati City
  '517504': [13.6833, 79.3500], // Tirumala Hills
  '517507': [13.6300, 79.4300], // Tirupati Renigunta
  '517644': [13.7500, 79.7000], // Srikalahasti
  '517127': [13.2800, 79.0300], // Kanipakam
  '533001': [16.9891, 82.2475], // Kakinada City
  '533101': [17.0005, 81.8040], // Rajahmundry City
  '533406': [17.2800, 82.4000], // Annavaram
  '534001': [16.7107, 81.0952], // Eluru City
  '534201': [16.5449, 81.5212], // Bhimavaram
  '518001': [15.8281, 78.0373], // Kurnool City
  '518101': [16.0740, 78.8680], // Srisailam Devasthanam
  '518345': [15.9390, 77.4290], // Mantralayam
  '515001': [14.6819, 77.6006], // Anantapur City
  '515134': [14.1650, 77.8110], // Puttaparthi
  '516001': [14.4673, 78.8242], // Kadapa City
  '524001': [14.4426, 79.9865], // Nellore City
  '523001': [15.5057, 80.0499], // Ongole City
  '535001': [18.1067, 83.3956], // Vizianagaram City
  '532001': [18.2949, 83.8938], // Srikakulam City
  '518501': [15.4800, 78.4800], // Nandyal

  // Delhi NCR
  '122001': [28.4595, 77.0266], // Gurugram
  '122002': [28.4870, 77.0880], // DLF Phase Gurugram
  '110001': [28.6139, 77.2090], // Connaught Place Delhi
  '201301': [28.5355, 77.3910], // Noida Sector
};

const Map<String, List<double>> _pincodePrefixCoords = {
  // Telangana
  '500': [17.3850, 78.4867], // Hyderabad Central
  '501': [17.3850, 78.4867], // Hyderabad outer
  '502': [17.5500, 78.1500], // Medak / Sangareddy
  '503': [18.6725, 78.0941], // Nizamabad
  '504': [19.6640, 78.5320], // Adilabad
  '505': [18.4386, 79.1288], // Karimnagar
  '506': [17.9689, 79.5941], // Warangal
  '507': [17.2473, 80.1514], // Khammam
  '508': [17.0575, 79.2684], // Nalgonda
  '509': [16.7488, 77.9840], // Mahabubnagar

  // Andhra Pradesh Districts
  '515': [14.6819, 77.6006], // Anantapur
  '516': [14.4673, 78.8242], // Kadapa (YSR District)
  '517': [13.6288, 79.4192], // Tirupati / Chittoor
  '518': [15.8281, 78.0373], // Kurnool / Nandyal
  '520': [16.5062, 80.6480], // Vijayawada / NTR District
  '521': [16.1875, 81.1389], // Machilipatnam / Krishna
  '522': [16.3067, 80.4365], // Guntur / Palnadu / Bapatla
  '523': [15.5057, 80.0499], // Ongole / Prakasam
  '524': [14.4426, 79.9865], // Nellore (SPSR Nellore)
  '530': [17.6868, 83.2185], // Visakhapatnam City
  '531': [17.6913, 83.0039], // Anakapalle / Alluri Sitharama Raju
  '532': [18.2949, 83.8938], // Srikakulam
  '533': [16.9891, 82.2475], // Kakinada / Konaseema / Rajahmundry
  '534': [16.7107, 81.0952], // Eluru / West Godavari (Bhimavaram)
  '535': [18.1067, 83.3956], // Vizianagaram / Parvathipuram Manyam
};

/// Port of web `resolveAddressCoordinates` — same tables, same lookup order:
/// address locality (longest key first) → exact 6-digit pincode →
/// city/locality → 3-digit pincode prefix → state. Returns `null` when the
/// venue cannot be resolved (web returns `[null, null]`).
List<double>? _resolveVenueCoordinates({
  required String address,
  required String city,
  required String state,
  required String pincode,
}) {
  final rawAddr = address.trim().toLowerCase();
  final cleanCity = city.replaceAll(RegExp(r'\(.*?\)'), '').trim().toLowerCase();
  final cleanState = state.trim().toLowerCase();
  var digits = (pincode.isNotEmpty ? pincode : address).replaceAll(
    RegExp(r'\D'),
    '',
  );
  if (digits.length > 6) digits = digits.substring(0, 6);
  final cleanPin = digits;
  final combined = '$rawAddr $cleanCity $cleanState'.trim();

  final sortedKeys = _cityCoordinates.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  final cityKeys = sortedKeys.where((k) => !_stateNames.contains(k)).toList();

  // 1. Locality / suburb inside the venue address (longest match first).
  if (rawAddr.isNotEmpty) {
    for (final key in cityKeys) {
      if (rawAddr.contains(key)) return _cityCoordinates[key];
    }
  }

  // 2. Exact 6-digit pincode anchor (e.g. 500090 → Bachupally).
  if (cleanPin.length == 6) {
    final exact = _pincodeExactCoords[cleanPin];
    if (exact != null) return exact;
  }

  // 3. City / locality typed directly.
  if (cleanCity.isNotEmpty) {
    for (final key in cityKeys) {
      if (cleanCity.contains(key) || key.contains(cleanCity)) {
        return _cityCoordinates[key];
      }
    }
  }

  // 4. 3-digit pincode prefix (e.g. 515 → Anantapur, 535 → Vizianagaram).
  if (cleanPin.length >= 3) {
    final prefix = _pincodePrefixCoords[cleanPin.substring(0, 3)];
    if (prefix != null) return prefix;
  }

  // 5. Broad state fallback.
  for (final key in sortedKeys) {
    if (cleanState.contains(key) || (_stateNames.contains(key) && combined.contains(key))) {
      return _cityCoordinates[key];
    }
  }

  return null;
}

/// Port of web `isValidIndiaCoordinate` — India's bounding box.
bool _isValidIndiaCoordinate(double lat, double lon) {
  if (lat.isNaN || lon.isNaN) return false;
  if (lat == 0 || lon == 0) return false;
  return lat >= 6.0 && lat <= 38.0 && lon >= 68.0 && lon <= 98.0;
}

/// Port of web `calculateHaversineDistanceKm` — haversine × 1.25 Indian
/// urban road curvature; returns 0 for invalid / identical points.
double _haversineDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  if (!_isValidIndiaCoordinate(lat1, lon1) ||
      !_isValidIndiaCoordinate(lat2, lon2)) {
    return 0;
  }
  if (lat1 == lat2 && lon1 == lon2) return 0;
  const earthRadiusKm = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  final roadDistance = earthRadiusKm * c * 1.25;
  return roadDistance > 0 ? roadDistance : 0;
}

/// Priest-hub origin for the given city — port of the `centerCoords`
/// selection in web `StepDevotee.jsx handleRecalculateDistance` (the same
/// keyword lists and constants, including the default Hyderabad hub).
List<double> _priestHubForCity(String city) {
  final cityKey = city.toLowerCase();
  const hyderabadCenter = <double>[17.3850, 78.4867];
  const apCenter = <double>[16.9988, 80.4143];
  const apKeywords = [
    'andhrapradesh',
    'amaravathi',
    'vijayawada',
    'visakhapatnam',
    'guntur',
    'kurnool',
    'tirupati',
    'nellore',
    'rajahmundry',
    'kakinada',
    'ongole',
    'proddatur',
    'vijayanagaram',
    'eluru',
    'tadepalligudem',
    'amalapuram',
    'bhadrachalam',
  ];
  if (apKeywords.any((k) => cityKey.contains(k))) return apCenter;
  const telanganaKeywords = [
    'telangana',
    'hyderabad',
    'warangal',
    'karimnagar',
    'nizamabad',
    'khammam',
    'adilabad',
    'mahabubnagar',
    'suryapet',
    'miryalaguda',
  ];
  if (telanganaKeywords.any((k) => cityKey.contains(k))) {
    return hyderabadCenter;
  }
  if (cityKey.contains('bengaluru') || cityKey.contains('bangalore')) {
    return <double>[12.9716, 77.5946];
  }
  if (cityKey.contains('mumbai')) return <double>[19.0760, 72.8777];
  if (cityKey.contains('chennai')) return <double>[13.0827, 80.2707];
  if (cityKey.contains('pune')) return <double>[18.5204, 73.8567];
  return hyderabadCenter; // Default Hyderabad
}
