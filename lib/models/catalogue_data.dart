import '../core/theme/app_theme.dart';
import 'ceremony.dart';
import 'ceremony_samagri_data.dart';

class CeremonyCatalogue {
  CeremonyCatalogue._();

  static const List<Ceremony> ceremonies = [
    Ceremony(
      id: 'grihapravesh',
      name: 'Griha Pravesh & Vastu Shanti',
      category: 'Housewarming & Vastu',
      price: 3100,
      duration: '2.5 - 3 Hours',
      description: 'Auspicious Vedic housewarming ceremony to sanctify new residence with Vastu Purusha invocation, Navagraha and peace mantras.',
      image: '/assets/images/griha-pravesh-natural.webp',
      panditType: 'Senior Vedic Acharya',
      popular: true,
    ),
    Ceremony(
      id: 'satyanarayana',
      name: 'Sri Satyanarayana Swamy Vratam',
      category: 'Wealth & Prosperity',
      price: 2200,
      duration: '2 Hours',
      description: 'Sacred ritual dedicated to Lord Vishnu for family prosperity, happiness, and fulfillment of all desires with Katha recitation.',
      image: '/assets/images/satyanarayana-spotlight.webp',
      panditType: 'Certified Gurukul Scholar',
      popular: true,
    ),
    Ceremony(
      id: 'rudrabhishekam',
      name: 'Maha Rudrabhishekam (Ekadasa)',
      category: 'Health & Protection',
      price: 2600,
      duration: '2.5 Hours',
      description: 'Sacred Shiva Abhishekam reciting Sri Rudram with 11 holy substances and Bilva leaves for health, peace, and divine energy.',
      image: '/assets/images/rudrabhishekam.webp',
      panditType: 'Yajurvedic Scholar',
      popular: true,
    ),
    Ceremony(
      id: 'ganapathi',
      name: 'Maha Ganapathi Homam',
      category: 'New Beginnings',
      price: 1900,
      duration: '2 Hours',
      description: 'Powerful fire ritual to remove all obstacles, grant wisdom, and bring success to new business ventures and milestones.',
      image: '/assets/images/ganapathi-homam.webp',
      panditType: 'Vedic Priest',
      popular: true,
    ),
    Ceremony(
      id: 'lakshmi-kubera',
      name: 'Sri Maha Lakshmi & Kubera Homam',
      category: 'Wealth & Prosperity',
      price: 2200,
      duration: '2 Hours',
      description: 'Auspicious Vedic fire ceremony for financial abundance, business growth, and removal of financial obstacles.',
      image: '/assets/images/lakshmi-kubera-homam.webp',
      panditType: 'Vedic Scholar',
      popular: true,
    ),
    Ceremony(
      id: 'mrityunjaya',
      name: 'Maha Mrityunjaya Homam',
      category: 'Health & Protection',
      price: 2600,
      duration: '2.5 Hours',
      description: 'Sacred life-protecting Shiva homam invoking the Tryambakam mantra for healing, vitality, and recovery from illnesses.',
      image: '/assets/images/mrityunjaya-homam.webp',
      panditType: 'Senior Vedic Acharya',
      popular: true,
    ),
    Ceremony(
      id: 'navagraha',
      name: 'Navagraha Shanti Homam',
      category: 'Shanti & Dosha Nivarana',
      price: 2200,
      duration: '2 Hours',
      description: 'Pacification ritual for all 9 cosmic planetary deities to alleviate doshas, planetary afflictions, and bring harmony.',
      image: '/assets/images/navagraha-homam.webp',
      panditType: 'Astrological Vedic Priest',
      popular: true,
    ),
    Ceremony(
      id: 'sudarshana',
      name: 'Maha Sudarshana & Narasimha Homam',
      category: 'Health & Protection',
      price: 2600,
      duration: '2.5 Hours',
      description: 'Potent Vaishnavite fire ritual invoking Lord Sudarshana to remove drishti doshas, negative energy, and provide divine armor.',
      image: '/assets/images/sudarshana-homam.webp',
      panditType: 'Taittiriya Scholar',
      popular: false,
    ),
    Ceremony(
      id: 'ayush',
      name: 'Ayush Homam (Longevity Blessing)',
      category: 'Health & Protection',
      price: 1900,
      duration: '1.5 - 2 Hours',
      description: 'Vedic ceremony performed on birthdays and milestone years for children and elders to bestow good health and long life.',
      image: '/assets/images/ayush-homam.webp',
      panditType: 'Vedic Acharya',
      popular: false,
    ),
    Ceremony(
      id: 'namakaranam',
      name: 'Namakaranam & Annaprashana Samskara',
      category: 'Samskaras',
      price: 1500,
      duration: '1.5 Hours',
      description: 'Traditional baby naming and first sacred solid food feeding ritual accompanied by Vedic blessings and Nakshatra sankalp.',
      image: '/assets/images/namakaranam-puja.webp',
      panditType: 'Vedic Priest',
      popular: false,
    ),
    Ceremony(
      id: 'saraswati',
      name: 'Saraswati Puja & Aksharabhyasam',
      category: 'New Beginnings',
      price: 1400,
      duration: '1.5 Hours',
      description: 'Sacred learning initiation for children and students to invoke Goddess Saraswati for wisdom, memory, and academic success.',
      image: '/assets/images/saraswati-puja.webp',
      panditType: 'Vedic Scholar',
      popular: false,
    ),
    Ceremony(
      id: 'bhoomi-puja',
      name: 'Bhoomi Puja & Foundation Blessing',
      category: 'Housewarming & Vastu',
      price: 2600,
      duration: '2 Hours',
      description: 'Traditional Vedic ground-breaking ceremony for new plot, building construction, or commercial site sanctification.',
      image: '/assets/images/corporate-bhoomi-puja.webp',
      panditType: 'Vastu Scholar',
      popular: false,
    ),
    Ceremony(
      id: 'vahana-puja',
      name: 'Vahana Puja (New Vehicle Blessing)',
      category: 'New Beginnings',
      price: 701,
      duration: '45 mins',
      description: 'Consecration of new car, two-wheeler, or transport with coconut breaking, lemon drishti, and Lord Ganesha raksha mantras.',
      image: '/assets/images/vahana-puja.webp',
      panditType: 'Vedic Priest',
      popular: false,
    ),
    Ceremony(
      id: 'chandi',
      name: 'Navachandi Mahayajnam (Sri Chandi Homam)',
      category: 'Protection & Victory',
      price: 12100,
      duration: '4 - 5 Hours',
      description: 'Grand Durga Saptashati parayana and sacred fire oblation by certified Acharyas for supreme victory, health, and protection.',
      image: '/assets/images/chandi-homam.webp',
      panditType: '2-3 Senior Acharyas',
      popular: false,
    ),
    Ceremony(
      id: 'wedding',
      name: 'Vedic Vivah Samskara (Complete Wedding)',
      category: 'Samskaras',
      price: 18000,
      duration: 'Full Day / Custom',
      description: 'Traditional Vedic wedding rituals including Kanyadaan, Mangalsutra dharana, Saptapadi, and Laja Homam by scholar Acharyas.',
      image: '/assets/images/vedic-wedding1.webp',
      panditType: 'Master Acharyas Team',
      popular: false,
    ),
    Ceremony(
      id: 'vinayaka-chavithi',
      name: 'Sri Vinayaka Chavithi (Ganesh Chaturthi Vratam)',
      category: 'Festivals & Vratams',
      price: 1800,
      duration: '2 Hours',
      description: 'Grand Ganesha Chaturthi Vratam with 21 Sacred Patri (herbal leaves) Puja, Modak Naivedyam, Ashtottara archana, and Mangala Aarti.',
      image: '/assets/images/vinayaka-chavithi.webp',
      panditType: 'Certified Gurukul Purohit',
      popular: true,
    ),
    Ceremony(
      id: 'varalakshmi-vratam',
      name: 'Sri Varalakshmi Vratam',
      category: 'Festivals & Vratams',
      price: 2100,
      duration: '2.5 Hours',
      description: 'Auspicious Friday vrata performed by women for family health and prosperity with Kalash sthapana, 9-knot yellow Toram, and Lakshmi Sahasranama.',
      image: '/assets/images/varalakshmi-vratam.webp',
      panditType: 'Vedic Scholar',
      popular: true,
    ),
    Ceremony(
      id: 'deepavali-lakshmi',
      name: 'Deepavali Maha Lakshmi & Kubera Puja',
      category: 'Festivals & Vratams',
      price: 2500,
      duration: '2 Hours',
      description: 'Sacred Diwali evening Lakshmi, Ganesha, and Saraswati Puja with Chopda Pujan, Kuber Yantra consecration, and 108 Deepam lighting.',
      image: '/assets/images/deepavali-lakshmi-puja.webp',
      panditType: 'Senior Vedic Acharya',
      popular: true,
    ),
    Ceremony(
      id: 'sundarakanda-hanuman',
      name: 'Sundarakanda Parayana & Hanuman Puja',
      category: 'Health & Protection',
      price: 2400,
      duration: '3 Hours',
      description: 'Valmiki Ramayana Sundarakanda recitation and Lord Hanuman Sindoor archana with 108 Betel leaf garland for courage and obstacle removal.',
      image: '/assets/images/sundarakanda-hanuman.webp',
      panditType: 'Ramayana Vedic Scholar',
      popular: false,
    ),
    Ceremony(
      id: 'subrahmanya-sashti',
      name: 'Sri Subrahmanya / Skanda Sashti Homam',
      category: 'Shanti & Dosha Nivarana',
      price: 2600,
      duration: '2.5 Hours',
      description: 'Powerful fire ritual invoking Lord Muruga with Sarpa Suktam and Kuja Dosha Shanti for fertility, marriage obstacles, and vitality.',
      image: '/assets/images/subrahmanya-sashti.webp',
      panditType: 'Vedic Priest',
      popular: false,
    ),
    Ceremony(
      id: 'pitru-shradh',
      name: 'Pinda Daan & Pitru Tarpana Ritual',
      category: 'Ancestral Rituals',
      price: 1800,
      duration: '2 Hours',
      description: 'Sacred ancestral peace ceremony ensuring blessings and spiritual liberation of forebearers.',
      image: '/assets/images/pitru-tarpana.webp',
      panditType: 'Vedic Priest',
      popular: false,
    ),
  ];

  static const List<SamagriPackage> samagriPackages = [
    SamagriPackage(
      id: 'premium',
      name: 'Premium Sealed Eco-Samagri Kit',
      price: 800,
      badge: 'Recommended',
      description: '100% pure organic A2 cow ghee, cold-pressed oils, certified Himalayan herbs, dry coconut halves, hawan sticks & brass items.',
    ),
    SamagriPackage(
      id: 'standard',
      name: 'Standard Vedic Samagri Kit',
      price: 500,
      badge: 'Standard',
      description: 'Standard ceremonial herbs, pure camphor, flowers list, kumkum, raw turmeric and basic homam samidha sticks.',
    ),
    SamagriPackage(
      id: 'none',
      name: 'Devotee Will Arrange Own Items',
      price: 0,
      badge: 'Self Arrange',
      description: 'Acharya will provide a complete verified checklist of ritual items for you to purchase locally before the ceremony.',
    ),
  ];

  static const List<MuhuratSlot> timeSlots = [
    MuhuratSlot(
      id: 'brahma',
      name: 'Brahma Muhurat (05:30 AM - 08:00 AM)',
      type: 'Highest Spiritual Energy',
      desc: 'Ideal for Rudrabhishekam, Ganapathi Homam & Deep Meditation.',
    ),
    MuhuratSlot(
      id: 'abhijit',
      name: 'Morning Abhijit Muhurat (08:00 AM - 11:30 AM)',
      type: 'Most Auspicious For All Rituals',
      desc: 'Optimal for Griha Pravesh, Satyanarayana Puja, and Vivah.',
    ),
    MuhuratSlot(
      id: 'afternoon',
      name: 'Afternoon Vijaya Muhurat (12:00 PM - 03:00 PM)',
      type: 'Victory & Success',
      desc: 'Recommended for Business Inception, Bhoomi Puja, and Shanti.',
    ),
    MuhuratSlot(
      id: 'evening',
      name: 'Evening Pradosha Kaal (05:30 PM - 08:30 PM)',
      type: 'Devotional Bliss',
      desc: 'Auspicious for Shiva Puja, Lakshmi Vratam, and Evening Havans.',
    ),
  ];

  static Ceremony? byId(String? id) {
    for (final c in ceremonies) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Flat (ceremony agnostic) package price — the pre-parity fallback.
  static double flatSamagriPrice(String packageId) {
    for (final p in samagriPackages) {
      if (p.id == packageId) return p.price;
    }
    return samagriPackages.first.price;
  }

  /// Ceremony specific kit items for the package (empty for `none` and for
  /// ceremonies without an explicit mapping — callers fall back to flat
  /// prices via [samagriKitPrice]). [ceremonyName] lets API-loaded ceremonies
  /// (numeric ids) resolve their kit by title, like the web flow.
  static List<SamagriItem> samagriKitItems({
    required String? ceremonyId,
    required String packageId,
    String? ceremonyName,
  }) {
    if (packageId == 'none') return const [];
    if (!CeremonySamagriData.hasCeremonyMapping(
      ceremonyId,
      ceremonyName: ceremonyName,
    )) {
      return const [];
    }
    return CeremonySamagriData.getCeremonyKitItems(
      ceremonyId,
      packageId,
      ceremonyName,
    );
  }

  /// Price charged for the kit on this ceremony — mirrors the web
  /// `calculateKitTotal(getCeremonyKitItems(ceremonyId, tier))`, falling back
  /// to the flat ₹800/₹500 package prices when no mapping exists.
  static double samagriKitPrice({
    required String? ceremonyId,
    required String packageId,
    String? ceremonyName,
  }) {
    if (packageId == 'none') return 0;
    if (!CeremonySamagriData.hasCeremonyMapping(
      ceremonyId,
      ceremonyName: ceremonyName,
    )) {
      return flatSamagriPrice(packageId);
    }
    return CeremonySamagriData.calculateKitTotal(
      CeremonySamagriData.getCeremonyKitItems(
        ceremonyId,
        packageId,
        ceremonyName,
      ),
    );
  }

  /// Categories present in the baked-in fallback catalogue.
  static List<String> get categories => categoriesOf(ceremonies);

  /// Distinct categories of [list], in first-seen order. Used for the API
  /// loaded catalogue where categories come from `GET /pujas`.
  static List<String> categoriesOf(List<Ceremony> list) {
    final seen = <String>{};
    final result = <String>[];
    for (final c in list) {
      if (seen.add(c.category)) result.add(c.category);
    }
    return result;
  }
}

double calculateTravelAllowance(num distanceKm) {
  final d = distanceKm.toDouble().clamp(0, double.infinity);
  if (d <= 8) return 0;
  if (d <= 20) return 150;
  if (d <= 40) return 300;
  return 300 + ((d - 40) * 10).roundToDouble();
}

class PriceBreakdown {
  PriceBreakdown({
    required this.ceremonyPrice,
    required this.panditTierPrice,
    required this.travelPrice,
    required this.samagriPrice,
    required this.dakshinaTrustFee,
    required this.distanceKm,
  });

  final double ceremonyPrice;
  final double panditTierPrice;
  final double travelPrice;
  final double samagriPrice;
  final double dakshinaTrustFee;
  final double distanceKm;

  double get total =>
      ceremonyPrice +
      panditTierPrice +
      travelPrice +
      samagriPrice +
      dakshinaTrustFee;

  String get totalFormatted => Fmt.inr(total);
}
