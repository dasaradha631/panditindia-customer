import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/ceremony.dart';
import '../../models/catalogue_data.dart';
import '../../providers/booking_provider.dart';
import 'puja_details_screen.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

class PujaCatalogueScreen extends StatefulWidget {
  const PujaCatalogueScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<PujaCatalogueScreen> createState() => _PujaCatalogueScreenState();
}

class _PujaCatalogueScreenState extends State<PujaCatalogueScreen> {
  late final TextEditingController _search;
  String? _category;
  bool _showPopularOnly = false;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery ?? '');
    final q = widget.initialQuery;
    if (q != null && CeremonyCatalogue.categories.contains(q)) {
      _category = q;
      _search.clear();
    }
    // Kick off the production `GET /pujas` load (falls back to the baked-in
    // catalogue when the API is unreachable) — mirrors the web booking page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().ensureCeremoniesLoaded();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Ceremony> _resultsOf(List<Ceremony> source) {
    final query = _search.text.trim().toLowerCase();
    return source.where((c) {
      final matchesQuery =
          query.isEmpty ||
          c.name.toLowerCase().contains(query) ||
          c.category.toLowerCase().contains(query) ||
          c.description.toLowerCase().contains(query);
      final matchesCategory = _category == null || c.category == _category;
      final matchesPopular = !_showPopularOnly || c.popular;
      return matchesQuery && matchesCategory && matchesPopular;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final results = _resultsOf(booking.ceremonies);
    final categories = CeremonyCatalogue.categoriesOf(booking.ceremonies);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const GradientAppBar(
        title: 'Puja Services',
        actions: [DashboardActionButton()],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search ceremony, festival or category...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                    ),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _filterChip(null, 'All'),
                      _filterChip('__popular__', '★ Popular'),
                      ...categories.map((c) => _filterChip(c, c)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: booking.loadingCeremonies && booking.ceremonies.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                    ),
                  )
                : results.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No ceremonies found',
                    subtitle: booking.loadingCeremonies
                        ? 'Refreshing the puja catalogue…'
                        : 'Try a different search term or category.',
                    actionLabel: booking.usedCeremoniesFallback
                        ? 'Retry'
                        : null,
                    onAction: booking.usedCeremoniesFallback
                        ? () => booking.ensureCeremoniesLoaded(force: true)
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _CeremonyRow(
                      ceremony: results[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PujaDetailsScreen(ceremony: results[i]),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String? value, String label) {
    final selected = value == '__popular__'
        ? _showPopularOnly
        : (_category == value && value != '__popular__');
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        selected: selected,
        onSelected: (v) {
          setState(() {
            if (value == '__popular__') {
              _showPopularOnly = v;
              if (v) _category = null;
            } else {
              _category = v ? value : null;
              if (v) _showPopularOnly = false;
            }
          });
        },
        selectedColor: AppColors.accent,
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textDark,
        ),
        side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
      ),
    );
  }
}

class _CeremonyRow extends StatelessWidget {
  const _CeremonyRow({required this.ceremony, required this.onTap});

  final Ceremony ceremony;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CeremonyImage(
              assetPath: ceremony.image,
              emoji: '🪔',
              height: 76,
              width: 76,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ceremony.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ceremony.category} • ${ceremony.duration}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        ceremony.priceFormatted,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accent,
                        ),
                      ),
                      if (ceremony.hasOfferPrice) ...[
                        const SizedBox(width: 6),
                        Text(
                          ceremony.originalPriceFormatted,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (ceremony.hasOfferPrice && ceremony.discountPct > 0)
                        StatusBadge(
                          label: '${ceremony.discountPct}% OFF',
                          color: AppColors.danger,
                          dense: true,
                        )
                      else if (ceremony.badgeLabel != null &&
                          ceremony.badgeLabel!.isNotEmpty)
                        StatusBadge(
                          label: ceremony.badgeLabel!,
                          color: AppColors.warning,
                          dense: true,
                        ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
