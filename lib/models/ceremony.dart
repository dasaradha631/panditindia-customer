import 'package:intl/intl.dart';

class Ceremony {
  const Ceremony({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.duration,
    required this.description,
    required this.image,
    required this.panditType,
    required this.popular,
    this.originalPrice = 0,
    this.discountPct = 0,
    this.offerActive = false,
    this.badgeLabel,
    this.longDescription,
    this.offerTitle,
    this.offerDescription,
    this.offerValidTill,
    this.apiCategoryId,
  });

  /// Parses a row of the production `GET /pujas` catalogue. Mirrors the web
  /// puja mapper (`name: a.title`, `price: current_price ?? discount_price ??
  /// original_price`, `offerActive: !!offer_active`).
  factory Ceremony.fromJson(Map<String, dynamic> json) {
    final original = _num(json['original_price']).toDouble();
    final current = _num(
      json['current_price'] ?? json['discount_price'] ?? json['original_price'],
    ).toDouble();
    final min = _num(json['duration_min']).toInt();
    final max = _num(json['duration_max']).toInt();
    final offerActive = json['offer_active'] == true;
    final badge = json['badge_label']?.toString();
    return Ceremony(
      id: '${json['id']}',
      name: '${json['title'] ?? ''}',
      category: '${json['category'] ?? 'Ceremonies'}',
      price: current,
      duration: min == max
          ? '$min Hours'
          : '$min - $max Hours',
      description: '${json['description'] ?? ''}',
      image: '${json['image_url'] ?? ''}',
      panditType: 'Verified Vedic Acharya',
      popular:
          offerActive ||
          (badge != null &&
              (badge.contains('Popular') || badge.contains('Most Booked'))),
      originalPrice: original,
      discountPct: _num(json['discount_pct']).toInt(),
      offerActive: offerActive,
      badgeLabel: badge,
      longDescription: json['long_description']?.toString(),
      offerTitle: json['offer_title']?.toString(),
      offerDescription: json['offer_description']?.toString(),
      offerValidTill: json['offer_valid_till']?.toString(),
      apiCategoryId: _num(json['api_category_id']).toInt(),
    );
  }

  final String id;
  final String name;
  final String category;
  final double price;
  final String duration;
  final String description;
  final String image;
  final String panditType;
  final bool popular;

  /// Pre-discount list price (0 when the API carries no offer row).
  final double originalPrice;
  final int discountPct;
  final bool offerActive;
  final String? badgeLabel;
  final String? longDescription;
  final String? offerTitle;
  final String? offerDescription;
  final String? offerValidTill;
  final int? apiCategoryId;

  /// Strikethrough original price is only shown when a live offer discounts
  /// the current price below it (same guard as the web puja card).
  bool get hasOfferPrice =>
      offerActive && originalPrice > price && originalPrice > 0;

  /// Rupee amount a devotee saves with the live offer.
  double get savings => hasOfferPrice ? originalPrice - price : 0;

  /// Indian digit grouping (`₹3,098`) — matches the web puja mapper's
  /// currency formatter and `Fmt.inr` used across the app.
  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  String get priceFormatted => _inr.format(price);
  String get originalPriceFormatted => _inr.format(originalPrice);

  static num _num(Object? value) {
    if (value is num) return value;
    return num.tryParse('${value ?? ''}') ?? 0;
  }
}

class SamagriPackage {
  const SamagriPackage({
    required this.id,
    required this.name,
    required this.price,
    required this.badge,
    required this.description,
  });

  final String id;
  final String name;
  final double price;
  final String badge;
  final String description;

  String get priceFormatted => '₹${price.toInt()}';
}

class MuhuratSlot {
  const MuhuratSlot({
    required this.id,
    required this.name,
    required this.type,
    required this.desc,
  });

  final String id;
  final String name;
  final String type;
  final String desc;
}

const kLanguages = [
  'Hindi & Sanskrit',
  'Telugu & Sanskrit',
  'Tamil & Sanskrit',
  'Kannada & Sanskrit',
  'Marathi & Sanskrit',
  'Bengali & Sanskrit',
  'Gujarati & Sanskrit',
  'English & Sanskrit',
];

/// Booking city selector — the exact `CITIES` list of the web step 2
/// (`StepMuhurat.jsx`), including the full Hyderabad locality cluster and
/// the Andhra Pradesh town roster so both platforms offer identical options.
const kCities = [
  'Hyderabad (Madhapur, Gachibowli, Banjara Hills,Uppal,Kukatpally,Begumpet,Hi-Tech City, Shamshabad,Alwal,LB Nagar,Miyapur,Attapur,Manikonda, Kondapur,Kondapur,kukatpally,Kothapet,sainikpuri,kalyanipuri,shaikpet,tarnaka,pariseema colony, Yapral,Balanagar,Dilsukhnagar)',
  'Andhra Pradesh (Vijayawada, Visakhapatnam, Guntur, Kakinada, Rajahmundry, Nellore, Tirupati, Kurnool, Eluru, Anantapur, Kadapa, Ongole, Machilipatnam, Srikakulam, Chittoor, Nandyal, Proddatur, Hindupur, Adoni, Gudivada, Tenali, Bhimavaram, Amalapuram, Narasaraopet, Vizianagaram, Bapatla, Puttur, Srikalahasti, Tadepalligudem, Narsipatnam, Palakollu, Mandapeta, Pithapuram, Rajampet, Kavali, Chodavaram, Jaggayyapeta, Kandukur, Macherla, Ponnur, Repalle, Sullurpeta, Tadpatri, Yemmiganur, Atmakur, Bhimavaram, Chintalapudi, Giddalur, Gudur, Kothagudem, Mangalagiri, Nuzvid, Piduguralla, Srikakulam, Tuni)',
  'Delhi-NCR (Delhi, Noida, Gurugram, Faridabad)',
  'Bengaluru (Whitefield, Koramangala, Indiranagar, HSR)',
  'Mumbai & Pune (Bandra, Andheri, Kothrud, Hinjewadi)',
  'Chennai (Adyar, T. Nagar, Velachery)',
  'Varanasi & Lucknow',
  'Kolkata & Howrah',
  'Ahmedabad & Surat',
];

const kGotras = [
  'Kashyapa',
  'Bharadwaja',
  'Vashishta',
  'Vishwamitra',
  'Gautama',
  'Jamadagni',
  'Atri',
  'Agastya',
  'Shandilya',
  'Kaundinya',
  'Harita',
  'Srivatsa',
  'Other / Unknown (Acharya will assign Shiva Gotra)',
];

const kNakshatras = [
  'Ashwini',
  'Bharani',
  'Krittika',
  'Rohini',
  'Mrigashirsha',
  'Ardra',
  'Punarvasu',
  'Pushya',
  'Ashlesha',
  'Magha',
  'Purva Phalguni',
  'Uttara Phalguni',
  'Hasta',
  'Chitra',
  'Swati',
  'Vishakha',
  'Anuradha',
  'Jyeshtha',
  'Mula',
  'Purva Ashadha',
  'Uttara Ashadha',
  'Shravana',
  'Dhanishta',
  'Shatabhisha',
  'Purva Bhadrapada',
  'Uttra Bhadrapada',
  'Revati',
];

const kRashis = [
  'Mesha (Aries)',
  'Vrishabha (Taurus)',
  'Mithuna (Gemini)',
  'Karka (Cancer)',
  'Simha (Leo)',
  'Kanya (Virgo)',
  'Tula (Libra)',
  'Vrishchika (Scorpio)',
  'Dhanu (Sagittarius)',
  'Makara (Capricorn)',
  'Kumbha (Aquarius)',
  'Meena (Pisces)',
];
