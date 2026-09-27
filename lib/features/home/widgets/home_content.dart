import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/service_model.dart';
import '../../../services/service_api.dart';
import '../../../services/session_service.dart';

/// Scrollable home body matching the reference design board: navy header
/// (greeting, location, search, category grid) above the white
/// "Popular Services" list (PDF section 14 - Stage 3).
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<ServiceModel> _categories = <ServiceModel>[];
  List<ServiceModel> _services = <ServiceModel>[];
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
      SessionService.instance.user(),
    ]);
    if (!mounted) return;
    setState(() {
      _categories = results[0] as List<ServiceModel>;
      _services = results[1] as List<ServiceModel>;
      _name = (results[2] as dynamic)?.fullName as String?;
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
        padding: EdgeInsets.zero,
        children: <Widget>[
          _navyHeader(theme),
          _popularSection(theme),
        ],
      ),
    );
  }

  Widget _navyHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${AppStrings.greetingPrefix}${_name ?? 'Devotee'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.onDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              const Icon(Icons.place_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  AppStrings.homeLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.onDarkMuted,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: AppColors.onDarkMuted),
            ],
          ),
          const SizedBox(height: 14),
          _searchBar(theme),
          const SizedBox(height: 18),
          _categoryGrid(theme),
        ],
      ),
    );
  }

  Widget _searchBar(ThemeData theme) {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(left: 14, right: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.search_rounded, size: 21, color: AppColors.muted),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: AppStrings.searchHint,
                hintStyle: theme.textTheme.bodySmall,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => context.go('/services'),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.search_rounded,
                    size: 21, color: AppColors.onDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryGrid(ThemeData theme) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 8,
      childAspectRatio: 0.95,
      children: _categories.map<Widget>((ServiceModel category) {
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.go('/services'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.onDark.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconFor(category.icon),
                  size: 23,
                  color: AppColors.onDark,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                category.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onDark,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _popularSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      color: AppColors.cream,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  AppStrings.popularServices,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/services'),
                child: const Text(AppStrings.viewAll),
              ),
            ],
          ),
          const SizedBox(height: 2),
          ..._services.map<Widget>(
            (ServiceModel service) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PopularServiceCard(
                service: service,
                onTap: () => context.go('/services'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(String? key) => switch (key) {
        'temple' => Icons.temple_buddhist_rounded,
        'fire' => Icons.local_fire_department_rounded,
        'flame' => Icons.whatshot_rounded,
        'home' => Icons.home_rounded,
        'stars' => Icons.auto_awesome_rounded,
        'rings' => Icons.favorite_rounded,
        'compass' => Icons.explore_rounded,
        'festival' => Icons.celebration_rounded,
        'grid' => Icons.grid_view_rounded,
        'book' => Icons.menu_book_rounded,
        _ => Icons.temple_buddhist_rounded,
      };
}

/// Popular service card: thumbnail, rating / duration / languages,
/// price and an orange "Book Now" action (reference design board).
class _PopularServiceCard extends StatelessWidget {
  const _PopularServiceCard({required this.service, required this.onTap});

  final ServiceModel service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _HomeContentState._iconFor(service.icon),
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      service.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.star_rounded,
                            size: 15, color: AppColors.gold),
                        const SizedBox(width: 3),
                        Text(
                          service.rating.toStringAsFixed(1),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (service.duration != null) ...<Widget>[
                          const SizedBox(width: 10),
                          const Icon(Icons.schedule_rounded,
                              size: 14, color: AppColors.muted),
                          const SizedBox(width: 3),
                          Text(
                            service.duration!,
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.language_rounded,
                            size: 14, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            service.languagesLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            service.priceLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 0),
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onDark,
                            textStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: const Text(AppStrings.bookNow),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
