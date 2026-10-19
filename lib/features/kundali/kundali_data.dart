/// Ceremony, location and geography data for the Muhurtham engine.
///
/// Mirrors `CEREMONY_CATALOGUE` / `POPULAR_LOCATIONS` from the web app
/// (`frontend/src/utils/vedicAstrology.js`, `PersonalizedKundliMuhurthamSection.jsx`),
/// with `catalogueId` pointing at the nearest entry of the mobile app's own
/// `CeremonyCatalogue` so a muhurtham result can seed the booking flow.
class MuhurthamCeremony {
  const MuhurthamCeremony({
    required this.name,
    required this.fullTitle,
    required this.catalogueId,
    required this.price,
  });

  final String name;
  final String fullTitle;

  /// Nearest `CeremonyCatalogue` id used to preselect step 2 of booking.
  final String catalogueId;

  /// Listing price in rupees (web shows `₹5,100` etc.).
  final double price;
}

const List<MuhurthamCeremony> kMuhurthamCeremonies = [
  MuhurthamCeremony(
    name: 'Griha Pravesh',
    fullTitle: 'Griha Pravesh & Vastu Shanti',
    catalogueId: 'grihapravesh',
    price: 5100,
  ),
  MuhurthamCeremony(
    name: 'Marriage',
    fullTitle: 'Vedic Vivah Samskara',
    catalogueId: 'wedding',
    price: 21000,
  ),
  MuhurthamCeremony(
    name: 'Engagement',
    fullTitle: 'Nischitartham (Engagement Ceremony)',
    catalogueId: 'wedding',
    price: 4500,
  ),
  MuhurthamCeremony(
    name: 'Upanayanam',
    fullTitle: 'Upanayanam (Sacred Thread Ceremony)',
    catalogueId: 'grihapravesh',
    price: 9500,
  ),
  MuhurthamCeremony(
    name: 'Namakaranam',
    fullTitle: 'Namakaranam (Baby Naming Ceremony)',
    catalogueId: 'namakaranam',
    price: 3100,
  ),
  MuhurthamCeremony(
    name: 'Annaprashana',
    fullTitle: 'Annaprashana (First Solid Food)',
    catalogueId: 'namakaranam',
    price: 3100,
  ),
  MuhurthamCeremony(
    name: 'Satyanarayana Pooja',
    fullTitle: 'Sri Satyanarayana Vratham',
    catalogueId: 'satyanarayana',
    price: 3500,
  ),
  MuhurthamCeremony(
    name: 'Ganapathi Pooja',
    fullTitle: 'Maha Ganapathi Homam',
    catalogueId: 'ganapathi',
    price: 3100,
  ),
  MuhurthamCeremony(
    name: 'Lakshmi Pooja',
    fullTitle: 'Sri Maha Lakshmi Pooja',
    catalogueId: 'lakshmi-kubera',
    price: 3800,
  ),
  MuhurthamCeremony(
    name: 'Durga Pooja',
    fullTitle: 'Maha Chandi & Durga Parayanam',
    catalogueId: 'chandi',
    price: 4500,
  ),
  MuhurthamCeremony(
    name: 'Navagraha Pooja',
    fullTitle: 'Navagraha Shanti Homam',
    catalogueId: 'navagraha',
    price: 3900,
  ),
  MuhurthamCeremony(
    name: 'Ayushya Homam',
    fullTitle: 'Ayushya & Mrityunjaya Homam',
    catalogueId: 'ayush',
    price: 4200,
  ),
  MuhurthamCeremony(
    name: 'Rudrabhishekam',
    fullTitle: 'Maha Rudrabhishekam',
    catalogueId: 'rudrabhishekam',
    price: 4200,
  ),
  MuhurthamCeremony(
    name: 'Gruha Shanti',
    fullTitle: 'Gruha Shanti & Ganapathi Homam',
    catalogueId: 'grihapravesh',
    price: 4500,
  ),
  MuhurthamCeremony(
    name: 'Vastu Shanti',
    fullTitle: 'Vastu Shanti & Dikpalaka Homam',
    catalogueId: 'grihapravesh',
    price: 5100,
  ),
  MuhurthamCeremony(
    name: 'Business / Shop Opening',
    fullTitle: 'Vyapar Aarambh & Kubera Pooja',
    catalogueId: 'grihapravesh',
    price: 4500,
  ),
  MuhurthamCeremony(
    name: 'Vehicle Purchase / Pooja',
    fullTitle: 'Vahana Pooja & Shanti',
    catalogueId: 'vahana-puja',
    price: 2100,
  ),
  MuhurthamCeremony(
    name: 'Property Registration',
    fullTitle: 'Bhoomi & Property Registration',
    catalogueId: 'bhoomi-puja',
    price: 3500,
  ),
  MuhurthamCeremony(
    name: 'Other',
    fullTitle: 'Custom Sacred Ceremony',
    catalogueId: 'grihapravesh',
    price: 3500,
  ),
];

/// Ceremony locations offered in the dropdown (web `POPULAR_LOCATIONS`).
const List<String> kPopularLocations = [
  'Hyderabad, Telangana',
  'Vijayawada, Andhra Pradesh',
  'Visakhapatnam, Andhra Pradesh',
  'Tirumala, Andhra Pradesh',
  'Tirupati, Andhra Pradesh',
  'Bengaluru, Karnataka',
  'Chennai, Tamil Nadu',
  'Mumbai, Maharashtra',
  'Pune, Maharashtra',
  'Delhi NCR, Delhi',
  'Varanasi, Uttar Pradesh',
  'Kolkata, West Bengal',
  'Jaipur, Rajasthan',
  'Ahmedabad, Gujarat',
  'Kochi, Kerala',
];

/// States and union territories offered by the birth-details modal.
const List<String> kIndianStates = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
  'Andaman and Nicobar Islands',
  'Chandigarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi',
  'Jammu and Kashmir',
  'Ladakh',
  'Lakshadweep',
  'Puducherry',
];

/// Keyword mapping from a muhurtham ceremony name to the nearest
/// `CeremonyCatalogue` id (web `mapCeremonyNameToId`, retargeted at the
/// mobile catalogue).
String kCeremonyCatalogueIdFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('griha') || n.contains('vastu') || n.contains('house') || n.contains('shanti')) {
    return 'grihapravesh';
  }
  if (n.contains('satyanarayana') || n.contains('vratham')) return 'satyanarayana';
  if (n.contains('rudra') || n.contains('shiva') || n.contains('abhishekam')) {
    return 'rudrabhishekam';
  }
  if (n.contains('ganapathi') || n.contains('ganesh') || n.contains('homam')) {
    return 'ganapathi';
  }
  if (n.contains('lakshmi') || n.contains('wealth') || n.contains('kubera')) {
    return 'lakshmi-kubera';
  }
  if (n.contains('durga') || n.contains('chandi')) return 'chandi';
  if (n.contains('navagraha')) return 'navagraha';
  if (n.contains('ayushya') || n.contains('mrityunjaya')) return 'ayush';
  if (n.contains('vivaha') || n.contains('wedding') || n.contains('marriage')) {
    return 'wedding';
  }
  if (n.contains('namakaranam') || n.contains('naming') || n.contains('annaprashana')) {
    return 'namakaranam';
  }
  if (n.contains('vehicle') || n.contains('vahana') || n.contains('car')) {
    return 'vahana-puja';
  }
  if (n.contains('property') || n.contains('bhoomi') || n.contains('land')) {
    return 'bhoomi-puja';
  }
  return 'grihapravesh';
}

/// Splits a `"City, State"` location string for the booking draft.
({String city, String state}) kSplitLocation(String location) {
  final parts = location.split(',');
  final city = parts.first.trim();
  final state = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
  return (city: city, state: state);
}

/// Birth information the Muhurtham engine requires (web birth-modal state).
class KundaliBirthDetails {
  const KundaliBirthDetails({
    this.fullName,
    this.dateOfBirth,
    this.timeOfBirth,
    this.placeOfBirth,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.timezone,
  });

  final String? fullName;
  final String? dateOfBirth;
  final String? timeOfBirth;
  final String? placeOfBirth;
  final String? city;
  final String? state;
  final String? latitude;
  final String? longitude;
  final String? timezone;

  bool get isComplete =>
      (dateOfBirth?.isNotEmpty ?? false) &&
      (timeOfBirth?.isNotEmpty ?? false) &&
      (placeOfBirth?.isNotEmpty ?? false);

  factory KundaliBirthDetails.fromProfile(dynamic profile) => KundaliBirthDetails(
        fullName: profile?.fullName as String?,
        dateOfBirth: profile?.dateOfBirth as String?,
        timeOfBirth: profile?.timeOfBirth as String?,
        placeOfBirth: profile?.placeOfBirth as String?,
        city: profile?.city as String?,
        state: profile?.state as String?,
        latitude: profile?.latitude as String?,
        longitude: profile?.longitude as String?,
        timezone: profile?.timezone as String?,
      );
}
