import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/catalogue_data.dart';
import '../../models/ceremony.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/profile_provider.dart';
import '../auth/login_screen.dart';
import '../booking/booking_flow_screen.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

class PujaDetailsScreen extends StatefulWidget {
  const PujaDetailsScreen({super.key, required this.ceremony});

  final Ceremony ceremony;

  @override
  State<PujaDetailsScreen> createState() => _PujaDetailsScreenState();
}

class _PujaDetailsScreenState extends State<PujaDetailsScreen> {
  String _samagriId = 'premium';

  Future<void> _book(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      final goLogin = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Sign in required'),
          content: const Text('Please sign in to book this ceremony.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Sign In',
                style: TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
      );
      if (goLogin != true || !context.mounted) return;
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (!context.mounted) return;
      if (!context.read<AuthProvider>().isLoggedIn) return;
    }

    final bookings = context.read<BookingProvider>();
    final profile = context.read<ProfileProvider>();
    bookings.resetDraft(
      devoteeName:
          profile.profile?.fullName ??
          context.read<AuthProvider>().session?.name,
      mobile:
          profile.profile?.phonenumber ??
          context.read<AuthProvider>().session?.phone,
      email:
          profile.profile?.email ?? context.read<AuthProvider>().session?.email,
      address: profile.profile?.address,
      city: profile.profile?.city,
      state: profile.profile?.state,
      gothram: profile.profile?.gotra,
      nakshatra: profile.profile?.nakshatra,
      rashi: profile.profile?.rashi,
    );
    bookings.selectCeremony(widget.ceremony);
    bookings.selectSamagri(
      CeremonyCatalogue.samagriPackages.firstWhere(
        (p) => p.id == _samagriId,
        orElse: () => CeremonyCatalogue.samagriPackages.first,
      ),
    );
    bookings.setStep(2);
    if (!context.mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const BookingFlowScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: const [DashboardActionButton()],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CeremonyImage(
                    assetPath: widget.ceremony.image,
                    emoji: '🪔',
                    height: 230,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC021F2C)],
                        stops: [0.4, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            StatusBadge(
                              label: widget.ceremony.category,
                              color: AppColors.gold,
                              dense: true,
                            ),
                            if (widget.ceremony.hasOfferPrice &&
                                widget.ceremony.discountPct > 0) ...[
                              const SizedBox(width: 8),
                              StatusBadge(
                                label: '${widget.ceremony.discountPct}% OFF',
                                color: AppColors.danger,
                                dense: true,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.ceremony.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _metaTile(
                          Icons.timer_outlined,
                          widget.ceremony.duration,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _metaTile(
                          Icons.person_outline,
                          widget.ceremony.panditType,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'About this ceremony',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.ceremony.description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textMuted,
                      height: 1.6,
                    ),
                  ),
                  if (widget.ceremony.hasOfferPrice) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.local_offer_outlined,
                                size: 16,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.ceremony.offerTitle ??
                                      'Limited Time Offer',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.successDark,
                                  ),
                                ),
                              ),
                              Text(
                                'Save ${Fmt.inr(widget.ceremony.savings)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.successDark,
                                ),
                              ),
                            ],
                          ),
                          if (widget.ceremony.offerDescription != null &&
                              widget.ceremony.offerDescription!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              widget.ceremony.offerDescription!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                                height: 1.5,
                              ),
                            ),
                          ],
                          if (widget.ceremony.offerValidTill != null &&
                              widget
                                  .ceremony
                                  .offerValidTill!
                                  .trim()
                                  .isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Valid till ${_formatOfferValidTill(widget.ceremony.offerValidTill!)}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  const Text(
                    'Eco-Samagri Options',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...CeremonyCatalogue.samagriPackages.map((p) {
                    final selected = p.id == _samagriId;
                    final kitPrice = CeremonyCatalogue.samagriKitPrice(
                      ceremonyId: widget.ceremony.id,
                      packageId: p.id,
                      ceremonyName: widget.ceremony.name,
                    );
                    final kitCount = CeremonyCatalogue.samagriKitItems(
                      ceremonyId: widget.ceremony.id,
                      packageId: p.id,
                      ceremonyName: widget.ceremony.name,
                    ).length;
                    return GestureDetector(
                      key: ValueKey<String>('samagri-${p.id}'),
                      onTap: () => setState(() => _samagriId = p.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accentLight
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppColors.accent
                                : AppColors.border,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.border,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              p.id == 'none'
                                  ? Icons.shopping_bag_outlined
                                  : Icons.inventory_2_outlined,
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    p.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Fmt.inr(kitPrice),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.accent,
                                  ),
                                ),
                                if (kitCount > 0)
                                  Text(
                                    '$kitCount Sacred Items',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STARTING FROM',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.textMuted,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      widget.ceremony.priceFormatted,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (widget.ceremony.hasOfferPrice) ...[
                      const SizedBox(width: 6),
                      Text(
                        widget.ceremony.originalPriceFormatted,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.ceremony.hasOfferPrice)
                  Text(
                    'You save ${Fmt.inr(widget.ceremony.savings)}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppButton(
                label: 'Book This Puja',
                onPressed: () => _book(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaTile(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats the API's `offer_valid_till` (e.g. `2026-11-20T23:59:00`) as
  /// `20 Nov 2026`. Falls back to the raw string when unparsable.
  static String _formatOfferValidTill(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
