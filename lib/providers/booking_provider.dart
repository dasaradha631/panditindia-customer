import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/catalogue_data.dart';
import '../models/ceremony.dart';
import '../models/ceremony_samagri_data.dart';
import '../services/booking_service.dart';
import '../services/puja_service.dart';

class BookingDraft {
  String ceremonyId = '5';
  String ceremonyName = 'Griha Pravesh & Vastu Shanti';
  double ceremonyPrice = 5100;

  /// Pre-discount list price of the selected ceremony (0 when no live offer).
  /// Mirrors the web booking page, which shows the strikethrough original
  /// total and the "You save" amount in the order summary.
  double ceremonyOriginalPrice = 0;
  String panditTierId = 'standard';
  String panditTierName = 'Certified Vedic Purohit';
  double panditTierPrice = 0;
  double distanceKm = 4.5;
  double? latitude;
  double? longitude;
  String date = '';
  String timeSlot = 'Morning Abhijit Muhurat (08:00 AM - 11:30 AM)';
  String language = 'Hindi & Sanskrit';
  String city = kCities.first;
  String samagriPackageId = 'premium';
  bool samagriCustomized = false;
  List<SamagriItem> customSamagriItems = const [];
  String samagriNotes = '';
  String devoteeName = '';
  String mobile = '';
  String email = '';
  String address = '';
  String cityText = '';
  String stateText = '';
  String pincode = '';
  String gothram = '';
  String nakshatra = '';
  String rashi = '';
  String specialRequests = '';

  /// Kit price for the currently selected ceremony + package. Web parity:
  /// the actual charge is `calculateKitTotal(getCeremonyKitItems(id, tier))`
  /// (e.g. grihapravesh ₹1,050 premium / ₹640 standard), falling back to the
  /// flat ₹800/₹500 package prices when the ceremony has no kit mapping.
  /// A customized kit charges the live total of the edited cart, exactly
  /// like the web booking flow's `updateSamagriKit`.
  double get samagriPrice {
    if (samagriPackageId == 'none') return 0;
    if (samagriCustomized) {
      return CeremonySamagriData.calculateKitTotal(customSamagriItems);
    }
    return CeremonyCatalogue.samagriKitPrice(
      ceremonyId: ceremonyId,
      packageId: samagriPackageId,
      ceremonyName: ceremonyName,
    );
  }

  List<SamagriItem> get samagriKitItems {
    if (samagriPackageId == 'none') return const [];
    if (samagriCustomized) return customSamagriItems;
    return CeremonyCatalogue.samagriKitItems(
      ceremonyId: ceremonyId,
      packageId: samagriPackageId,
      ceremonyName: ceremonyName,
    );
  }

  PriceBreakdown get breakdown => PriceBreakdown(
    ceremonyPrice: ceremonyPrice,
    panditTierPrice: panditTierPrice,
    travelPrice: calculateTravelAllowance(distanceKm),
    samagriPrice: samagriPrice,
    dakshinaTrustFee: 51,
    distanceKm: distanceKm,
  );

  /// Amount saved on the ceremony via a live offer (web "You save").
  double get ceremonySavings =>
      ceremonyOriginalPrice > ceremonyPrice
          ? ceremonyOriginalPrice - ceremonyPrice
          : 0;
}

class BookingProvider extends ChangeNotifier {
  BookingProvider() {
    final tomorrow = DateTime.now().add(const Duration(days: 2));
    draft.date = tomorrow.toIso8601String().split('T').first;
  }

  final BookingService _service = BookingService();
  final PujaService _pujaService = PujaService();

  int currentStep = 1;
  BookingDraft draft = BookingDraft();
  List<Booking> myBookings = [];
  bool loadingBookings = false;
  Timer? _pollTimer;

  /// Ceremony catalogue. Prefers the production `GET /pujas` feed (live
  /// offer pricing); falls back to the baked-in list when the API is
  /// unreachable — same strategy as the web booking page.
  List<Ceremony> ceremonies = CeremonyCatalogue.ceremonies;
  bool loadingCeremonies = false;
  bool usedCeremoniesFallback = false;
  bool _ceremoniesLoaded = false;

  bool get ceremoniesIsApi => !usedCeremoniesFallback;

  /// Loads the catalogue once per app run (or again after a failed attempt).
  Future<void> ensureCeremoniesLoaded({bool force = false}) async {
    if (_ceremoniesLoaded && !force) return;
    if (loadingCeremonies) return;
    loadingCeremonies = true;
    notifyListeners();
    try {
      final list = await _pujaService.getAllPujas();
      if (list.isNotEmpty) {
        ceremonies = list;
        usedCeremoniesFallback = false;
      } else {
        ceremonies = CeremonyCatalogue.ceremonies;
        usedCeremoniesFallback = true;
      }
    } catch (_) {
      ceremonies = CeremonyCatalogue.ceremonies;
      usedCeremoniesFallback = true;
    } finally {
      loadingCeremonies = false;
      _ceremoniesLoaded = true;
      notifyListeners();
    }
  }

  List<String> get ceremonyCategories =>
      CeremonyCatalogue.categoriesOf(ceremonies);

  List<Ceremony> get popularCeremonies =>
      ceremonies.where((c) => c.popular).toList();

  void startForCeremony(Ceremony ceremony) {
    draft.ceremonyId = ceremony.id;
    draft.ceremonyName = ceremony.name;
    draft.ceremonyPrice = ceremony.price;
    draft.ceremonyOriginalPrice = ceremony.hasOfferPrice
        ? ceremony.originalPrice
        : 0;
    currentStep = 2;
    notifyListeners();
  }

  void resetDraft({
    String? devoteeName,
    String? mobile,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? gothram,
    String? nakshatra,
    String? rashi,
  }) {
    draft = BookingDraft();
    final tomorrow = DateTime.now().add(const Duration(days: 2));
    draft.date = tomorrow.toIso8601String().split('T').first;
    if (devoteeName != null) draft.devoteeName = devoteeName;
    if (mobile != null) draft.mobile = mobile;
    if (email != null) draft.email = email;
    if (address != null) draft.address = address;
    if (city != null) draft.cityText = city;
    if (state != null) draft.stateText = state;
    if (pincode != null) draft.pincode = pincode;
    // Pre-fill ritual details from the saved devotee profile so the
    // Devotee step is never blank (web parity: profile gotra/nakshatra seed
    // the booking form).
    if (gothram != null && gothram.isNotEmpty) draft.gothram = gothram;
    if (nakshatra != null && nakshatra.isNotEmpty) draft.nakshatra = nakshatra;
    if (rashi != null && rashi.isNotEmpty) draft.rashi = rashi;
    currentStep = 1;
    notifyListeners();
  }

  void setStep(int step) {
    currentStep = step.clamp(1, 4);
    notifyListeners();
  }

  void updateDraft(void Function(BookingDraft d) mutate) {
    mutate(draft);
    notifyListeners();
  }

  void selectCeremony(Ceremony ceremony) {
    draft.ceremonyId = ceremony.id;
    draft.ceremonyName = ceremony.name;
    draft.ceremonyPrice = ceremony.price;
    draft.ceremonyOriginalPrice = ceremony.hasOfferPrice
        ? ceremony.originalPrice
        : 0;
    notifyListeners();
  }

  void selectSamagri(SamagriPackage pkg) {
    draft.samagriPackageId = pkg.id;
    // Web parity: picking a package discards any customized cart
    // (`selectSamagri` in BookingContext resets `samagriCustomized`).
    draft.samagriCustomized = false;
    draft.customSamagriItems = const [];
    notifyListeners();
  }

  /// Commit an edited Eco-Samagri cart from the kit editor — web parity with
  /// `updateSamagriKit`: `samagri_items`, `ecokit_price` and the price
  /// breakdown all derive from the customized items via the draft getters.
  void applyCustomSamagriKit({
    required String packageId,
    required List<SamagriItem> items,
  }) {
    draft.samagriPackageId = packageId;
    draft.customSamagriItems = List<SamagriItem>.unmodifiable(items);
    draft.samagriCustomized = true;
    notifyListeners();
  }

  Map<String, dynamic> buildPayload() {
    final cityCore = draft.city.split('(').first.trim();
    final stateCore = _stateForCity(cityCore);
    return {
      'ceremony': draft.ceremonyName,
      'price': '₹${draft.breakdown.totalFormatted.replaceAll('₹', '')}',
      'ecokit_price': draft.samagriPrice,
      'samagri': _samagriLabel(),
      'ecokit': _ecokitSummary(),
      'samagri_items': _samagriItemsPayload(),
      'date': draft.date,
      'time_slot': draft.timeSlot,
      'language': draft.language,
      'city': draft.cityText.isNotEmpty ? draft.cityText : cityCore,
      'state': draft.stateText.isNotEmpty ? draft.stateText : stateCore,
      'full_name': draft.devoteeName,
      'email': draft.email,
      'mobile': draft.mobile,
      'address_line1': draft.address,
      'address': draft.address,
      'pincode': draft.pincode,
      'gothram': draft.gothram,
      'nakshatra': draft.nakshatra,
      'rashi': draft.rashi,
      'special_requests': draft.specialRequests,
      'samagri_notes': draft.samagriNotes,
      'latitude': draft.latitude,
      'longitude': draft.longitude,
    };
  }

  String _samagriLabel() {
    final items = draft.samagriKitItems;
    switch (draft.samagriPackageId) {
      case 'premium':
        return items.isEmpty
            ? 'Premium Sealed Samagri Kit'
            : 'Premium Sealed Samagri Kit (${items.length} Items)';
      case 'standard':
        return items.isEmpty
            ? 'Standard Vedic Samagri Kit'
            : 'Standard Vedic Kit (${items.length} Items)';
      default:
        return 'Devotee Brings Own Items';
    }
  }

  String _ecokitSummary() {
    if (draft.samagriPackageId == 'none') {
      return 'Self-Arranged by Devotee (No Kit)';
    }
    final items = draft.samagriKitItems;
    if (items.isEmpty) {
      final pkg = CeremonyCatalogue.samagriPackages.firstWhere(
        (p) => p.id == draft.samagriPackageId,
        orElse: () => CeremonyCatalogue.samagriPackages.first,
      );
      return '${pkg.name} (\u20B9${pkg.price.toInt()})';
    }
    return items
        .map(
          (i) =>
              '${i.name} (₹${i.price.toInt()} × ${i.qty} = ₹${i.lineTotal.toInt()})',
        )
        .join(', ');
  }

  List<Map<String, dynamic>> _samagriItemsPayload() =>
      draft.samagriKitItems.map((i) => i.toJson()).toList();

  String _stateForCity(String city) {
    final c = city.toLowerCase();
    if (c.contains('hyderabad')) return 'Telangana';
    if (c.contains('delhi') || c.contains('noida') || c.contains('gurugram')) {
      return 'Delhi';
    }
    if (c.contains('bengaluru')) return 'Karnataka';
    if (c.contains('mumbai') || c.contains('pune')) return 'Maharashtra';
    if (c.contains('chennai')) return 'Tamil Nadu';
    if (c.contains('varanasi') || c.contains('lucknow')) return 'Uttar Pradesh';
    if (c.contains('kolkata') || c.contains('howrah')) return 'West Bengal';
    if (c.contains('ahmedabad') || c.contains('surat')) return 'Gujarat';
    return 'Telangana';
  }

  Future<CreateBookingResult> submitBooking() async {
    final result = await _service.createBooking(buildPayload());
    if (result.success) {
      await loadMyBookings();
    }
    return result;
  }

  Future<void> loadMyBookings() async {
    loadingBookings = true;
    notifyListeners();
    myBookings = await _service.getMyBookings();
    loadingBookings = false;
    notifyListeners();
  }

  Booking? bookingById(int? id) {
    if (id == null) return null;
    for (final b in myBookings) {
      if (b.bookingId == id) return b;
    }
    return null;
  }

  Booking? get nextUpcoming {
    final upcoming =
        myBookings.where((b) {
          if (b.isCompleted || b.isCancelled) return false;
          final d = DateTime.tryParse(b.bookingDate ?? '');
          if (d == null) return true;
          final endOfDay = DateTime(d.year, d.month, d.day, 23, 59);
          return endOfDay.isAfter(DateTime.now());
        }).toList()..sort(
          (a, b) => (a.bookingDate ?? '').compareTo(b.bookingDate ?? ''),
        );
    return upcoming.isEmpty ? null : upcoming.first;
  }

  List<Booking> filtered(String filter) {
    switch (filter) {
      case 'Active':
      case 'Upcoming':
        return myBookings
            .where((b) => !b.isCompleted && !b.isCancelled)
            .toList();
      case 'Completed':
        return myBookings.where((b) => b.isCompleted).toList();
      case 'Cancelled':
        return myBookings.where((b) => b.isCancelled).toList();
      default:
        return myBookings;
    }
  }

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => loadMyBookings(),
    );
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
