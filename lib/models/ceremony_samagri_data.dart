// Ceremony-specific Eco-Samagri kits & samagri catalogue.
//
// 1:1 Dart port of the web reference file
// `frontend/src/data/ceremonySamagriData.js` (SAMAGRI_CATALOGUE,
// CEREMONY_SAMAGRI_MAPPING, getCeremonyKitItems, calculateKitTotal).
// Every id, name, quantity, category, price and icon is copied verbatim from
// the web source so mobile checkout totals match the web booking flow.
//
// Notes:
// * Mapping keys match the ceremony ids used by `CeremonyCatalogue`
//   (grihapravesh, satyanarayana, rudrabhishekam, ganapathi, ...).
// * Web mapping rows carry `qty: 1`; `SamagriItem.qty` defaults to 1 so the
//   ported totals are identical without repeating the field on every row.
// * The web mapping also has a generic `default` kit used as a lookup
//   fallback; `hasCeremonyMapping` deliberately reports `false` for it so
//   callers can fall back to the flat 800/500 package prices for any
//   ceremony that has no explicit kit of its own.

class SamagriItem {
  const SamagriItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.category,
    required this.price,
    required this.icon,
    this.qty = 1,
  });

  final String id;
  final String name;
  final String quantity;
  final String category;
  final double price;
  final String icon;
  final int qty;

  double get lineTotal => price * qty;

  SamagriItem copyWith({int? qty}) => SamagriItem(
    id: id,
    name: name,
    quantity: quantity,
    category: category,
    price: price,
    icon: icon,
    qty: qty ?? this.qty,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'price': price,
    'qty': qty,
  };
}

class CeremonySamagriKit {
  const CeremonySamagriKit({
    required this.ceremonyName,
    required this.standard,
    required this.premium,
  });

  final String ceremonyName;
  final List<SamagriItem> standard;
  final List<SamagriItem> premium;
}

class CeremonySamagriData {
  CeremonySamagriData._();

  static const String _fallbackKey = 'default';

  static const List<String> samagriCategories = [
    'all',
    'Liquids',
    'Dry Items',
    'Flowers',
    'Utensils',
    'Herbs',
    'Incense',
  ];

  // ─── SAMAGRI_CATALOGUE (88 items) ────────────────────────────────────────
  static const List<SamagriItem> catalogue = [
    // ─── Liquids ───
    SamagriItem(id: 'smg_ghee_a2', name: 'Pure Desi Cow Ghee (A2 Bilona Organic)', quantity: '500ml', category: 'Liquids', price: 320, icon: '🍯'),
    SamagriItem(id: 'smg_ghee_std', name: 'Pure Desi Cow Ghee for Deepam & Ahuti', quantity: '250ml', category: 'Liquids', price: 160, icon: '🍯'),
    SamagriItem(id: 'smg_gangajal_lota', name: 'Sealed Gangajal (Gangotri Origin Brass Lota)', quantity: '500ml', category: 'Liquids', price: 150, icon: '🏺'),
    SamagriItem(id: 'smg_raw_honey', name: 'Pure Raw Forest Honey (Shahad)', quantity: '250g', category: 'Liquids', price: 120, icon: '🍯'),
    SamagriItem(id: 'smg_sesame_oil', name: 'Gingelly Sesame Oil (Pure Til Tel for Shivalinga/Grahas)', quantity: '250ml', category: 'Liquids', price: 80, icon: '🫙'),
    SamagriItem(id: 'smg_mustard_oil', name: 'Cold-Pressed Mustard Oil (Sarson Tel for Shani/Drishti)', quantity: '250ml', category: 'Liquids', price: 70, icon: '🫙'),
    SamagriItem(id: 'smg_panchamrit_mix', name: 'Panchamrit Divine 5-Nectar Mix Set', quantity: '1 Set', category: 'Liquids', price: 180, icon: '🥛'),
    SamagriItem(id: 'smg_raw_milk', name: 'Organic Fresh Cow Raw Milk (Kaccha Doodh)', quantity: '500ml', category: 'Liquids', price: 60, icon: '🥛'),
    SamagriItem(id: 'smg_rose_water', name: 'Pure Gulab Jal (Distilled Rose Water Decanter)', quantity: '200ml', category: 'Liquids', price: 60, icon: '🌹'),
    SamagriItem(id: 'smg_sugandhi_ittar', name: 'Sugandhi Royal Natural Attar (Gulab & Sandal)', quantity: '10ml', category: 'Liquids', price: 90, icon: '✨'),
    SamagriItem(id: 'smg_gomutra_arka', name: 'Certified Desi Cow Gomutra Arka (Purification)', quantity: '200ml', category: 'Liquids', price: 75, icon: '🏺'),
    SamagriItem(id: 'smg_ekadasa_dravya', name: 'Ekadasa 11-Sacred Dravya Abhishekam Liquid Box', quantity: '1 Set', category: 'Liquids', price: 220, icon: '🥛'),

    // ─── Dry Items ───
    SamagriItem(id: 'smg_hawan_mix_108', name: '108 Sacred Herb Hawan Samagri Mix', quantity: '250g', category: 'Dry Items', price: 180, icon: '🌿'),
    SamagriItem(id: 'smg_hawan_mix_std', name: 'Vedic Hawan Samagri Mix (150g)', quantity: '150g', category: 'Dry Items', price: 110, icon: '🌿'),
    SamagriItem(id: 'smg_camphor_bhimseni', name: 'Bhimseni Pure Camphor (Kapoor) Tablets', quantity: '50g', category: 'Dry Items', price: 50, icon: '🕯️'),
    SamagriItem(id: 'smg_kumkum_roli', name: 'Pure Roli Kumkum Sindoor (Organic)', quantity: '50g', category: 'Dry Items', price: 30, icon: '🔴'),
    SamagriItem(id: 'smg_haldi_powder', name: 'Raw Vedic Turmeric Powder (Kasturi Haldi)', quantity: '100g', category: 'Dry Items', price: 40, icon: '💛'),
    SamagriItem(id: 'smg_chandan_powder', name: 'Mysore Sandalwood Powder (Pure Chandan)', quantity: '50g', category: 'Dry Items', price: 90, icon: '🪵'),
    SamagriItem(id: 'smg_akshat_rice', name: 'Consecrated Whole Sacred Rice (Akshat)', quantity: '250g', category: 'Dry Items', price: 45, icon: '🌾'),
    SamagriItem(id: 'smg_rice_9_colors', name: 'Navagraha 9-Planetary Colored Rice Mix', quantity: '500g', category: 'Dry Items', price: 120, icon: '🌾'),
    SamagriItem(id: 'smg_black_sesame', name: 'Black Sesame Seeds (Sacred Kala Til)', quantity: '200g', category: 'Dry Items', price: 50, icon: '⚫'),
    SamagriItem(id: 'smg_white_mustard', name: 'White Mustard Seeds (Sarshapa for Raksha)', quantity: '100g', category: 'Dry Items', price: 40, icon: '⚫'),
    SamagriItem(id: 'smg_navadhanya', name: 'Navadhanya (9 Planetary Sacred Grains Pack)', quantity: '250g', category: 'Dry Items', price: 80, icon: '🌾'),
    SamagriItem(id: 'smg_panchamewa', name: 'Panchamewa Dry Fruits Royal Offering Box', quantity: '200g', category: 'Dry Items', price: 150, icon: '🥜'),
    SamagriItem(id: 'smg_vastram_set', name: 'Sacred Red & Yellow Silk Peeta Vastram Cloth', quantity: '1 Set', category: 'Dry Items', price: 90, icon: '🧣'),
    SamagriItem(id: 'smg_navavastram_9', name: '9 Planetary Colored Silk Cloths (Navavastram Set)', quantity: '1 Set (9 Pcs)', category: 'Dry Items', price: 180, icon: '🧣'),
    SamagriItem(id: 'smg_mata_chunri', name: 'Red Silk Mata Chunri with Golden Zari & Sindoor', quantity: '1 Set', category: 'Dry Items', price: 100, icon: '🧣'),
    SamagriItem(id: 'smg_baby_vastram', name: 'Sacred Baby Silk Vastram & Sankalpa Blanket Pack', quantity: '1 Set', category: 'Dry Items', price: 160, icon: '🧣'),
    SamagriItem(id: 'smg_janeu_pack', name: 'Sacred Yagnopavita Janeu Thread (5 Pcs)', quantity: '5 Pcs', category: 'Dry Items', price: 50, icon: '🧵'),
    SamagriItem(id: 'smg_supari_nuts', name: 'Whole Sacred Puja Betel Nuts (Supari 21 Pcs)', quantity: '21 Pcs', category: 'Dry Items', price: 60, icon: '🌰'),
    SamagriItem(id: 'smg_elaichi_lavang', name: 'Green Cardamom (Elaichi) & Cloves (Laung)', quantity: '50g', category: 'Dry Items', price: 85, icon: '🌱'),
    SamagriItem(id: 'smg_moli_kalava', name: 'Kalava / Raksha Sutra Sacred Thread (2 Rolls)', quantity: '2 Rolls', category: 'Dry Items', price: 40, icon: '🧶'),
    SamagriItem(id: 'smg_vibhuti_bhasma', name: 'Sacred Maha Bhasma / Vibhuti Ash', quantity: '100g', category: 'Dry Items', price: 60, icon: '🪵'),
    SamagriItem(id: 'smg_jaggery_misri', name: 'Organic Jaggery (Gur) & Crystal Dhaga Misri', quantity: '250g', category: 'Dry Items', price: 60, icon: '🍯'),
    SamagriItem(id: 'smg_kamalgatta', name: 'Sacred Kamalgatta Lotus Seeds (108 Beads)', quantity: '1 Pack', category: 'Dry Items', price: 110, icon: '🪷'),
    SamagriItem(id: 'smg_gomti_kauri', name: 'Consecrated Gomti Chakra & Yellow Kauri Shells (11 Pcs)', quantity: '11 Pcs', category: 'Dry Items', price: 90, icon: '🐚'),
    SamagriItem(id: 'smg_laja_puffed_rice', name: 'Sacred Puffed Rice (Kheel / Laja for Havan)', quantity: '250g', category: 'Dry Items', price: 50, icon: '🌾'),
    SamagriItem(id: 'smg_dry_copra_halves', name: 'Whole Dry Copra Halves (Khopra Gola 2 Pcs)', quantity: '2 Pcs', category: 'Dry Items', price: 70, icon: '🥥'),
    SamagriItem(id: 'smg_katha_pothi', name: 'Satyanarayana Vrata Katha Pothi & Puja Vidhi Dravyam', quantity: '1 Set', category: 'Dry Items', price: 100, icon: '📜'),
    SamagriItem(id: 'smg_sapatha_mix', name: 'Sapatha Prasad Kit (Wheat Flour, Sooji, Jaggery, Elaichi)', quantity: '1 Box', category: 'Dry Items', price: 140, icon: '🌾'),
    SamagriItem(id: 'smg_saptapadi_mats', name: 'Sacred Saptapadi 7-Step Mats & Vivah Vastram Kit', quantity: '1 Set', category: 'Dry Items', price: 180, icon: '🧣'),
    SamagriItem(id: 'smg_wooden_slate', name: 'Saraswati Wooden Slate (Pattika), Sacred Chalk & Pen', quantity: '1 Set', category: 'Dry Items', price: 130, icon: '✏️'),
    SamagriItem(id: 'smg_swastik_stencil', name: 'Swastik Stencil, Sindoor & Vehicle Consecration Kit', quantity: '1 Set', category: 'Dry Items', price: 80, icon: '🔴'),

    // ─── Flowers & Botanicals ───
    SamagriItem(id: 'smg_marigold_garland', name: 'Fresh Yellow Marigold Garland (Genda Mala)', quantity: '1 Kg', category: 'Flowers', price: 150, icon: '🌼'),
    SamagriItem(id: 'smg_rose_petals', name: 'Fresh Fragrant Rose Petals (Gulab Pankhudi)', quantity: '500g', category: 'Flowers', price: 100, icon: '🌸'),
    SamagriItem(id: 'smg_lotus_pink', name: 'Sacred Pink Lotus Flowers (Kamal 5 Pcs)', quantity: '5 Pcs', category: 'Flowers', price: 180, icon: '🪷'),
    SamagriItem(id: 'smg_lotus_white', name: 'Sacred White Lotus Flowers (5 Pcs for Saraswati)', quantity: '5 Pcs', category: 'Flowers', price: 190, icon: '🪷'),
    SamagriItem(id: 'smg_tulsi_leaves', name: 'Fresh Organic Tulsi Leaves & Seed Manjari', quantity: '100g', category: 'Flowers', price: 50, icon: '🌱'),
    SamagriItem(id: 'smg_tulsi_garland', name: 'Fresh Tulsi Manjari Auspicious Garland', quantity: '1 Pc', category: 'Flowers', price: 110, icon: '🌱'),
    SamagriItem(id: 'smg_mango_toran', name: 'Fresh Mango Leaves & Peepal Toran Bundle', quantity: '1 Bundle', category: 'Flowers', price: 80, icon: '🍃'),
    SamagriItem(id: 'smg_durva_grass', name: 'Fresh Green Durva Grass (21 Sacred Garika Bundles)', quantity: '21 Bundles', category: 'Flowers', price: 60, icon: '🌿'),
    SamagriItem(id: 'smg_bilva_patra', name: 'Fresh Sacred Bilva (Bel Patra) Leaves (108 Pcs)', quantity: '108 Leaves', category: 'Flowers', price: 120, icon: '🍃'),
    SamagriItem(id: 'smg_betel_leaves', name: 'Fresh Green Betel Leaves (Paan Ke Patte 21 Pcs)', quantity: '21 Pcs', category: 'Flowers', price: 50, icon: '🍃'),
    SamagriItem(id: 'smg_dhatura_set', name: 'Sacred Dhatura Flower & Fruit for Shiva Abhishekam', quantity: '5 Pcs', category: 'Flowers', price: 70, icon: '🌱'),
    SamagriItem(id: 'smg_red_hibiscus', name: 'Fresh Red Hibiscus Flowers (Jaswand 21 Pcs)', quantity: '21 Pcs', category: 'Flowers', price: 80, icon: '🌺'),
    SamagriItem(id: 'smg_ritual_lemons', name: 'Consecrated Ritual Lemons (4 Pcs for Tyre Blessing)', quantity: '4 Pcs', category: 'Flowers', price: 70, icon: '🍋'),
    SamagriItem(id: 'smg_vehicle_ribbon', name: 'Red & Yellow Vehicle Bonnet Ribbon Garlands', quantity: '1 Set', category: 'Flowers', price: 90, icon: '🎗️'),

    // ─── Utensils & Vessels ───
    SamagriItem(id: 'smg_kalash_copper', name: 'Sacred Pure Copper Kalash with Swastik', quantity: '1 Pc', category: 'Utensils', price: 350, icon: '🏺'),
    SamagriItem(id: 'smg_coconut_sriphal', name: 'Consecrated Whole Coconut (Husk on Sriphal)', quantity: '1 Pc', category: 'Utensils', price: 50, icon: '🥥'),
    SamagriItem(id: 'smg_thali_set', name: 'Brass & Copper Puja Thali Set with Diya', quantity: '1 Set', category: 'Utensils', price: 450, icon: '🍽️'),
    SamagriItem(id: 'smg_clay_diyas', name: 'Traditional Clay Diya (Mitti Earthen Lamp) Set (12 Pcs)', quantity: '12 Pcs', category: 'Utensils', price: 60, icon: '🪔'),
    SamagriItem(id: 'smg_hawan_kund', name: 'Heavy Stepped Copper Hawan Kund Stand', quantity: '1 Pc', category: 'Utensils', price: 550, icon: '🔥'),
    SamagriItem(id: 'smg_panchapatra', name: 'Brass Panchapatra with Achamani Pali Spoon', quantity: '1 Set', category: 'Utensils', price: 280, icon: '🏺'),
    SamagriItem(id: 'smg_garuda_bell', name: 'Auspicious Brass Pooja Ghanti (Garuda Bell)', quantity: '1 Pc', category: 'Utensils', price: 290, icon: '🔔'),
    SamagriItem(id: 'smg_aarti_diya', name: 'Pancha Aarti 5-Flame Brass Diya Stand', quantity: '1 Pc', category: 'Utensils', price: 340, icon: '🪔'),
    SamagriItem(id: 'smg_shankh_blowing', name: 'Natural Consecrated Vamavarti Blowing Shankh', quantity: '1 Pc', category: 'Utensils', price: 450, icon: '🐚'),
    SamagriItem(id: 'smg_cotton_wicks', name: 'Round & Long Pure Cotton Wicks (Batti 100 Pcs)', quantity: '100 Pcs', category: 'Utensils', price: 30, icon: '🕯️'),
    SamagriItem(id: 'smg_vastu_shila_metal', name: 'Vastu Purusha Shila & 5-Metal Token Box', quantity: '1 Set', category: 'Utensils', price: 140, icon: '🪙'),
    SamagriItem(id: 'smg_navaratna_shila', name: '9 Gemstone (Navaratna) Vastu Purusha Shila Box', quantity: '1 Set', category: 'Utensils', price: 220, icon: '💎'),
    SamagriItem(id: 'smg_yantra_sri_kubera', name: 'Gold-Plated Sri Lakshmi Kubera Yantra Plate', quantity: '1 Set', category: 'Utensils', price: 180, icon: '🪙'),
    SamagriItem(id: 'smg_yantra_navagraha', name: 'Consecrated Copper Navagraha Yantra Plate', quantity: '1 Set', category: 'Utensils', price: 140, icon: '🪙'),
    SamagriItem(id: 'smg_silver_baby_spoon', name: 'Consecrated Silver Baby Spoon Token for Namakaran', quantity: '1 Set', category: 'Utensils', price: 180, icon: '🪙'),

    // ─── Herbs & Sacred Woods ───
    SamagriItem(id: 'smg_dashmoola_ayur', name: 'Dashmoola Ayurvedic 10-Root Herb Churna', quantity: '100g', category: 'Herbs', price: 110, icon: '🌿'),
    SamagriItem(id: 'smg_mrityunjaya_32', name: '32 Ayurvedic Healing Herb Churna (Mrityunjaya Blend)', quantity: '150g', category: 'Herbs', price: 130, icon: '🌿'),
    SamagriItem(id: 'smg_palash_samidha', name: 'Pure Palash (Moduga) Samidha Sticks Bundle', quantity: '1 Bundle', category: 'Herbs', price: 75, icon: '🪵'),
    SamagriItem(id: 'smg_navagraha_samidha', name: 'Navagraha 9-Planetary Wood Samidha Sticks Bundle', quantity: '1 Bundle', category: 'Herbs', price: 90, icon: '🪵'),
    SamagriItem(id: 'smg_mango_wood_logs', name: 'Dry Mango Wood Logs for Havan (Aam Ki Lakdi)', quantity: '1 Kg', category: 'Herbs', price: 90, icon: '🪵'),
    SamagriItem(id: 'smg_sudarshana_samidha', name: 'Sudarshana Khadira Samidha Sticks & Hawan Herbs', quantity: '150g', category: 'Herbs', price: 120, icon: '🪵'),
    SamagriItem(id: 'smg_jatamansi_blend', name: 'Sacred Jatamansi & Nagarmotha Root Blend', quantity: '100g', category: 'Herbs', price: 120, icon: '🌿'),
    SamagriItem(id: 'smg_bhoomi_vastu_herbs', name: '108 Sacred Herb Bhoomi Vastu Mahayajna Blend', quantity: '250g', category: 'Herbs', price: 150, icon: '🌿'),
    SamagriItem(id: 'smg_charu_dravya', name: 'Sacred Charu Rice & Milk Oblation Dravyam Mix', quantity: '150g', category: 'Herbs', price: 110, icon: '🌾'),

    // ─── Incense & Aroma ───
    SamagriItem(id: 'smg_agarbatti_sandal', name: 'Mysore Sandalwood Agarbatti (100 Sticks)', quantity: '1 Pack', category: 'Incense', price: 80, icon: '🕯️'),
    SamagriItem(id: 'smg_loban_benzoin', name: 'Natural Benzoin Loban (Pure Dhoop Sticks 20 Pcs)', quantity: '20 Pcs', category: 'Incense', price: 60, icon: '💨'),
    SamagriItem(id: 'smg_gugal_himalayan', name: 'Pure Himalayan Gugal Dhoop Resin', quantity: '100g', category: 'Incense', price: 70, icon: '💨'),
    SamagriItem(id: 'smg_sambrani_cups', name: 'Traditional Charcoal Sambrani Dhoop Cups (12 Cups)', quantity: '12 Cups', category: 'Incense', price: 90, icon: '💨'),
    SamagriItem(id: 'smg_kasturi_chandan_dhoop', name: 'Royal Kasturi & Chandan Dhoop Cones (20 Pcs)', quantity: '20 Pcs', category: 'Incense', price: 75, icon: '💨'),
    SamagriItem(id: 'smg_panchagavya_diyas', name: 'Panchagavya Cow Dung Organic Diyas (11 Pcs)', quantity: '11 Pcs', category: 'Incense', price: 65, icon: '🪔'),
    SamagriItem(id: 'smg_havan_cups_mini', name: 'Ready-to-Light Mini Hawan Cups with Guggul & Loban', quantity: '6 Cups', category: 'Incense', price: 110, icon: '🔥'),
  ];

  // ─── CEREMONY_SAMAGRI_MAPPING (20 ceremonies + generic default) ─────────
  static const Map<String, CeremonySamagriKit> ceremonyMapping = {
    'grihapravesh': CeremonySamagriKit(
      ceremonyName: 'Griha Pravesh & Vastu Shanti',
      standard: [
        SamagriItem(id: 'std_gp_vastu_shila', name: 'Vastu Purusha Shila & 5 Consecrated Panchadhatu Metals', quantity: '1 Set', category: 'Utensils', price: 140, icon: '🪙'),
        SamagriItem(id: 'std_gp_vastu_hawan', name: 'Vastu Shanti 108 Herb Hawan Dravyam', quantity: '150g', category: 'Herbs', price: 120, icon: '🌿'),
        SamagriItem(id: 'std_gp_mango_toran', name: 'Fresh Mango & Peepal Leaves Entrance Toran Bundle', quantity: '1 Bundle', category: 'Flowers', price: 80, icon: '🍃'),
        SamagriItem(id: 'std_gp_navadhanya', name: 'Navadhanya (9 Sacred Grains) for Threshold Sowing', quantity: '250g', category: 'Dry Items', price: 80, icon: '🌾'),
        SamagriItem(id: 'std_gp_milk_vessel', name: 'Sacred Milk Boiling Dravyam & Desi Cow Ghee', quantity: '250ml', category: 'Liquids', price: 160, icon: '🥛'),
        SamagriItem(id: 'std_gp_sriphal', name: 'Consecrated Whole Coconut with Sacred Kalava', quantity: '1 Pc', category: 'Utensils', price: 60, icon: '🥥'),
      ],
      premium: [
        SamagriItem(id: 'prm_gp_navaratna_box', name: '9-Gemstone (Navaratna) Vastu Purusha Maha Shila Box', quantity: '1 Set', category: 'Utensils', price: 220, icon: '💎'),
        SamagriItem(id: 'prm_gp_copper_kalash', name: 'Heavy Pure Copper Swastik Kalash with Coconut', quantity: '1 Set', category: 'Utensils', price: 200, icon: '🏺'),
        SamagriItem(id: 'prm_gp_silk_vastram', name: 'Red & Gold Peeta Silk Vastram for Vastu Sthapana', quantity: '1 Set', category: 'Dry Items', price: 120, icon: '🧣'),
        SamagriItem(id: 'prm_gp_a2_ghee_ganga', name: 'Pure Gir Cow A2 Bilona Ghee & Gangotri Gangajal Set', quantity: '1 Set', category: 'Liquids', price: 340, icon: '🍯'),
        SamagriItem(id: 'prm_gp_vastu_samidha', name: 'Khadir & Palash Vastu Samidha Hawan Wood Sticks', quantity: '1 Bundle', category: 'Herbs', price: 90, icon: '🪵'),
        SamagriItem(id: 'prm_gp_sambrani_cups', name: 'Charcoal Sambrani Cups & Himalayan Guggul Dhoop', quantity: '1 Pack', category: 'Incense', price: 80, icon: '💨'),
      ],
    ),

    'satyanarayana': CeremonySamagriKit(
      ceremonyName: 'Sri Satyanarayana Swamy Vratam',
      standard: [
        SamagriItem(id: 'std_sn_katha_pothi', name: 'Sri Satyanarayana Vrata Katha Pothi & Puja Vidhi Dravyam', quantity: '1 Set', category: 'Dry Items', price: 100, icon: '📜'),
        SamagriItem(id: 'std_sn_sapatha_mix', name: 'Sapatha Maha Prasad Kit (Wheat Flour, Sooji, Jaggery, Elaichi)', quantity: '1 Box', category: 'Dry Items', price: 120, icon: '🌾'),
        SamagriItem(id: 'std_sn_tulsi_supari', name: '108 Fresh Organic Tulsi Dala & 21 Whole Supari Nuts', quantity: '1 Set', category: 'Flowers', price: 80, icon: '🌱'),
        SamagriItem(id: 'std_sn_panchamrit', name: 'Panchamrit Divine 5-Nectar Mix (Honey, Milk, Curd, Ghee)', quantity: '1 Set', category: 'Liquids', price: 120, icon: '🥛'),
        SamagriItem(id: 'std_sn_betel_janeu', name: 'Fresh Green Betel Leaves (21 Pcs) & Sacred Janeu Thread', quantity: '1 Set', category: 'Flowers', price: 70, icon: '🍃'),
        SamagriItem(id: 'std_sn_haldi_kumkum', name: 'Kasturi Haldi, Roli Kumkum & Whole Grain Akshat', quantity: '1 Set', category: 'Dry Items', price: 50, icon: '🔴'),
      ],
      premium: [
        SamagriItem(id: 'prm_sn_lotus_tulsi', name: '5 Fresh Pink Lotus Blooms & Tulsi Manjari Garland', quantity: '1 Set', category: 'Flowers', price: 160, icon: '🪷'),
        SamagriItem(id: 'prm_sn_panchamewa', name: 'Royal Panchamewa Dry Fruits Box (Cashews, Almonds, Makhana)', quantity: '1 Box', category: 'Dry Items', price: 150, icon: '🥜'),
        SamagriItem(id: 'prm_sn_pitambari', name: 'Pure Yellow Pitambari Silk Vastram for Lord Satyanarayana', quantity: '1 Set', category: 'Dry Items', price: 130, icon: '🧣'),
        SamagriItem(id: 'prm_sn_copper_kalash', name: 'Consecrated Copper Kalash with Coconut & Mango Leaves', quantity: '1 Set', category: 'Utensils', price: 160, icon: '🏺'),
        SamagriItem(id: 'prm_sn_a2_ghee', name: 'Pure Desi Cow A2 Bilona Ghee for Akhanda Deepam (500ml)', quantity: '500ml', category: 'Liquids', price: 320, icon: '🍯'),
        SamagriItem(id: 'prm_sn_gangotri_rose', name: 'Sealed Gangotri Gangajal Lota & Distilled Rose Water', quantity: '1 Set', category: 'Liquids', price: 130, icon: '🏺'),
      ],
    ),

    'rudrabhishekam': CeremonySamagriKit(
      ceremonyName: 'Maha Rudrabhishekam (Ekadasa)',
      standard: [
        SamagriItem(id: 'std_rb_bilva_108', name: '108 Fresh Sacred Bilva Patra (Bel Leaves Bundle)', quantity: '108 Leaves', category: 'Flowers', price: 120, icon: '🍃'),
        SamagriItem(id: 'std_rb_ekadasa_mix', name: 'Ekadasa (11) Sacred Dravya Abhishekam Liquid Mix', quantity: '1 Set', category: 'Liquids', price: 150, icon: '🥛'),
        SamagriItem(id: 'std_rb_bhasma_vibhuti', name: 'Maha Shivaratri Vibhuti Bhasma & Mysore Chandan Paste', quantity: '1 Set', category: 'Dry Items', price: 90, icon: '🪵'),
        SamagriItem(id: 'std_rb_til_ghee', name: 'Pure Gingelly Sesame Oil (Til Tel) & Cow Ghee for Shivalinga', quantity: '1 Set', category: 'Liquids', price: 120, icon: '🫙'),
        SamagriItem(id: 'std_rb_camphor_aarti', name: 'Bhimseni Kapoor Aarti Stand with Cotton Wicks', quantity: '1 Set', category: 'Utensils', price: 60, icon: '🕯️'),
        SamagriItem(id: 'std_rb_rudraksha_bilva', name: 'Rudraksha Consecration Thread & Bilva Fruit (Phalam)', quantity: '1 Set', category: 'Dry Items', price: 80, icon: '🌰'),
      ],
      premium: [
        SamagriItem(id: 'prm_rb_dhatura_lotus', name: 'Sacred Dhatura Flowers, Fruit & Blue Lotus Blooms', quantity: '1 Set', category: 'Flowers', price: 150, icon: '🌱'),
        SamagriItem(id: 'prm_rb_gangotri_lota', name: 'Sealed Gangotri Gangajal Brass Lota for Snanam (500ml)', quantity: '500ml', category: 'Liquids', price: 150, icon: '🏺'),
        SamagriItem(id: 'prm_rb_panchapatra_brass', name: 'Pure Brass Panchapatra with Achamani Pali Spoon', quantity: '1 Set', category: 'Utensils', price: 160, icon: '🏺'),
        SamagriItem(id: 'prm_rb_honey_ghee_ittar', name: 'Raw Forest Honey, A2 Cow Ghee & Sugandhi Attar Abhishekam', quantity: '1 Set', category: 'Liquids', price: 310, icon: '🍯'),
        SamagriItem(id: 'prm_rb_guggul_loban', name: 'Himalayan Guggul, Natural Loban Resin & Sambrani Cups', quantity: '1 Set', category: 'Incense', price: 90, icon: '💨'),
        SamagriItem(id: 'prm_rb_shiva_token', name: 'Consecrated Shiva Lingam Yantra Protective Token', quantity: '1 Set', category: 'Utensils', price: 140, icon: '🪙'),
      ],
    ),

    'ganapathi': CeremonySamagriKit(
      ceremonyName: 'Maha Ganapathi Homam',
      standard: [
        SamagriItem(id: 'std_gn_durva_21', name: '21 Bundles of Fresh Green Durva Grass (Garika)', quantity: '21 Bundles', category: 'Flowers', price: 70, icon: '🌿'),
        SamagriItem(id: 'std_gn_modak_ahuti', name: '21 Consecrated Modaks & Sweets Ahuti Kit', quantity: '1 Set', category: 'Dry Items', price: 110, icon: '🌾'),
        SamagriItem(id: 'std_gn_moduga_wood', name: 'Palash / Moduga Sacred Samidha Wood Sticks', quantity: '1 Bundle', category: 'Herbs', price: 80, icon: '🪵'),
        SamagriItem(id: 'std_gn_sindoor_haldi', name: 'Orange Ganesha Sindoor, Kasturi Haldi & Akshat Pack', quantity: '1 Set', category: 'Dry Items', price: 60, icon: '🔴'),
        SamagriItem(id: 'std_gn_khopra_jaggery', name: 'Dry Copra Halves (Khopra Gola) & Organic Jaggery Ahuti', quantity: '1 Set', category: 'Dry Items', price: 90, icon: '🥥'),
        SamagriItem(id: 'std_gn_diyas_batti', name: 'Terracotta Mitti Diyas & Cotton Batti Set', quantity: '1 Set', category: 'Utensils', price: 50, icon: '🪔'),
      ],
      premium: [
        SamagriItem(id: 'prm_gn_jaswand_garland', name: '21 Fresh Red Hibiscus (Jaswand) & Red Rose Garland', quantity: '1 Set', category: 'Flowers', price: 140, icon: '🌺'),
        SamagriItem(id: 'prm_gn_108_ganapathi', name: '108 Herb Maha Ganapathi Homam Dravyam Special Blend', quantity: '250g', category: 'Dry Items', price: 180, icon: '🌿'),
        SamagriItem(id: 'prm_gn_a2_ghee_ganga', name: 'Pure A2 Gir Cow Ghee & Gangotri Gangajal for Maha Ahuti', quantity: '1 Set', category: 'Liquids', price: 340, icon: '🍯'),
        SamagriItem(id: 'prm_gn_ganesha_yantra', name: 'Gold-Plated Sri Maha Ganapathi Yantra Token', quantity: '1 Set', category: 'Utensils', price: 160, icon: '🪙'),
        SamagriItem(id: 'prm_gn_sriphal_sutra', name: 'Whole Consecrated Sriphal Coconut with Ganesha Raksha Sutra', quantity: '1 Pc', category: 'Utensils', price: 70, icon: '🥥'),
        SamagriItem(id: 'prm_gn_loban_camphor', name: 'Natural Benzoin Loban & Bhimseni Crystalline Camphor', quantity: '1 Set', category: 'Incense', price: 80, icon: '💨'),
      ],
    ),

    'lakshmi-kubera': CeremonySamagriKit(
      ceremonyName: 'Sri Maha Lakshmi & Kubera Homam',
      standard: [
        SamagriItem(id: 'std_lk_kamalgatta', name: '108 Sacred Lotus Seeds (Kamalgatta Rosary & Ahuti)', quantity: '1 Pack', category: 'Dry Items', price: 110, icon: '🪷'),
        SamagriItem(id: 'std_lk_sri_suktam', name: 'Sri Suktam Hawan Dravyam with Saffron & Sandalwood', quantity: '150g', category: 'Dry Items', price: 120, icon: '🌿'),
        SamagriItem(id: 'std_lk_gomti_kauri', name: 'Consecrated Gomti Chakras (11 Pcs) & Yellow Kauri Shells', quantity: '1 Set', category: 'Dry Items', price: 90, icon: '🐚'),
        SamagriItem(id: 'std_lk_elaichi_lavang', name: 'Green Cardamom, Cloves & Nutmeg Puja Offering Pack', quantity: '1 Set', category: 'Dry Items', price: 80, icon: '🌱'),
        SamagriItem(id: 'std_lk_kumkum_swastik', name: 'Natural Red Kumkum, Kasturi Haldi & Swastik Sheet', quantity: '1 Set', category: 'Dry Items', price: 60, icon: '🔴'),
        SamagriItem(id: 'std_lk_misri_ghee', name: 'Organic Crystal Dhaga Misri & Cow Ghee for Ahuti', quantity: '1 Set', category: 'Liquids', price: 100, icon: '🍯'),
      ],
      premium: [
        SamagriItem(id: 'prm_lk_yantra_kubera', name: 'Gold-Plated Sri Yantra & Kubera Dhanakarshana Plate', quantity: '1 Set', category: 'Utensils', price: 200, icon: '🪙'),
        SamagriItem(id: 'prm_lk_lotus_petals', name: '11 Fresh Sacred Pink Lotus Blooms & Rose Petals Basket', quantity: '1 Set', category: 'Flowers', price: 180, icon: '🪷'),
        SamagriItem(id: 'prm_lk_crimson_silk', name: 'Pure Crimson Red Silk Vastram with Golden Zari Border', quantity: '1 Set', category: 'Dry Items', price: 140, icon: '🧣'),
        SamagriItem(id: 'prm_lk_panchamewa_box', name: 'Royal Panchamewa Dry Fruits Ahuti Box (Cashews, Makhana)', quantity: '1 Box', category: 'Dry Items', price: 150, icon: '🥜'),
        SamagriItem(id: 'prm_lk_a2_ghee_gulab', name: 'Pure Gir Cow A2 Bilona Ghee & Distilled Gulab Jal', quantity: '1 Set', category: 'Liquids', price: 340, icon: '🍯'),
        SamagriItem(id: 'prm_lk_kasturi_dhoop', name: 'Royal Kasturi Chandan Dhoop & Benzoin Loban Cups', quantity: '1 Set', category: 'Incense', price: 80, icon: '💨'),
      ],
    ),

    'mrityunjaya': CeremonySamagriKit(
      ceremonyName: 'Maha Mrityunjaya Homam',
      standard: [
        SamagriItem(id: 'std_mj_ayur_32', name: '32 Ayurvedic Healing Roots (Amrita, Giloy, Ashwagandha)', quantity: '150g', category: 'Herbs', price: 140, icon: '🌿'),
        SamagriItem(id: 'std_mj_black_sesame', name: 'Sacred Black Sesame Seeds (Kala Til 250g)', quantity: '250g', category: 'Dry Items', price: 60, icon: '⚫'),
        SamagriItem(id: 'std_mj_palash_sticks', name: 'Palash & Peepal Sacred Samidha Hawan Sticks Bundle', quantity: '1 Bundle', category: 'Herbs', price: 80, icon: '🪵'),
        SamagriItem(id: 'std_mj_vibhuti_chandan', name: 'Sacred Maha Bhasma Vibhuti & Sandalwood Powder', quantity: '1 Set', category: 'Dry Items', price: 70, icon: '🪵'),
        SamagriItem(id: 'std_mj_raksha_potli', name: 'Maha Mrityunjaya Raksha Sutra Potli with Thread', quantity: '1 Set', category: 'Dry Items', price: 80, icon: '🧶'),
        SamagriItem(id: 'std_mj_ghee_ahuti', name: 'Pure Desi Cow Ghee for Amrit Ahuti Oblations', quantity: '250ml', category: 'Liquids', price: 160, icon: '🍯'),
      ],
      premium: [
        SamagriItem(id: 'prm_mj_108_himalayan', name: '108 Rare Himalayan Ayurvedic Healing Herb & Amrit Blend', quantity: '250g', category: 'Dry Items', price: 220, icon: '🌿'),
        SamagriItem(id: 'prm_mj_gangotri_lota', name: 'Sealed Gangotri Gangajal Brass Lota for Sankalpa (500ml)', quantity: '500ml', category: 'Liquids', price: 150, icon: '🏺'),
        SamagriItem(id: 'prm_mj_guggul_loban', name: 'Pure Himalayan Guggul Dhoop Resin & Loban Sambrani', quantity: '1 Set', category: 'Incense', price: 90, icon: '💨'),
        SamagriItem(id: 'prm_mj_yantra_copper', name: 'Consecrated Copper Maha Mrityunjaya Protective Shila', quantity: '1 Set', category: 'Utensils', price: 160, icon: '🪙'),
        SamagriItem(id: 'prm_mj_a2_honey_set', name: 'Pure A2 Desi Cow Bilona Ghee & Raw Forest Honey Set', quantity: '1 Set', category: 'Liquids', price: 340, icon: '🍯'),
        SamagriItem(id: 'prm_mj_durva_bilva_dhat', name: 'Fresh Durva Grass, Bilva Patra & Dhatura Flower Pack', quantity: '1 Set', category: 'Flowers', price: 110, icon: '🍃'),
      ],
    ),

    'navagraha': CeremonySamagriKit(
      ceremonyName: 'Navagraha Shanti Homam',
      standard: [
        SamagriItem(id: 'std_ng_9_samidha', name: '9 Planetary Wood Samidha Sticks (Arka, Palash, Khadira)', quantity: '1 Bundle', category: 'Herbs', price: 120, icon: '🪵'),
        SamagriItem(id: 'std_ng_navadhanya', name: 'Certified Navadhanya (9 Sacred Planetary Grains 250g)', quantity: '250g', category: 'Dry Items', price: 90, icon: '🌾'),
        SamagriItem(id: 'std_ng_9_colored_rice', name: '9 Planetary Color Akshat Rice Mix for Mandala', quantity: '1 Set', category: 'Dry Items', price: 90, icon: '🌾'),
        SamagriItem(id: 'std_ng_haldi_janeu', name: 'Roli Kumkum, Kasturi Haldi, Janeu Threads & Kalava', quantity: '1 Set', category: 'Dry Items', price: 60, icon: '🔴'),
        SamagriItem(id: 'std_ng_til_ghee', name: 'Pure Gingelly Sesame Oil & Desi Cow Ghee for 9 Grahas', quantity: '1 Set', category: 'Liquids', price: 130, icon: '🫙'),
        SamagriItem(id: 'std_ng_bali_coconut', name: 'Consecrated Whole Coconut for Navagraha Bali & Ahuti', quantity: '1 Pc', category: 'Utensils', price: 60, icon: '🥥'),
      ],
      premium: [
        SamagriItem(id: 'prm_ng_navavastram_9', name: '9 Sacred Planetary Colored Silk Cloths (Navavastram Set)', quantity: '1 Set (9 Pcs)', category: 'Dry Items', price: 200, icon: '🧣'),
        SamagriItem(id: 'prm_ng_yantra_copper', name: 'Navagraha Yantra Consecrated Heavy Copper Plate', quantity: '1 Set', category: 'Utensils', price: 160, icon: '🪙'),
        SamagriItem(id: 'prm_ng_108_shanti', name: '108 Herb Navagraha Shanti Mahayajna Dravyam Blend', quantity: '250g', category: 'Dry Items', price: 180, icon: '🌿'),
        SamagriItem(id: 'prm_ng_gangotri_rose', name: 'Sealed Gangotri Gangajal Brass Lota & Rose Water', quantity: '1 Set', category: 'Liquids', price: 140, icon: '🏺'),
        SamagriItem(id: 'prm_ng_a2_ghee_panch', name: 'Pure A2 Desi Cow Ghee & Panchamewa Offering Box', quantity: '1 Set', category: 'Liquids', price: 340, icon: '🍯'),
        SamagriItem(id: 'prm_ng_sandal_loban', name: 'Pure Mysore Sandalwood Chandan & Loban Dhoop Cones', quantity: '1 Pack', category: 'Incense', price: 80, icon: '🪵'),
      ],
    ),

    'chandi': CeremonySamagriKit(
      ceremonyName: 'Navachandi Mahayajnam (Sri Chandi Homam)',
      standard: [
        SamagriItem(id: 'std_ch_saptashati_mix', name: 'Durga Saptashati 108 Herb Sacred Hawan Dravyam', quantity: '200g', category: 'Dry Items', price: 150, icon: '🌿'),
        SamagriItem(id: 'std_ch_silk_chunri', name: 'Red Silk Mata Chunri with Golden Lace & Sindoor', quantity: '1 Set', category: 'Dry Items', price: 110, icon: '🧣'),
        SamagriItem(id: 'std_ch_khopra_ahuti', name: 'Whole Dry Coconut (Khopra Gola) for Purna Ahuti', quantity: '1 Set', category: 'Dry Items', price: 90, icon: '🥥'),
        SamagriItem(id: 'std_ch_mata_shringaar', name: 'Consecrated Mata Shringaar Set (Kumkum, Bindi, Alta)', quantity: '1 Set', category: 'Dry Items', price: 80, icon: '🔴'),
        SamagriItem(id: 'std_ch_betel_supari', name: 'Fresh Green Betel Leaves (21 Pcs), Supari & Elaichi', quantity: '1 Set', category: 'Flowers', price: 70, icon: '🍃'),
        SamagriItem(id: 'std_ch_ghee_aarti', name: 'Pure Desi Cow Ghee & Camphor Aarti Stand', quantity: '1 Set', category: 'Liquids', price: 160, icon: '🍯'),
      ],
      premium: [
        SamagriItem(id: 'prm_ch_108_rare', name: '108 Rare Sacred Chandi Mahayajna Herbal & Dry Fruit Blend', quantity: '250g', category: 'Dry Items', price: 220, icon: '🌿'),
        SamagriItem(id: 'prm_ch_hibiscus_lotus', name: 'Fresh Red Hibiscus Garlands & Fresh Pink Lotus Blooms', quantity: '1 Set', category: 'Flowers', price: 160, icon: '🌺'),
        SamagriItem(id: 'prm_ch_copper_kalash', name: 'Ornate Heavy Copper Kalash with Coconut & Gangajal', quantity: '1 Set', category: 'Utensils', price: 180, icon: '🏺'),
        SamagriItem(id: 'prm_ch_zari_sari', name: 'Ornate Red Zari Silk Mata Sari & Silver Shringaar Pack', quantity: '1 Set', category: 'Dry Items', price: 180, icon: '🧣'),
        SamagriItem(id: 'prm_ch_a2_ghee_attar', name: 'Pure Desi Cow A2 Bilona Ghee (500ml) & Sugandhi Attar', quantity: '1 Set', category: 'Liquids', price: 340, icon: '🍯'),
        SamagriItem(id: 'prm_ch_guggul_loban', name: 'Himalayan Guggul Resin, Benzoin Loban & Sambrani Cups', quantity: '1 Set', category: 'Incense', price: 90, icon: '💨'),
      ],
    ),

    'wedding': CeremonySamagriKit(
      ceremonyName: 'Vedic Vivah Samskara (Complete Wedding)',
      standard: [
        SamagriItem(id: 'std_wd_laja_homam', name: 'Sacred Laja (Puffed Rice) & Khadira Samidha for Laja Homam', quantity: '1 Set', category: 'Dry Items', price: 130, icon: '🌾'),
        SamagriItem(id: 'std_wd_mangalsutra_haldi', name: 'Mangalsutra Yellow Thread with Raw Turmeric (Haldi) Knots', quantity: '1 Set', category: 'Dry Items', price: 110, icon: '🔴'),
        SamagriItem(id: 'std_wd_kanyadaan_set', name: 'Kanyadaan Consecrated Coconut, Betel Leaves & Supari', quantity: '1 Set', category: 'Dry Items', price: 90, icon: '🥥'),
        SamagriItem(id: 'std_wd_akshada_bless', name: 'Whole Grain Akshada (Turmeric Colored Rice) for Blessings', quantity: '1 Set', category: 'Dry Items', price: 70, icon: '🌾'),
        SamagriItem(id: 'std_wd_kalava_sutra', name: 'Sacred Kalava Raksha Sutra for Kankana Dharana', quantity: '1 Set', category: 'Dry Items', price: 50, icon: '🧶'),
        SamagriItem(id: 'std_wd_diyas_camphor', name: 'Clay Diyas, Cotton Wicks & Pure Camphor Set', quantity: '1 Set', category: 'Utensils', price: 60, icon: '🪔'),
      ],
      premium: [
        SamagriItem(id: 'prm_wd_saptapadi_mats', name: 'Sacred Saptapadi 7-Step Mats, Yellow Peeta & Red Silk Vastram', quantity: '1 Set', category: 'Dry Items', price: 220, icon: '🧣'),
        SamagriItem(id: 'prm_wd_jaimala_petals', name: 'Fresh Rose Petals, Jaimala Marigolds & Lotus Garlands', quantity: '1 Set', category: 'Flowers', price: 180, icon: '🌸'),
        SamagriItem(id: 'prm_wd_copper_kalash', name: 'Copper Kalash with Gangotri Gangajal & Mango Toran', quantity: '1 Set', category: 'Utensils', price: 190, icon: '🏺'),
        SamagriItem(id: 'prm_wd_rose_attar_spray', name: 'Distilled Rose Water Spray Decanter & Pure Mysore Attar', quantity: '1 Set', category: 'Liquids', price: 120, icon: '🌹'),
        SamagriItem(id: 'prm_wd_panchamewa_box', name: 'Royal Panchamewa Dry Fruits & Honey Sweet Naivedyam Box', quantity: '1 Set', category: 'Dry Items', price: 150, icon: '🥜'),
        SamagriItem(id: 'prm_wd_a2_ghee_agni', name: 'Pure Desi Cow A2 Organic Ghee for Vivah Agni Sthapana', quantity: '500ml', category: 'Liquids', price: 320, icon: '🍯'),
      ],
    ),

    'sudarshana': CeremonySamagriKit(
      ceremonyName: 'Maha Sudarshana & Narasimha Homam',
      standard: [
        SamagriItem(id: 'std_sd_samidha_wood', name: 'Sudarshana Khadira Samidha Sticks & Protective Hawan Herbs', quantity: '150g', category: 'Herbs', price: 130, icon: '🪵'),
        SamagriItem(id: 'std_sd_sesame_mustard', name: 'Black Sesame & White Mustard Seeds for Drishti Nivarana', quantity: '1 Set', category: 'Dry Items', price: 90, icon: '⚫'),
        SamagriItem(id: 'std_sd_tulsi_leaves', name: 'Fresh Organic Tulsi Leaves & Tulsi Seed Manjari', quantity: '1 Set', category: 'Flowers', price: 60, icon: '🌱'),
        SamagriItem(id: 'std_sd_sindoor_chandan', name: 'Pure Vermilion Sindoor, Mysore Sandalwood & Vibhuti', quantity: '1 Set', category: 'Dry Items', price: 80, icon: '🔴'),
        SamagriItem(id: 'std_sd_bali_coconut', name: 'Consecrated Whole Coconut for Shatru Dosha Bali', quantity: '1 Pc', category: 'Utensils', price: 60, icon: '🥥'),
        SamagriItem(id: 'std_sd_ghee_oblation', name: 'Pure Desi Cow Ghee for Sudarshana Mantra Ahutis', quantity: '250ml', category: 'Liquids', price: 160, icon: '🍯'),
      ],
      premium: [
        SamagriItem(id: 'prm_sd_yantra_copper', name: 'Consecrated Copper Sudarshana Narasimha Yantra Plate', quantity: '1 Set', category: 'Utensils', price: 180, icon: '🪙'),
        SamagriItem(id: 'prm_sd_108_sudarshana', name: '108 Rare Herb Sudarshana Mahayajna Dravyam Blend', quantity: '250g', category: 'Dry Items', price: 200, icon: '🌿'),
        SamagriItem(id: 'prm_sd_tulsi_garland', name: 'Fresh Tulsi Manjari Garlands & Fragrant Yellow Blooms', quantity: '1 Set', category: 'Flowers', price: 140, icon: '🌱'),
        SamagriItem(id: 'prm_sd_gangotri_lota', name: 'Sealed Gangotri Gangajal Brass Lota (500ml)', quantity: '500ml', category: 'Liquids', price: 150, icon: '🏺'),
        SamagriItem(id: 'prm_sd_a2_ghee_honey', name: 'Pure A2 Desi Cow Bilona Ghee & Raw Forest Honey Set', quantity: '1 Set', category: 'Liquids', price: 340, icon: '🍯'),
        SamagriItem(id: 'prm_sd_guggul_loban', name: 'Pure Himalayan Guggul & Benzoin Loban Smoke Cups', quantity: '1 Set', category: 'Incense', price: 80, icon: '💨'),
      ],
    ),

    'ayush': CeremonySamagriKit(
      ceremonyName: 'Ayush Homam (Longevity Blessing)',
      standard: [
        SamagriItem(id: 'std_ay_dashmoola', name: 'Ayushya Suktam 10-Root Dashamoola Herbal Dravyam', quantity: '150g', category: 'Herbs', price: 130, icon: '🌿'),
        SamagriItem(id: 'std_ay_charu_mix', name: 'Sacred Charu Rice & Milk Oblation Dravyam Mix', quantity: '150g', category: 'Dry Items', price: 110, icon: '🌾'),
        SamagriItem(id: 'std_ay_palash_wood', name: 'Palasha Sacred Samidha Wood Sticks Bundle', quantity: '1 Bundle', category: 'Herbs', price: 80, icon: '🪵'),
        SamagriItem(id: 'std_ay_akshat_sutra', name: 'Consecrated Whole Akshat Rice, Kasturi Haldi & Raksha Sutra', quantity: '1 Set', category: 'Dry Items', price: 70, icon: '🔴'),
        SamagriItem(id: 'std_ay_ghee_ahuti', name: 'Pure Desi Cow Ghee for Longevity Ahutis', quantity: '250ml', category: 'Liquids', price: 160, icon: '🍯'),
        SamagriItem(id: 'std_ay_diya_camphor', name: 'Earthen Clay Diyas & Pure Bhimseni Camphor Tablets', quantity: '1 Set', category: 'Utensils', price: 60, icon: '🪔'),
      ],
      premium: [
        SamagriItem(id: 'prm_ay_108_longevity', name: '108 Ayurvedic Longevity & Medha Herbal Blend (Ashwagandha, Shatavari)', quantity: '250g', category: 'Dry Items', price: 220, icon: '🌿'),
        SamagriItem(id: 'prm_ay_coin_kankanam', name: 'Consecrated Copper Ayushya Coin & Raksha Kankanam Thread', quantity: '1 Set', category: 'Utensils', price: 140, icon: '🪙'),
        SamagriItem(id: 'prm_ay_panchamewa_box', name: 'Royal Panchamewa Dry Fruits & Pure Raw Honey Box', quantity: '1 Set', category: 'Dry Items', price: 150, icon: '🥜'),
        SamagriItem(id: 'prm_ay_gangotri_lota', name: 'Sealed Gangotri Gangajal Brass Lota (500ml)', quantity: '500ml', category: 'Liquids', price: 150, icon: '🏺'),
        SamagriItem(id: 'prm_ay_a2_ghee_bilona', name: 'Pure Desi Cow A2 Organic Bilona Ghee (500ml)', quantity: '500ml', category: 'Liquids', price: 320, icon: '🍯'),
        SamagriItem(id: 'prm_ay_chandan_dhoop', name: 'Pure Mysore Sandalwood Chandan & Loban Dhoop Cups', quantity: '1 Pack', category: 'Incense', price: 80, icon: '🪵'),
      ],
    ),

    'saraswati': CeremonySamagriKit(
      ceremonyName: 'Saraswati Puja & Aksharabhyasam',
      standard: [
        SamagriItem(id: 'std_sw_slate_chalk_pen', name: 'Saraswati Wooden Slate (Pattika), Sacred Chalk & Pen', quantity: '1 Set', category: 'Dry Items', price: 140, icon: '✏️'),
        SamagriItem(id: 'std_sw_yellow_marigold', name: 'Fresh Fragrant Yellow Marigold & Jasmine Flower Garland', quantity: '1 Set', category: 'Flowers', price: 90, icon: '🌼'),
        SamagriItem(id: 'std_sw_misri_jaggery', name: 'Crystal Dhaga Misri, Organic Jaggery & Sweet Naivedyam', quantity: '1 Pack', category: 'Dry Items', price: 70, icon: '🍯'),
        SamagriItem(id: 'std_sw_betel_supari', name: 'Fresh Green Betel Leaves (21 Pcs) & Sacred Supari Nuts', quantity: '1 Set', category: 'Flowers', price: 60, icon: '🍃'),
        SamagriItem(id: 'std_sw_haldi_kumkum', name: 'Kasturi Haldi, Kumkum & Akshat Rice for Alphabet Inscription', quantity: '1 Set', category: 'Dry Items', price: 60, icon: '🔴'),
        SamagriItem(id: 'std_sw_diya_agarbatti', name: 'Traditional Clay Diyas & Sandalwood Incense Sticks', quantity: '1 Set', category: 'Utensils', price: 60, icon: '🪔'),
      ],
      premium: [
        SamagriItem(id: 'prm_sw_yantra_silver_pen', name: 'Gold-Plated Saraswati Yantra, Slate & Consecrated Silver Pen', quantity: '1 Set', category: 'Utensils', price: 200, icon: '📜'),
        SamagriItem(id: 'prm_sw_white_lotus_set', name: 'Fresh White Lotus Flowers (5 Pcs) & Yellow Chrysanthemums', quantity: '1 Set', category: 'Flowers', price: 160, icon: '🪷'),
        SamagriItem(id: 'prm_sw_yellow_silk', name: 'Pure Yellow Silk Peeta Vastram for Goddess Saraswati', quantity: '1 Set', category: 'Dry Items', price: 130, icon: '🧣'),
        SamagriItem(id: 'prm_sw_panchamewa_honey', name: 'Royal Panchamewa Dry Fruits & Pure Raw Forest Honey', quantity: '1 Box', category: 'Dry Items', price: 150, icon: '🥜'),
        SamagriItem(id: 'prm_sw_gangotri_rose', name: 'Sealed Gangotri Gangajal Lota & Rose Water Decanter', quantity: '1 Set', category: 'Liquids', price: 140, icon: '🏺'),
        SamagriItem(id: 'prm_sw_sandal_paste', name: 'Pure Mysore Sandalwood Paste (Chandan) & Kasturi Attar', quantity: '1 Set', category: 'Dry Items', price: 110, icon: '🪵'),
      ],
    ),

    'bhoomi-puja': CeremonySamagriKit(
      ceremonyName: 'Bhoomi Puja & Foundation Blessing',
      standard: [
        SamagriItem(id: 'std_bp_vastu_shila', name: 'Vastu Purusha Shila & 5 Sacred Metals (Panchaloha) Token', quantity: '1 Set', category: 'Utensils', price: 140, icon: '🪙'),
        SamagriItem(id: 'std_bp_navadhanya_trench', name: 'Navadhanya (9 Sacred Grains) for Foundation Trench Sowing', quantity: '1 Set', category: 'Dry Items', price: 90, icon: '🌾'),
        SamagriItem(id: 'std_bp_mango_bundle', name: 'Fresh Mango & Peepal Leaves Bundle with Sacred Mauli', quantity: '1 Bundle', category: 'Flowers', price: 80, icon: '🍃'),
        SamagriItem(id: 'std_bp_earth_coconut', name: 'Consecrated Whole Sriphal Coconut for Earth Sanctification', quantity: '1 Pc', category: 'Utensils', price: 60, icon: '🥥'),
        SamagriItem(id: 'std_bp_haldi_akshat', name: 'Raw Vedic Haldi Knots, Roli Kumkum & Whole Akshat Rice', quantity: '1 Set', category: 'Dry Items', price: 60, icon: '🔴'),
        SamagriItem(id: 'std_bp_diya_camphor', name: 'Terracotta Diyas & Pure Bhimseni Camphor Tablets', quantity: '1 Set', category: 'Utensils', price: 60, icon: '🪔'),
      ],
      premium: [
        SamagriItem(id: 'prm_bp_navaratna_shila', name: 'Sacred 9-Gemstone (Navaratna) Vastu Purusha Shila Box', quantity: '1 Set', category: 'Utensils', price: 230, icon: '💎'),
        SamagriItem(id: 'prm_bp_copper_kalash', name: 'Heavy Consecrated Pure Copper Swastik Kalash with Coconut', quantity: '1 Set', category: 'Utensils', price: 190, icon: '🏺'),
        SamagriItem(id: 'prm_bp_108_bhoomi_herbs', name: '108 Sacred Herb Bhoomi Vastu Mahayajna Herbal Blend', quantity: '250g', category: 'Dry Items', price: 180, icon: '🌿'),
        SamagriItem(id: 'prm_bp_gangotri_lota', name: 'Sealed Gangotri Gangajal Brass Lota (500ml)', quantity: '500ml', category: 'Liquids', price: 150, icon: '🏺'),
        SamagriItem(id: 'prm_bp_a2_ghee_honey', name: 'Pure Desi Cow A2 Bilona Ghee & Raw Honey for Earth Oblation', quantity: '1 Set', category: 'Liquids', price: 340, icon: '🍯'),
        SamagriItem(id: 'prm_bp_sandal_sambrani', name: 'Pure Mysore Sandalwood & Sambrani Charcoal Dhoop Cups', quantity: '1 Pack', category: 'Incense', price: 80, icon: '🪵'),
      ],
    ),

    'vahana-puja': CeremonySamagriKit(
      ceremonyName: 'Vahana Puja (New Vehicle Blessing)',
      standard: [
        SamagriItem(id: 'std_vp_4_lemons', name: '4 Consecrated Ritual Lemons for Placement under 4 Tyres', quantity: '4 Pcs', category: 'Flowers', price: 70, icon: '🍋'),
        SamagriItem(id: 'std_vp_ribbon_garlands', name: 'Red & Yellow Ribbon Garlands for Front Grill & Bonnet', quantity: '1 Set', category: 'Flowers', price: 90, icon: '🎗️'),
        SamagriItem(id: 'std_vp_swastik_stencil', name: 'Swastik Kumkum, Sindoor & Kasturi Haldi Stencil Kit', quantity: '1 Set', category: 'Dry Items', price: 80, icon: '🔴'),
        SamagriItem(id: 'std_vp_break_coconut', name: 'Consecrated Whole Coconut for Vehicle Ground Breaking', quantity: '1 Pc', category: 'Utensils', price: 60, icon: '🥥'),
        SamagriItem(id: 'std_vp_camphor_aarti', name: 'Heavy Camphor Aarti Stand for Vehicle Aarti & Wicks', quantity: '1 Set', category: 'Utensils', price: 80, icon: '🕯️'),
        SamagriItem(id: 'std_vp_sweet_prasad', name: 'Organic Jaggery & Sweet Sugar Candies for Driver Prasad', quantity: '1 Pack', category: 'Dry Items', price: 60, icon: '🍯'),
      ],
      premium: [
        SamagriItem(id: 'prm_vp_ganesha_yantra', name: 'Gold-Plated Lord Ganesha Raksha Yantra for Dashboard', quantity: '1 Set', category: 'Utensils', price: 190, icon: '🪙'),
        SamagriItem(id: 'prm_vp_bonnet_garlands', name: 'Fresh Yellow Marigold & Rose Bonnet Garland Set (Custom Size)', quantity: '1 Set', category: 'Flowers', price: 180, icon: '🌼'),
        SamagriItem(id: 'prm_vp_8_lemons_kalava', name: '8 Consecrated Ritual Lemons & Sacred Kalava Ribbon Spool', quantity: '1 Set', category: 'Flowers', price: 110, icon: '🍋'),
        SamagriItem(id: 'prm_vp_ganga_sprinkler', name: 'Gangotri Gangajal Holy Water Sprinkler & Mysore Chandan Paste', quantity: '1 Set', category: 'Liquids', price: 150, icon: '🏺'),
        SamagriItem(id: 'prm_vp_sriphal_mauli', name: 'Whole Consecrated Sriphal Coconut with Sacred Mauli & Elaichi', quantity: '1 Pc', category: 'Utensils', price: 70, icon: '🥥'),
        SamagriItem(id: 'prm_vp_loban_cups', name: 'Natural Benzoin Loban Dhoop Cups for Cabin Smoke Purification', quantity: '1 Pack', category: 'Incense', price: 70, icon: '💨'),
      ],
    ),

    'namakaranam': CeremonySamagriKit(
      ceremonyName: 'Namakaranam & Annaprashana Samskara',
      standard: [
        SamagriItem(id: 'std_nk_honey_spoon', name: 'Pure Raw Forest Honey & Brass Achamani Spoon for Jatakarma', quantity: '1 Set', category: 'Liquids', price: 120, icon: '🍯'),
        SamagriItem(id: 'std_nk_akshat_name_tray', name: 'Sacred Whole Grain Akshat Rice Tray for Writing Baby Name', quantity: '1 Set', category: 'Dry Items', price: 90, icon: '🌾'),
        SamagriItem(id: 'std_nk_haldi_sutra', name: 'Kasturi Turmeric, Kumkum & Consecrated Raksha Sutra Thread', quantity: '1 Set', category: 'Dry Items', price: 70, icon: '💛'),
        SamagriItem(id: 'std_nk_betel_coconut', name: 'Fresh Green Betel Leaves & Whole Consecrated Coconut', quantity: '1 Set', category: 'Flowers', price: 80, icon: '🥥'),
        SamagriItem(id: 'std_nk_diyas_camphor', name: 'Mitti Diyas & Bhimseni Camphor Tablets Set', quantity: '1 Set', category: 'Utensils', price: 60, icon: '🪔'),
        SamagriItem(id: 'std_nk_milk_katori', name: 'Desi Cow Milk & Katori Mix for Annaprashanam', quantity: '1 Set', category: 'Liquids', price: 70, icon: '🥛'),
      ],
      premium: [
        SamagriItem(id: 'prm_nk_silver_spoon_coin', name: 'Consecrated Pure Silver Baby Feeding Spoon & Name Coin', quantity: '1 Set', category: 'Utensils', price: 210, icon: '🪙'),
        SamagriItem(id: 'prm_nk_silk_vastram', name: 'Sacred Baby Pure Silk Vastram & Sankalpa Blanket Pack', quantity: '1 Set', category: 'Dry Items', price: 170, icon: '🧣'),
        SamagriItem(id: 'prm_nk_petals_lotus', name: 'Fresh Fragrant Rose Petals Basket & White Lotus Flower', quantity: '1 Set', category: 'Flowers', price: 140, icon: '🌸'),
        SamagriItem(id: 'prm_nk_gangotri_lota', name: 'Sealed Gangotri Gangajal Brass Lota (500ml)', quantity: '500ml', category: 'Liquids', price: 150, icon: '🏺'),
        SamagriItem(id: 'prm_nk_sandal_rosewater', name: 'Pure Mysore Sandalwood Paste & Sugandhi Rose Water', quantity: '1 Set', category: 'Dry Items', price: 120, icon: '🪵'),
        SamagriItem(id: 'prm_nk_panchamewa_box', name: 'Royal Panchamewa Dry Fruits & Honey Sweet Prasad Box', quantity: '1 Box', category: 'Dry Items', price: 140, icon: '🥜'),
      ],
    ),

    'vinayaka-chavithi': CeremonySamagriKit(
      ceremonyName: 'Sri Vinayaka Chavithi (Ganesh Chaturthi Vratam)',
      standard: [
        SamagriItem(id: 'std_vc_21_patri', name: '21 Sacred Herbal Leaves (Eka Vimsathi Patri for Ganesha)', quantity: '21 Patri Set', category: 'Flowers', price: 90, icon: '🌿'),
        SamagriItem(id: 'std_vc_modak_naivedya', name: 'Consecrated Modaks, Kudumulu & Undrallu Naivedyam Kit', quantity: '1 Set', category: 'Dry Items', price: 120, icon: '🌾'),
        SamagriItem(id: 'std_vc_moduga_samidha', name: 'Palash / Moduga Sacred Samidha Wood Sticks', quantity: '1 Bundle', category: 'Herbs', price: 80, icon: '🪵'),
        SamagriItem(id: 'std_vc_sindoor_haldi', name: 'Orange Ganesha Sindoor, Kasturi Haldi & Akshat Pack', quantity: '1 Set', category: 'Dry Items', price: 60, icon: '🔴'),
        SamagriItem(id: 'std_vc_mango_coconut', name: 'Consecrated Whole Coconut & Fresh Mango Leaves Toran', quantity: '1 Set', category: 'Flowers', price: 80, icon: '🥥'),
        SamagriItem(id: 'std_vc_diyas_camphor', name: 'Terracotta Mitti Diyas & Bhimseni Camphor Set', quantity: '1 Set', category: 'Utensils', price: 60, icon: '🪔'),
      ],
      premium: [
        SamagriItem(id: 'prm_vc_hibiscus_garland', name: '21 Fresh Red Hibiscus (Jaswand) & Fragrant Rose Garland', quantity: '1 Set', category: 'Flowers', price: 150, icon: '🌺'),
        SamagriItem(id: 'prm_vc_ganesha_yantra', name: 'Gold-Plated Sri Maha Ganapathi Yantra Token & Janeu', quantity: '1 Set', category: 'Utensils', price: 160, icon: '🪙'),
        SamagriItem(id: 'prm_vc_108_vratam_herbs', name: '108 Herb Ganesha Chaturthi Vratam Special Hawan Blend', quantity: '250g', category: 'Dry Items', price: 180, icon: '🌿'),
        SamagriItem(id: 'prm_vc_gangotri_rose', name: 'Sealed Gangotri Gangajal Brass Lota & Rose Water', quantity: '1 Set', category: 'Liquids', price: 140, icon: '🏺'),
        SamagriItem(id: 'prm_vc_a2_ghee_honey', name: 'Pure Gir Cow A2 Bilona Ghee & Raw Forest Honey Set', quantity: '1 Set', category: 'Liquids', price: 340, icon: '🍯'),
        SamagriItem(id: 'prm_vc_panchamewa_box', name: 'Royal Panchamewa Dry Fruits & Organic Jaggery Box', quantity: '1 Box', category: 'Dry Items', price: 140, icon: '🥜'),
      ],
    ),

    'varalakshmi-vratam': CeremonySamagriKit(
      ceremonyName: 'Sri Varalakshmi Vratam',
      standard: [
        SamagriItem(id: 'std_vl_toram_thread', name: 'Sacred 9-Knot Yellow Toram Thread Set (9 Pcs for Women)', quantity: '9 Pcs Set', category: 'Dry Items', price: 80, icon: '🧶'),
        SamagriItem(id: 'std_vl_katha_pothi', name: 'Sri Varalakshmi Vrata Katha Pothi & Puja Vidhi Dravyam', quantity: '1 Set', category: 'Dry Items', price: 100, icon: '📜'),
        SamagriItem(id: 'std_vl_betel_supari', name: 'Fresh Green Betel Leaves (21 Pcs), Supari & Haldi Knots', quantity: '1 Set', category: 'Flowers', price: 70, icon: '🍃'),
        SamagriItem(id: 'std_vl_mata_shringaar', name: 'Consecrated Mata Shringaar Pack (Roli Kumkum, Bindi, Bangles)', quantity: '1 Set', category: 'Dry Items', price: 80, icon: '🔴'),
        SamagriItem(id: 'std_vl_kalash_coconut', name: 'Consecrated Whole Coconut with Mango Leaves for Kalash Sthapana', quantity: '1 Set', category: 'Utensils', price: 80, icon: '🥥'),
        SamagriItem(id: 'std_vl_ghee_panchamrit', name: 'Pure Desi Cow Ghee for Deepam & Panchamrit Mix', quantity: '1 Set', category: 'Liquids', price: 130, icon: '🥛'),
      ],
      premium: [
        SamagriItem(id: 'prm_vl_face_mask', name: 'Golden Goddess Varalakshmi Mukhavadana Face Plate Mask', quantity: '1 Set', category: 'Utensils', price: 220, icon: '🪙'),
        SamagriItem(id: 'prm_vl_lotus_jasmine', name: '11 Fresh Sacred Pink Lotus Blooms & Jasmine (Mallepoolu) Garlands', quantity: '1 Set', category: 'Flowers', price: 180, icon: '🪷'),
        SamagriItem(id: 'prm_vl_mini_saree', name: 'Miniature Green & Gold Silk Saree for Kalash Decoration', quantity: '1 Set', category: 'Dry Items', price: 140, icon: '🧣'),
        SamagriItem(id: 'prm_vl_panchamewa_box', name: 'Royal Panchamewa Dry Fruits Box & Pure Raw Honey', quantity: '1 Box', category: 'Dry Items', price: 150, icon: '🥜'),
        SamagriItem(id: 'prm_vl_gangotri_rose', name: 'Sealed Gangotri Gangajal Brass Lota & Mysore Rose Water', quantity: '1 Set', category: 'Liquids', price: 140, icon: '🏺'),
        SamagriItem(id: 'prm_vl_sandal_dhoop', name: 'Pure Mysore Sandalwood Paste (Chandan) & Kasturi Dhoop', quantity: '1 Set', category: 'Incense', price: 90, icon: '🪵'),
      ],
    ),

    'deepavali-lakshmi': CeremonySamagriKit(
      ceremonyName: 'Deepavali Maha Lakshmi & Kubera Puja',
      standard: [
        SamagriItem(id: 'std_dl_kuber_coins', name: 'Consecrated Sri Lakshmi Kubera Copper Coin Set', quantity: '1 Set', category: 'Utensils', price: 110, icon: '🪙'),
        SamagriItem(id: 'std_dl_chopda_kit', name: 'Chopda Pujan Account Book Swastik & Consecrated Pen Kit', quantity: '1 Set', category: 'Dry Items', price: 90, icon: '✏️'),
        SamagriItem(id: 'std_dl_16_diyas', name: '16 Traditional Earthen Clay Diyas & Long Cotton Wicks', quantity: '1 Set', category: 'Utensils', price: 80, icon: '🪔'),
        SamagriItem(id: 'std_dl_akshat_kumkum', name: 'Consecrated Whole Grain Akshat, Kasturi Haldi & Roli Kumkum', quantity: '1 Set', category: 'Dry Items', price: 60, icon: '🔴'),
        SamagriItem(id: 'std_dl_sriphal_supari', name: 'Consecrated Sriphal Coconut & Whole Puja Supari (21 Pcs)', quantity: '1 Set', category: 'Utensils', price: 80, icon: '🥥'),
        SamagriItem(id: 'std_dl_misri_naivedya', name: 'Crystal Dhaga Misri, Organic Jaggery & Sweet Naivedyam', quantity: '1 Pack', category: 'Dry Items', price: 60, icon: '🍯'),
      ],
      premium: [
        SamagriItem(id: 'prm_dl_gold_yantra', name: 'Gold-Plated Sri Yantra & Dhanakarshana Kubera Plate', quantity: '1 Set', category: 'Utensils', price: 200, icon: '🪙'),
        SamagriItem(id: 'prm_dl_lotus_petals', name: '11 Fresh Pink Lotus Blooms & Fresh Rose Petals Basket', quantity: '1 Set', category: 'Flowers', price: 180, icon: '🪷'),
        SamagriItem(id: 'prm_dl_gomti_kauri', name: 'Consecrated Gomti Chakras (11 Pcs) & Yellow Kauri Shells', quantity: '1 Set', category: 'Dry Items', price: 100, icon: '🐚'),
        SamagriItem(id: 'prm_dl_crimson_vastram', name: 'Pure Crimson Red Silk Vastram with Golden Zari Border', quantity: '1 Set', category: 'Dry Items', price: 140, icon: '🧣'),
        SamagriItem(id: 'prm_dl_a2_ghee_deepam', name: 'Pure Gir Cow A2 Bilona Ghee (500ml) for Akhanda Deepam', quantity: '500ml', category: 'Liquids', price: 320, icon: '🍯'),
        SamagriItem(id: 'prm_dl_kasturi_loban', name: 'Royal Kasturi Sandalwood Dhoop & Benzoin Loban Cups', quantity: '1 Set', category: 'Incense', price: 80, icon: '💨'),
      ],
    ),

    'sundarakanda-hanuman': CeremonySamagriKit(
      ceremonyName: 'Sundarakanda Parayana & Hanuman Puja',
      standard: [
        SamagriItem(id: 'std_sh_sindoor_oil', name: 'Pure Consecrated Orange Sindoor & Chameli Oil for Hanuman Archana', quantity: '1 Set', category: 'Dry Items', price: 110, icon: '🔴'),
        SamagriItem(id: 'std_sh_sundarakanda_pothi', name: 'Valmiki Ramayana Sundarakanda Pothi & Stotram Dravyam', quantity: '1 Set', category: 'Dry Items', price: 120, icon: '📜'),
        SamagriItem(id: 'std_sh_betel_mala', name: 'Fresh Green Betel Leaves Garland (108 Paan Mala)', quantity: '1 Mala', category: 'Flowers', price: 100, icon: '🍃'),
        SamagriItem(id: 'std_sh_ghee_honey', name: 'Pure Desi Cow Ghee & Raw Forest Honey for Prasad', quantity: '1 Set', category: 'Liquids', price: 130, icon: '🍯'),
        SamagriItem(id: 'std_sh_coconut_raksha', name: 'Consecrated Whole Coconut for Hanuman Raksha', quantity: '1 Pc', category: 'Utensils', price: 60, icon: '🥥'),
        SamagriItem(id: 'std_sh_camphor_aarti', name: 'Clay Diyas & Heavy Camphor Aarti Stand', quantity: '1 Set', category: 'Utensils', price: 70, icon: '🕯️'),
      ],
      premium: [
        SamagriItem(id: 'prm_sh_panchamukha_yantra', name: 'Consecrated Copper Panchamukha Hanuman Yantra Plate', quantity: '1 Set', category: 'Utensils', price: 180, icon: '🪙'),
        SamagriItem(id: 'prm_sh_108_hanuman_herbs', name: '108 Herb Hanuman Vijay Homam Medicinal Hawan Blend', quantity: '250g', category: 'Dry Items', price: 180, icon: '🌿'),
        SamagriItem(id: 'prm_sh_vadamala_hibiscus', name: 'Fresh Red Hibiscus, Marigold Mala & 108 Vadamala Kit', quantity: '1 Set', category: 'Flowers', price: 160, icon: '🌺'),
        SamagriItem(id: 'prm_sh_gangotri_lota', name: 'Sealed Gangotri Gangajal Brass Lota (500ml)', quantity: '500ml', category: 'Liquids', price: 150, icon: '🏺'),
        SamagriItem(id: 'prm_sh_panchamewa_ladoo', name: 'Royal Panchamewa Dry Fruits & Jaggery Ladoo Prasad Box', quantity: '1 Box', category: 'Dry Items', price: 140, icon: '🥜'),
        SamagriItem(id: 'prm_sh_guggul_loban', name: 'Pure Himalayan Guggul & Natural Benzoin Loban Resin', quantity: '1 Set', category: 'Incense', price: 80, icon: '💨'),
      ],
    ),

    'subrahmanya-sashti': CeremonySamagriKit(
      ceremonyName: 'Sri Subrahmanya / Skanda Sashti Homam',
      standard: [
        SamagriItem(id: 'std_ss_sarpa_herbs', name: 'Sarpa Suktam & Skanda Sashti Hawan Herb Dravyam (150g)', quantity: '150g', category: 'Herbs', price: 130, icon: '🌿'),
        SamagriItem(id: 'std_ss_red_flowers', name: 'Fresh Red Oleander (Karaveera) & Red Hibiscus Flowers', quantity: '1 Set', category: 'Flowers', price: 90, icon: '🌺'),
        SamagriItem(id: 'std_ss_khadira_samidha', name: 'Khadira & Palash Sacred Samidha Wood Sticks Bundle', quantity: '1 Bundle', category: 'Herbs', price: 80, icon: '🪵'),
        SamagriItem(id: 'std_ss_kumkum_sutra', name: 'Consecrated Vermilion Kumkum, Haldi & Raksha Sutra', quantity: '1 Set', category: 'Dry Items', price: 60, icon: '🔴'),
        SamagriItem(id: 'std_ss_til_ghee', name: 'Pure Gingelly Sesame Oil (Til Tel) & Desi Cow Ghee', quantity: '1 Set', category: 'Liquids', price: 130, icon: '🫙'),
        SamagriItem(id: 'std_ss_bali_coconut', name: 'Whole Consecrated Coconut for Naga Shanti Bali', quantity: '1 Pc', category: 'Utensils', price: 60, icon: '🥥'),
      ],
      premium: [
        SamagriItem(id: 'prm_ss_naga_yantra', name: 'Consecrated Copper Subrahmanya / Naga Dosha Shanti Yantra', quantity: '1 Set', category: 'Utensils', price: 180, icon: '🪙'),
        SamagriItem(id: 'prm_ss_108_skanda_herbs', name: '108 Rare Herb Skanda Sashti Mahayajna Dravyam Blend', quantity: '250g', category: 'Dry Items', price: 200, icon: '🌿'),
        SamagriItem(id: 'prm_ss_gangotri_rose', name: 'Sealed Gangotri Gangajal Brass Lota & Rose Water Decanter', quantity: '1 Set', category: 'Liquids', price: 140, icon: '🏺'),
        SamagriItem(id: 'prm_ss_a2_ghee_honey', name: 'Pure A2 Desi Cow Ghee & Raw Honey for Maha Ahuti', quantity: '1 Set', category: 'Liquids', price: 340, icon: '🍯'),
        SamagriItem(id: 'prm_ss_panchamewa_charu', name: 'Royal Panchamewa Dry Fruits Box & Charu Oblation Mix', quantity: '1 Set', category: 'Dry Items', price: 150, icon: '🥜'),
        SamagriItem(id: 'prm_ss_sandal_loban', name: 'Pure Mysore Sandalwood Chandan & Loban Dhoop Cones', quantity: '1 Pack', category: 'Incense', price: 80, icon: '🪵'),
      ],
    ),

    _fallbackKey: CeremonySamagriKit(
      ceremonyName: 'Vedic Ceremony',
      standard: [
        SamagriItem(id: 'std_def_hawan_mix', name: 'Vedic Hawan Samagri 108 Herb Mix (150g)', quantity: '150g', category: 'Dry Items', price: 110, icon: '🌿'),
        SamagriItem(id: 'std_def_kumkum_haldi', name: 'Roli Kumkum, Kasturi Haldi, Janeu & Akshat Pack', quantity: '1 Set', category: 'Dry Items', price: 80, icon: '🔴'),
        SamagriItem(id: 'std_def_betel_coconut', name: 'Fresh Betel Leaves, Supari Nuts & Consecrated Coconut', quantity: '1 Set', category: 'Flowers', price: 80, icon: '🥥'),
        SamagriItem(id: 'std_def_ghee_deepam', name: 'Pure Desi Cow Ghee for Sacred Deepam & Ahuti (250ml)', quantity: '250ml', category: 'Liquids', price: 160, icon: '🍯'),
        SamagriItem(id: 'std_def_diyas_camphor', name: 'Terracotta Clay Diyas, Cotton Wicks & Pure Camphor', quantity: '1 Set', category: 'Utensils', price: 70, icon: '🪔'),
      ],
      premium: [
        SamagriItem(id: 'prm_def_108_herbs', name: '108 Sacred Herb Special Vedic Hawan Samagri Mix (250g)', quantity: '250g', category: 'Dry Items', price: 180, icon: '🌿'),
        SamagriItem(id: 'prm_def_copper_kalash', name: 'Consecrated Pure Copper Kalash with Coconut & Mango Leaves', quantity: '1 Set', category: 'Utensils', price: 180, icon: '🏺'),
        SamagriItem(id: 'prm_def_gangotri_lota', name: 'Sealed Gangotri Gangajal Brass Lota (500ml)', quantity: '500ml', category: 'Liquids', price: 150, icon: '🏺'),
        SamagriItem(id: 'prm_def_a2_ghee', name: 'Pure Desi Cow A2 Organic Bilona Ghee (500ml)', quantity: '500ml', category: 'Liquids', price: 320, icon: '🍯'),
        SamagriItem(id: 'prm_def_sandal_sambrani', name: 'Pure Mysore Sandalwood Chandan & Charcoal Sambrani Dhoop', quantity: '1 Set', category: 'Incense', price: 90, icon: '🪵'),
        SamagriItem(id: 'prm_def_silk_vastram', name: 'Red & Yellow Silk Peeta Vastram Cloth Set', quantity: '1 Set', category: 'Dry Items', price: 110, icon: '🧣'),
      ],
    ),
  };

  /// Lower-cased / trimmed ceremony id (web: `(ceremonyId || '').toLowerCase().trim()`).
  static String? normalizeId(String? ceremonyId) {
    final key = ceremonyId?.toLowerCase().trim();
    if (key == null || key.isEmpty) return null;
    return key;
  }

  /// Slugifies a ceremony id/name the way the production web kit resolver
  /// does (`replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '')`).
  static String _slug(String value) => value
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  /// Resolves a kit by the ceremony's display title (API `title` / web
  /// `ceremonyName`). Production web `getCeremonyKitItems` matches the
  /// slugified title against each mapping key and `ceremonyName` field.
  static CeremonySamagriKit? kitByName(String? ceremonyName) {
    final slug = _slug(ceremonyName ?? '');
    if (slug.isEmpty) return null;
    for (final entry in ceremonyMapping.entries) {
      if (entry.key == _fallbackKey) continue;
      if (_slug(entry.key) == slug ||
          _slug(entry.value.ceremonyName) == slug) {
        return entry.value;
      }
    }
    return null;
  }

  /// True when the ceremony has its own explicit kit mapping (the generic
  /// `default` kit does not count — callers fall back to flat prices).
  /// Accepts an optional [ceremonyName] so API-loaded ceremonies (numeric
  /// ids) still resolve their kit by title, like the web flow.
  static bool hasCeremonyMapping(String? ceremonyId, {String? ceremonyName}) {
    final key = normalizeId(ceremonyId);
    if (key != null && key != _fallbackKey && ceremonyMapping.containsKey(key)) {
      return true;
    }
    return kitByName(ceremonyName) != null;
  }

  static CeremonySamagriKit kitFor(String? ceremonyId, {String? ceremonyName}) {
    final key = normalizeId(ceremonyId);
    if (key != null) {
      final kit = ceremonyMapping[key];
      if (kit != null) return kit;
    }
    final byName = kitByName(ceremonyName);
    if (byName != null) return byName;
    return ceremonyMapping[_fallbackKey]!;
  }

  /// Port of web `getCeremonyKitItems(ceremonyId, packageId)`.
  /// Returns `[]` for the `none` package and falls back to the generic
  /// default kit (then premium) exactly like the web helper.
  static List<SamagriItem> getCeremonyKitItems(
    String? ceremonyId, [
    String packageId = 'premium',
    String? ceremonyName,
  ]) {
    if (packageId == 'none') return const [];
    final kit = kitFor(ceremonyId, ceremonyName: ceremonyName);
    if (packageId == 'standard') return kit.standard;
    return kit.premium;
  }

  /// Port of web `calculateKitTotal(items)` — `sum(price * qty)`.
  static double calculateKitTotal(List<SamagriItem>? items) {
    if (items == null || items.isEmpty) return 0;
    var total = 0.0;
    for (final item in items) {
      total += item.price * item.qty;
    }
    return total;
  }
}
