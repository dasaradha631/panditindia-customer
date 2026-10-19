import 'package:flutter/material.dart' hide Text;

import '../../core/l10n/localized_text.dart';
import '../../core/theme/app_theme.dart';
import '../../models/ceremony_samagri_data.dart';

/// Emerald palette shared by the kit sheets (web `StepSamagri` modals).
const Color kKitGreen = Color(0xFF059669);
const Color kKitGreenDark = Color(0xFF064E3B);
const Color kKitGreenDeep = Color(0xFF065F46);
const Color kKitMint = Color(0xFFF0FDF4);
const Color kKitMintBorder = Color(0xFFA7F3D0);
const Color kKitMintChip = Color(0xFFD1FAE5);

/// Itemized cost breakdown modal for one Eco-Samagri kit (web parity with
/// the `StepSamagri` "Cost Breakdown" dialog — Image 2): category-wise
/// totals, the full per-item unit-price table and the live Total Kit
/// Dakshina. Pass the *effective* kit (customized cart when the package is
/// selected and edited, otherwise the ceremony default).
class SamagriCostBreakdownSheet extends StatelessWidget {
  const SamagriCostBreakdownSheet({
    super.key,
    required this.ceremonyName,
    required this.packageName,
    required this.items,
    required this.fallbackPrice,
    this.customized = false,
  });

  final String ceremonyName;
  final String packageName;
  final List<SamagriItem> items;
  final double fallbackPrice;
  final bool customized;

  /// Opens the breakdown as a bottom sheet.
  static Future<void> open(
    BuildContext context, {
    required String ceremonyName,
    required String packageName,
    required List<SamagriItem> items,
    required double fallbackPrice,
    bool customized = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SamagriCostBreakdownSheet(
        ceremonyName: ceremonyName,
        packageName: packageName,
        items: items,
        fallbackPrice: fallbackPrice,
        customized: customized,
      ),
    );
  }

  /// Category → summed line totals, in first-seen order.
  Map<String, double> get _categoryTotals {
    final totals = <String, double>{};
    for (final item in items) {
      totals[item.category] = (totals[item.category] ?? 0) + item.lineTotal;
    }
    return totals;
  }

  double get _total => CeremonySamagriData.calculateKitTotal(items);

  @override
  Widget build(BuildContext context) {
    final categories = _categoryTotals;
    final total = items.isEmpty ? fallbackPrice : _total;
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: ColoredBox(
          color: kKitGreenDark,
          child: Column(
            children: [
              _Header(
                title: 'Itemized Kit Cost Breakdown & Price Differentiation',
                subtitle: '$ceremonyName • $packageName${customized ? ' • Customized' : ''}',
              ),
              Expanded(
                child: ColoredBox(
                  color: kKitMint,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                    children: [
                      const _SectionLabel('CATEGORY-WISE COST SUMMARY'),
                      const SizedBox(height: 8),
                      if (items.isEmpty)
                        const Text(
                          'Itemized pricing for this ceremony follows the standard '
                          'package rate. The Acharya shares the itemised list after '
                          'the kit is sealed & dispatched.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final entry in categories.entries)
                              _CategoryChip(
                                label: entry.key,
                                total: entry.value,
                              ),
                          ],
                        ),
                      const SizedBox(height: 18),
                      _SectionLabel(
                        'ALL ${items.length} SACRED ITEMS IN THIS KIT',
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kKitMintBorder),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    'ITEM NAME',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'PRICE',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Divider(height: 1, color: AppColors.border),
                            if (items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'No itemized rows for this kit.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              )
                            else
                              ...items.map(_itemRow),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kKitGreen),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Total Kit Dakshina',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: kKitGreenDeep,
                                    ),
                                  ),
                                ),
                                Text(
                                  Fmt.inr(total),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: kKitGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Includes all consecrated items, airtight organic '
                              'seal & doorstep dispatch.',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ColoredBox(
                color: kKitMint,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: AppColors.textDark,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 13),
                          child: Text(
                            'Close Breakdown',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemRow(SamagriItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: kKitMintChip,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: kKitGreenDeep,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${Fmt.inr(item.price)} × ${item.qty}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Fmt.inr(item.lineTotal),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: kKitGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kKitGreenDark, kKitGreenDeep],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.receipt_long_rounded, size: 20, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
        color: kKitGreenDeep,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.total});

  final String label;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kKitMintBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            Fmt.inr(total),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: kKitGreen,
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only Vedic checklist shown for the "Devotee Will Arrange Own Items"
/// package — the Acharya's verified list the devotee purchases locally.
class VedicChecklistSheet extends StatefulWidget {
  const VedicChecklistSheet({
    super.key,
    required this.ceremonyName,
    required this.itemNames,
  });

  final String ceremonyName;
  final List<String> itemNames;

  static Future<void> open(
    BuildContext context, {
    required String ceremonyName,
    required List<String> itemNames,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VedicChecklistSheet(
        ceremonyName: ceremonyName,
        itemNames: itemNames,
      ),
    );
  }

  @override
  State<VedicChecklistSheet> createState() => _VedicChecklistSheetState();
}

class _VedicChecklistSheetState extends State<VedicChecklistSheet> {
  late final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.8,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: ColoredBox(
          color: kKitGreenDark,
          child: Column(
            children: [
              _Header(
                title: 'Vedic Samagri Checklist',
                subtitle:
                    '${widget.ceremonyName} • Devotee Will Arrange Own Items',
              ),
              Expanded(
                child: ColoredBox(
                  color: kKitMint,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    children: [
                      const Text(
                        'The Acharya will verify each item before the ceremony. '
                        'Purchase these locally from a trusted puja store:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kKitMintBorder),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < widget.itemNames.length; i++)
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => setState(() {
                                  if (!_checked.add(i)) _checked.remove(i);
                                }),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 7),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _checked.contains(i)
                                            ? Icons.check_box_rounded
                                            : Icons
                                                .check_box_outline_blank_rounded,
                                        size: 19,
                                        color: _checked.contains(i)
                                            ? kKitGreen
                                            : AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          widget.itemNames[i],
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: _checked.contains(i)
                                                ? AppColors.textMuted
                                                : AppColors.textDark,
                                            decoration: _checked.contains(i)
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kKitMintBorder),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.tips_and_updates_rounded,
                              size: 16,
                              color: kKitGreen,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tip: take this checklist with you to the store — '
                                'the Acharya confirms each item on arrival at the '
                                'mandap.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ColoredBox(
                color: kKitMint,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: AppColors.textDark,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 13),
                          child: Text(
                            'Close Checklist',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
