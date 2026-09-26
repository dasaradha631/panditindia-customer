import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/booking_card.dart';
import '../../../core/widgets/pandit_card.dart';
import '../../../core/widgets/service_card.dart';
import '../../../models/booking_model.dart';
import '../../../models/pandit_model.dart';
import '../../../models/service_model.dart';
import '../../../services/booking_api.dart';
import '../../../services/pandit_api.dart';
import '../../../services/service_api.dart';
import '../../../services/session_service.dart';

/// Scrollable home body: greeting, location, hero, categories, featured
/// services, featured pandits and promotions (PDF section 14 - Stage 3).
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<ServiceModel> _categories = <ServiceModel>[];
  List<ServiceModel> _services = <ServiceModel>[];
  List<PanditModel> _pandits = <PanditModel>[];
  List<BookingModel> _upcoming = <BookingModel>[];
  List<BookingModel> _past = <BookingModel>[];
  bool _loading = true;
  String? _name;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final List<Object?> results = await Future.wait<Object?>(<Future<Object?>>[
      ServiceApi().categories(),
      ServiceApi().featured(),
      PanditApi().featured(),
      BookingApi().upcoming(),
      BookingApi().past(),
      SessionService.instance.user(),
    ]);
    if (!mounted) return;
    setState(() {
      _categories = results[0] as List<ServiceModel>;
      _services = results[1] as List<ServiceModel>;
      _pandits = results[2] as List<PanditModel>;
      _upcoming = results[3] as List<BookingModel>;
      _past = results[4] as List<BookingModel>;
      _name = (results[5] as dynamic)?.fullName as String?;
      _loading = false;
    });
  }

  Future<void> _refresh() => _load();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
        children: <Widget>[
          _greeting(theme),
          const SizedBox(height: 16),
          _heroBanner(theme),
          const SizedBox(height: 20),
          _sectionHeader(theme, AppStrings.upcomingBookings, onAction: null),
          const SizedBox(height: 10),
          if (_upcoming.isEmpty)
            _emptyUpcoming(theme)
          else
            BookingCard(booking: _upcoming.first, onTap: () => context.go('/bookings')),
          const SizedBox(height: 22),
          _sectionHeader(theme, AppStrings.serviceCategories),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (BuildContext context, int index) {
                final ServiceModel category = _categories[index];
                return _CategoryTile(
                  category: category,
                  onTap: () => context.go('/services'),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          _sectionHeader(theme, AppStrings.featuredServices,
              actionLabel: AppStrings.viewAll,
              onAction: () => context.go('/services')),
          const SizedBox(height: 12),
          SizedBox(
            height: 216,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _services.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (BuildContext context, int index) {
                return SizedBox(
                  width: 196,
                  child: ServiceCard(
                    service: _services[index],
                    onTap: () => context.go('/services'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          _sectionHeader(theme, AppStrings.featuredPandits,
              actionLabel: AppStrings.viewAll,
              onAction: () => context.go('/pandits')),
          const SizedBox(height: 12),
          ..._pandits.map<Widget>(
            (PanditModel pandit) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PanditCard(
                pandit: pandit,
                onTap: () => context.go('/pandits'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _sectionHeader(theme, AppStrings.promotions),
          const SizedBox(height: 12),
          SizedBox(
            height: 132,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const <Widget>[
                _PromoCard(
                  title: 'Flat 15% off',
                  subtitle: 'On your first puja booking',
                  tag: 'WELCOME15',
                  gradient: AppColors.brandGradient,
                ),
                SizedBox(width: 12),
                _PromoCard(
                  title: 'Free sankalp',
                  subtitle: 'With every Satyanarayan puja',
                  tag: 'VEDIC2026',
                  gradient: AppColors.accentGradient,
                ),
              ],
            ),
          ),
          if (_past.isNotEmpty) ...<Widget>[
            const SizedBox(height: 22),
            _sectionHeader(theme, AppStrings.bookAgain),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _past
                  .map<Widget>(
                    (BookingModel booking) => ActionChip(
                      avatar: const Icon(Icons.replay_rounded,
                          size: 16, color: AppColors.primary),
                      label: Text(booking.serviceTitle),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                      onPressed: () => context.go('/services'),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _greeting(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
            ),
            child: Text(
              ((_name ?? 'D').trim().isEmpty ? 'D' : (_name ?? 'D').trim())
                  .substring(0, 1)
                  .toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.onDark,
                fontWeight: FontWeight.w700,
                fontSize: 19,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${AppStrings.greetingPrefix}${_name ?? 'Devotee'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Row(
                  children: <Widget>[
                    const Icon(Icons.place_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        AppStrings.homeLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Change location',
            onPressed: () {},
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _heroBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Book authentic Vedic pujas\nat your doorstep',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onDark,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Verified pandits • Secure booking',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.onDarkMuted,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => context.go('/services'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onDark,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  child: const Text(AppStrings.bookPujaNow),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.onDark.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.temple_buddhist_rounded,
              size: 44,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    ThemeData theme,
    String title, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(title, style: theme.textTheme.titleMedium),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
      ],
    );
  }

  Widget _emptyUpcoming(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Column(
        children: <Widget>[
          const Icon(Icons.event_busy_rounded,
              size: 34, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(AppStrings.noUpcomingTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            AppStrings.noUpcomingSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => context.go('/services'),
            icon: const Icon(Icons.search_rounded, size: 17),
            label: const Text('Explore services'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              backgroundColor: AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final ServiceModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 92,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.temple_buddhist_rounded,
                  size: 19, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              category.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.gradient,
  });

  final String title;
  final String subtitle;
  final String tag;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: 252,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.onDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onDarkMuted,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.onDark.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.onDark.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              tag,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.onDark,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
