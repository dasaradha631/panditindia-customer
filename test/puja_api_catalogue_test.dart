import 'package:flutter_test/flutter_test.dart';

import 'package:customer_app/models/catalogue_data.dart';
import 'package:customer_app/models/ceremony.dart';
import 'package:customer_app/models/ceremony_samagri_data.dart';
import 'package:customer_app/providers/booking_provider.dart';

/// Rows captured from the production `GET https://api.panditindia.com/pujas`
/// feed — the same payload the web booking page maps (`title`, `current_price`,
/// `original_price`, `discount_pct`, `offer_active`, ...).
void main() {
  Map<String, dynamic> satyanarayanaRow() => <String, dynamic>{
    'id': 6,
    'title': 'Sri Satyanarayana Swamy Vratam',
    'category': 'Festive Puja',
    'description': 'Sri Satyanarayana Swamy Vratam is a traditional ceremony.',
    'image_url': 'https://www.panditindia.com/assets/images/satyanarayana-spotlight.webp',
    'badge_label': 'Most Popular',
    'duration_min': 2,
    'duration_max': 3,
    'original_price': 4100,
    'discount_price': 3098,
    'discount_pct': 24,
    'offer_type': 'SPECIAL',
    'offer_title': 'Satyanarayana Swamy Vratam Special',
    'offer_description': 'Perform the sacred vratam with traditional rituals.',
    'offer_valid_till': '2026-11-20T23:59:00',
    'is_active': 1,
    'offer_active': true,
    'current_price': 3098,
  };

  Map<String, dynamic> grihaPraveshRow() => <String, dynamic>{
    'id': 5,
    'title': 'Griha Pravesh & Vastu Shanti',
    'category': 'Griha Pravesh',
    'description': 'Auspicious Vedic housewarming ceremony.',
    'image_url': 'https://www.panditindia.com/assets/images/griha-pravesh-natural.webp',
    'badge_label': 'Most Popular',
    'duration_min': 2,
    'duration_max': 3,
    'original_price': 5100,
    'discount_price': 5100,
    'discount_pct': 0,
    'is_active': 1,
    'offer_active': false,
    'current_price': 5100,
  };

  group('Ceremony.fromJson (GET /pujas mapper)', () {
    test('maps a discounted row like the web puja mapper', () {
      final c = Ceremony.fromJson(satyanarayanaRow());
      expect(c.id, '6');
      expect(c.name, 'Sri Satyanarayana Swamy Vratam');
      expect(c.category, 'Festive Puja');
      expect(c.price, 3098);
      expect(c.priceFormatted, '₹3,098');
      expect(c.originalPrice, 4100);
      expect(c.originalPriceFormatted, '₹4,100');
      expect(c.discountPct, 24);
      expect(c.offerActive, isTrue);
      expect(c.hasOfferPrice, isTrue);
      expect(c.savings, 1002);
      expect(c.duration, '2 - 3 Hours');
      expect(c.image, startsWith('https://'));
      expect(c.badgeLabel, 'Most Popular');
      expect(c.offerTitle, 'Satyanarayana Swamy Vratam Special');
      expect(c.offerValidTill, '2026-11-20T23:59:00');
      expect(c.popular, isTrue);
    });

    test('rows without a live offer show no strikethrough price', () {
      final c = Ceremony.fromJson(grihaPraveshRow());
      expect(c.price, 5100);
      expect(c.originalPrice, 5100);
      expect(c.offerActive, isFalse);
      expect(c.hasOfferPrice, isFalse);
      expect(c.savings, 0);
      expect(c.discountPct, 0);
    });
  });

  group('name-based Eco-Samagri kit lookup', () {
    test('API numeric ids resolve the kit by ceremony title', () {
      final c = Ceremony.fromJson(satyanarayanaRow());
      expect(CeremonySamagriData.hasCeremonyMapping(c.id, ceremonyName: c.name), isTrue);
      final premium = CeremonyCatalogue.samagriKitPrice(
        ceremonyId: c.id,
        packageId: 'premium',
        ceremonyName: c.name,
      );
      final defaultPremium = CeremonyCatalogue.flatSamagriPrice('premium');
      expect(premium, greaterThan(0));
      // The ceremony-specific kit must be its own mapped total, not the
      // flat ₹800 package fallback.
      expect(premium, isNot(defaultPremium));
      expect(
        CeremonyCatalogue.samagriKitPrice(
          ceremonyId: c.id,
          packageId: 'none',
          ceremonyName: c.name,
        ),
        0,
      );
    });

    test('Griha Pravesh title still maps to its ₹1,050 premium kit', () {
      final c = Ceremony.fromJson(grihaPraveshRow());
      expect(
        CeremonyCatalogue.samagriKitPrice(
          ceremonyId: c.id,
          packageId: 'premium',
          ceremonyName: c.name,
        ),
        1050,
      );
    });

    test('unknown ceremonies fall back to the flat package price', () {
      expect(
        CeremonyCatalogue.samagriKitPrice(
          ceremonyId: '999',
          packageId: 'premium',
          ceremonyName: 'Some Unknown Ritual',
        ),
        CeremonyCatalogue.flatSamagriPrice('premium'),
      );
    });
  });

  group('booking draft offer pricing', () {
    test('selectCeremony records the offer original price and savings', () {
      final p = BookingProvider();
      p.selectCeremony(Ceremony.fromJson(satyanarayanaRow()));
      expect(p.draft.ceremonyId, '6');
      expect(p.draft.ceremonyPrice, 3098);
      expect(p.draft.ceremonyOriginalPrice, 4100);
      expect(p.draft.ceremonySavings, 1002);
      // Total = ceremony + premium kit + trust fee (no travel at the default
      // 4.5 km tier, pandit tier 0) — savings only affect display, not total.
      expect(
        p.draft.breakdown.total,
        3098 + p.draft.samagriPrice + p.draft.breakdown.dakshinaTrustFee,
      );
    });

    test('ceremonies without an offer store no original price', () {
      final p = BookingProvider();
      p.selectCeremony(Ceremony.fromJson(grihaPraveshRow()));
      expect(p.draft.ceremonyOriginalPrice, 0);
      expect(p.draft.ceremonySavings, 0);
    });
  });
}
