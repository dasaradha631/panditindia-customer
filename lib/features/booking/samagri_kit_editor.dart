import 'package:flutter/material.dart' hide Text;

import '../../core/l10n/localized_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/ceremony_samagri_data.dart';
import 'samagri_kit_sheets.dart';

/// Result of the Customize Eco-Samagri Kit editor: the edited cart, the kit
/// grade it was built for (the user may toggle Premium ↔ Standard inside the
/// editor) and the Acharya preparation notes.
class SamagriKitEditResult {
  const SamagriKitEditResult({
    required this.items,
    required this.packageId,
    required this.notes,
  });

  final List<SamagriItem> items;
  final String packageId;
  final String notes;
}

/// Full-screen editor for the Eco-Samagri kit (web parity with the
/// `StepSamagri` "Customize Items" modal — Image 4): kit-grade toggle,
/// edit quantities, remove items, add from the samagri catalogue, add
/// custom items, live cost differentiation (category totals, base inclusions,
/// delta, Total Kit Dakshina), preparation notes, reset to the ceremony
/// default kit, then Save & Apply (commits the cart) or Cancel (discards
/// every edit — the booking draft keeps its original kit).
class SamagriKitEditor extends StatefulWidget {
  const SamagriKitEditor({
    super.key,
    required this.ceremonyId,
    required this.ceremonyName,
    required this.packageId,
    required this.initialItems,
    this.initialNotes = '',
  });

  final String ceremonyId;
  final String ceremonyName;
  final String packageId;
  final List<SamagriItem> initialItems;
  final String initialNotes;

  /// Opens the editor as a full-screen bottom sheet.
  /// Returns the edited kit on Apply, `null` on Cancel/close.
  static Future<SamagriKitEditResult?> open(
    BuildContext context, {
    required String ceremonyId,
    required String ceremonyName,
    required String packageId,
    required List<SamagriItem> initialItems,
    String initialNotes = '',
  }) {
    return showModalBottomSheet<SamagriKitEditResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.94,
        child: SamagriKitEditor(
          ceremonyId: ceremonyId,
          ceremonyName: ceremonyName,
          packageId: packageId,
          initialItems: initialItems,
          initialNotes: initialNotes,
        ),
      ),
    );
  }

  @override
  State<SamagriKitEditor> createState() => _SamagriKitEditorState();
}

class _SamagriKitEditorState extends State<SamagriKitEditor> {
  late List<SamagriItem> _cart;
  late String _packageId;
  final _search = TextEditingController();
  final _customName = TextEditingController();
  final _customPrice = TextEditingController();
  final _notes = TextEditingController();
  String _category = 'all';

  @override
  void initState() {
    super.initState();
    _cart = List<SamagriItem>.of(widget.initialItems);
    _packageId = widget.packageId == 'none' ? 'premium' : widget.packageId;
    _notes.text = widget.initialNotes;
  }

  @override
  void dispose() {
    _search.dispose();
    _customName.dispose();
    _customPrice.dispose();
    _notes.dispose();
    super.dispose();
  }

  double get _total => CeremonySamagriData.calculateKitTotal(_cart);

  /// Default (uncustomized) kit total for the currently picked grade —
  /// the "Ceremony Base Inclusions" figure of the web cost dialog.
  double get _baseInclusions => CeremonySamagriData.calculateKitTotal(
    CeremonySamagriData.getCeremonyKitItems(
      widget.ceremonyId,
      _packageId,
      widget.ceremonyName,
    ),
  );

  void _setQty(SamagriItem item, int qty) {
    setState(() {
      final idx = _cart.indexWhere((i) => i.id == item.id);
      if (idx == -1) return;
      if (qty <= 0) {
        _cart.removeAt(idx);
      } else {
        _cart[idx] = _cart[idx].copyWith(qty: qty);
      }
    });
  }

  void _addFromCatalogue(SamagriItem item) {
    final idx = _cart.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      _setQty(_cart[idx], _cart[idx].qty + 1);
      return;
    }
    setState(() => _cart.add(item.copyWith(qty: 1)));
  }

  void _addCustomItem() {
    final name = _customName.text.trim();
    final price = double.tryParse(_customPrice.text.trim());
    if (name.isEmpty) {
      showAppToast(
        context,
        'Please enter the item name.',
        type: ToastType.warning,
        title: 'Custom Item',
      );
      return;
    }
    if (price == null || price <= 0) {
      showAppToast(
        context,
        'Please enter a valid price for the item.',
        type: ToastType.warning,
        title: 'Custom Item',
      );
      return;
    }
    setState(() {
      _cart.add(
        SamagriItem(
          id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
          name: name,
          quantity: '1 Unit',
          category: 'Custom',
          price: price,
          icon: '🪔',
          qty: 1,
        ),
      );
      _customName.clear();
      _customPrice.clear();
    });
  }

  /// Kit-grade toggle (web `setKitTier`): swaps the cart to the other
  /// package's default ceremony kit and re-prices everything live.
  void _switchGrade(String packageId) {
    if (packageId == _packageId) return;
    setState(() {
      _packageId = packageId;
      _cart = List<SamagriItem>.of(
        CeremonySamagriData.getCeremonyKitItems(
          widget.ceremonyId,
          packageId,
          widget.ceremonyName,
        ),
      );
    });
    showAppToast(
      context,
      'Switched to ${_packageName(packageId)} with its default ceremony items.',
      type: ToastType.success,
      title: 'Kit Grade',
    );
  }

  void _resetToDefault() {
    setState(() {
      _cart = List<SamagriItem>.of(
        CeremonySamagriData.getCeremonyKitItems(
          widget.ceremonyId,
          _packageId,
          widget.ceremonyName,
        ),
      );
    });
    showAppToast(
      context,
      'Kit reset to the default ${_packageName(_packageId)} items.',
      type: ToastType.info,
      title: 'Reset',
    );
  }

  void _apply() {
    Navigator.of(context).pop(
      SamagriKitEditResult(
        items: List<SamagriItem>.of(_cart),
        packageId: _packageId,
        notes: _notes.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildGradeToggle(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              _buildCartSection(),
              const SizedBox(height: 14),
              _buildCatalogueSection(),
              const SizedBox(height: 14),
              _buildCustomItemSection(),
              const SizedBox(height: 14),
              _buildNotesSection(),
            ],
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Customize Eco-Samagri Kit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _packageId == 'premium' ? 'PREMIUM SEALED KIT' : 'STANDARD VEDIC KIT',
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: Colors.white,
                  ),
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
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ceremony: ${widget.ceremonyName} • Real-time Item Price Calculation',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  /// Kit grade toggle + reset link (web `kitGrade` row of the modal).
  Widget _buildGradeToggle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: kKitMint,
      child: Row(
        children: [
          const Text(
            'Kit Grade:',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(width: 8),
          _gradeChip('premium', '🏆 Premium Sealed Kit'),
          const SizedBox(width: 6),
          _gradeChip('standard', '🌿 Standard Vedic Kit'),
          const Spacer(),
          GestureDetector(
            onTap: _resetToDefault,
            child: const Text(
              '↻ Reset',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: kKitGreen,
                decoration: TextDecoration.underline,
                decorationColor: kKitGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradeChip(String id, String label) {
    final selected = _packageId == id;
    return GestureDetector(
      onTap: () => _switchGrade(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kKitGreen : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? kKitGreen : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  String _packageName(String id) {
    switch (id) {
      case 'premium':
        return 'Premium Sealed Kit';
      case 'standard':
        return 'Standard Vedic Kit';
      default:
        return 'Devotee Brings Own Items';
    }
  }

  Widget _buildCartSection() {
    final delta = _total - _baseInclusions;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kKitMintBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Cost Differentiation Dialog',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: kKitGreen,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_cart.length} Items',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_cart.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Your kit is empty. Add items from the catalogue below.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              )
            )
          else
            ..._cart.map(_cartRow),
          const SizedBox(height: 6),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          const Text(
            'CATEGORY-WISE COST DIFFERENTIATION',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              color: kKitGreenDeep,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final entry in _categoryTotals.entries)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kKitMint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kKitMintBorder),
                  ),
                  child: Text(
                    '${entry.key}: ${Fmt.inr(entry.value)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: kKitGreenDeep,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _summaryLine(
            'Ceremony Base Inclusions:',
            Fmt.inr(_baseInclusions),
          ),
          _summaryLine(
            'Cost Differentiation Delta:',
            '${delta >= 0 ? '' : '-'}${Fmt.inr(delta.abs())} '
                '(${_packageName(_packageId)})',
            highlight: delta != 0,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TOTAL KIT DAKSHINA:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                Fmt.inr(_total),
                style: const TextStyle(
                  fontSize: 16,
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

  /// Category → summed line totals of the live cart, first-seen order.
  Map<String, double> get _categoryTotals {
    final totals = <String, double>{};
    for (final item in _cart) {
      totals[item.category] = (totals[item.category] ?? 0) + item.lineTotal;
    }
    return totals;
  }

  Widget _summaryLine(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: highlight ? AppColors.accent : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartRow(SamagriItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(item.icon, style: const TextStyle(fontSize: 16)),
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
                const SizedBox(height: 2),
                Text(
                  '${Fmt.inr(item.price)} × ${item.qty} = ${Fmt.inr(item.lineTotal)}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _qtyButton(
            icon: Icons.remove,
            onTap: () => _setQty(item, item.qty - 1),
          ),
          SizedBox(
            width: 22,
            child: Text(
              '${item.qty}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
          ),
          _qtyButton(icon: Icons.add, onTap: () => _setQty(item, item.qty + 1)),
          const SizedBox(width: 2),
          IconButton(
            onPressed: () => _setQty(item, 0),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(
              Icons.delete_outline,
              size: 17,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 15, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildCatalogueSection() {
    final query = _search.text.trim().toLowerCase();
    final items = CeremonySamagriData.catalogue.where((i) {
      final matchQuery =
          query.isEmpty ||
          i.name.toLowerCase().contains(query) ||
          i.category.toLowerCase().contains(query);
      final matchCat = _category == 'all' || i.category == _category;
      return matchQuery && matchCat;
    }).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add from Samagri Catalogue',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Search items (e.g. Ghee, Kumkum, Lotus)...',
              hintStyle: const TextStyle(fontSize: 12.5),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear, size: 18),
                    ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: CeremonySamagriData.samagriCategories.map((c) {
              final selected = c == _category;
              final label = c == 'all' ? 'All' : c;
              return ChoiceChip(
                label: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                selected: selected,
                selectedColor: AppColors.accent,
                backgroundColor: Colors.white,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textDark,
                ),
                side: BorderSide(
                  color: selected ? AppColors.accent : AppColors.border,
                ),
                onSelected: (_) => setState(() => _category = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No items match your search.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            )
          else
            ...items.map(_catalogueRow),
        ],
      ),
    );
  }

  Widget _catalogueRow(SamagriItem item) {
    final inCart = _cart.indexWhere((i) => i.id == item.id);
    final qty = inCart == -1 ? 0 : _cart[inCart].qty;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: qty > 0 ? AppColors.accent : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Text(item.icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${Fmt.inr(item.price)} • ${item.quantity} • ${item.category}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (qty == 0)
            TextButton(
              onPressed: () => _addFromCatalogue(item),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 30),
                backgroundColor: AppColors.accentLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Add',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
            )
          else ...[
            _qtyButton(
              icon: Icons.remove,
              onTap: () => _setQty(_cart[inCart], qty - 1),
            ),
            SizedBox(
              width: 22,
              child: Text(
                '$qty',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ),
            _qtyButton(
              icon: Icons.add,
              onTap: () => _setQty(_cart[inCart], qty + 1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomItemSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add a Custom Item',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customName,
                  style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                  decoration: const InputDecoration(
                    hintText: 'Item name (e.g. Sandalwood paste)',
                    hintStyle: TextStyle(fontSize: 12.5),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: TextField(
                  controller: _customPrice,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                  decoration: const InputDecoration(
                    hintText: '₹ Price',
                    hintStyle: TextStyle(fontSize: 12.5),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addCustomItem,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 17),
              label: const Text(
                'Add Item to Kit',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Special Preparation Notes for Acharya',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notes,
            maxLines: 2,
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            decoration: const InputDecoration(
              hintText: 'e.g. Extra Bel leaves, pure cow milk pack needed...',
              hintStyle: TextStyle(fontSize: 12.5),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Kit Dakshina',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Text(
                Fmt.inr(_total),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetToDefault,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: 'Save & Apply Kit (${Fmt.inr(_total)})',
                  onPressed: _apply,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
