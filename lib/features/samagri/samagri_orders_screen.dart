import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../models/ceremony_samagri_data.dart';
import '../../providers/profile_provider.dart';
import '../../services/samagri_service.dart';
import '../pujas/puja_catalogue_screen.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

class SamagriOrdersScreen extends StatefulWidget {
  const SamagriOrdersScreen({super.key});

  @override
  State<SamagriOrdersScreen> createState() => _SamagriOrdersScreenState();
}

class _SamagriOrdersScreenState extends State<SamagriOrdersScreen> {
  static const _filters = ['All', 'Active', 'Delivered', 'Cancelled'];

  final SamagriService _service = SamagriService();
  final TextEditingController _search = TextEditingController();
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  bool _error = false;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_orders.isEmpty) setState(() => _loading = true);
    final orders = await _service.getOrders();
    if (!mounted) return;
    setState(() {
      _error = orders == null;
      if (orders != null) _orders = orders;
      _loading = false;
    });
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('deliver') || s.contains('complete')) {
      return AppColors.success;
    }
    if (s.contains('cancel')) return AppColors.danger;
    if (s.contains('ship') || s.contains('transit')) return AppColors.info;
    return AppColors.warning;
  }

  String _orderId(Map<String, dynamic> o) {
    final id = (o['id'] ?? o['order_id'] ?? '1024').toString();
    return '#ESK-${id.padLeft(4, '0')}';
  }

  String _itemsSummary(Map<String, dynamic> o) {
    final items = o['items'];
    if (items is! List || items.isEmpty) return 'Eco-Samagri kit';
    final names = items
        .map((e) {
          if (e is Map) {
            return (e['name'] ?? e['title'] ?? e['item'] ?? '').toString();
          }
          return e.toString();
        })
        .where((s) => s.isNotEmpty && s != 'null')
        .toList();
    return names.isEmpty ? 'Eco-Samagri kit' : names.join(', ');
  }

  List<Map<String, dynamic>> get _visibleOrders {
    final q = _search.text.trim().toLowerCase();
    return _orders.where((o) {
      final s = (o['status'] ?? 'Pending').toString().toLowerCase();
      if (_filter == 'Active' && (s == 'delivered' || s == 'cancelled')) {
        return false;
      }
      if (_filter == 'Delivered' && s != 'delivered') return false;
      if (_filter == 'Cancelled' && s != 'cancelled') return false;
      if (q.isEmpty) return true;
      final id = (o['id'] ?? o['order_id'] ?? '').toString().toLowerCase();
      if (id.contains(q)) return true;
      if (_orderId(o).toLowerCase().contains(q)) return true;
      if ((o['name'] ?? '').toString().toLowerCase().contains(q)) {
        return true;
      }
      if ((o['delivery_address'] ?? '').toString().toLowerCase().contains(q)) {
        return true;
      }
      final items = o['items'];
      if (items is List) {
        for (final e in items) {
          if (e is Map &&
              (e['name'] ?? '').toString().toLowerCase().contains(q)) {
            return true;
          }
        }
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleOrders;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: GradientAppBar(title: 'Eco-Samagri Kit'),
      body: _loading
          ? const LoadingView(label: 'Loading your samagri orders...')
          : _error && _orders.isEmpty
          ? EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'Unable to load your orders',
              subtitle: 'Please check your connection and try again.',
              actionLabel: 'Retry',
              onAction: _load,
            )
          : _orders.isEmpty
          ? EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No samagri orders yet',
              subtitle: 'Order a sealed eco-friendly samagri kit while booking any ceremony.',
              actionLabel: 'Browse Pujas',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PujaCatalogueScreen()),
              ),
            )
          : RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error) ...[
                    _refreshErrorStrip(),
                    const SizedBox(height: 16),
                  ],
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildStats(),
                  const SizedBox(height: 16),
                  _buildLogisticsHub(),
                  const SizedBox(height: 16),
                  _buildControls(),
                  const SizedBox(height: 16),
                  ...visible.map(
                    (o) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _orderCard(o),
                    ),
                  ),
                  if (visible.isEmpty) _noMatches(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Eco-Samagri Kit Orders & Organic Vedic Ingredients',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '100% Pure, Organic, Eco-packaged Vedic Puja Ingredients prepared by Gurukul Samagri specialists.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final ordered = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const _CustomKitSheet(),
                );
                if (ordered == true && mounted) _load();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: const BorderSide(color: AppColors.success),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.shopping_bag_outlined, size: 16),
              label: const Text(
                'Order Custom Samagri Kit',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final totalOrders = _orders.length;
    final inTransit = _orders.where((o) {
      final s = (o['status'] ?? '').toString().toLowerCase();
      return s.contains('transit') || s.contains('ship');
    }).length;
    final delivered = _orders.where((o) {
      final s = (o['status'] ?? '').toString().toLowerCase();
      return s == 'delivered' || s.contains('complete');
    }).length;
    final totalValue = _orders.fold<double>(0, (sum, o) {
      final amount =
          o['total_price'] ?? o['total'] ?? o['total_amount'] ?? o['amount'];
      if (amount is num) return sum + amount.toDouble();
      return sum;
    });

    return Row(
      children: [
        Expanded(
          child: _statCard('$totalOrders', 'Total Orders', AppColors.accent),
        ),
        const SizedBox(width: 8),
        Expanded(child: _statCard('$inTransit', 'In Transit', AppColors.info)),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard('$delivered', 'Delivered', AppColors.success),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            '₹${totalValue.toInt()}',
            'Total Value',
            AppColors.gold,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _refreshErrorStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 18,
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Unable to refresh your samagri orders.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: _load,
            child: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'My EcoSamagri Kit Orders',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '${_orders.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _filters.map(_filterChip).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: AppColors.textDark, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Search orders...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 19,
                color: AppColors.textMuted,
              ),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
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
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String f) {
    final selected = f == _filter;
    return ChoiceChip(
      label: Text(f),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textDark,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
      ),
      onSelected: (_) => setState(() => _filter = f),
    );
  }

  Widget _noMatches() {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'No matching Eco-Samagri Kit orders',
      subtitle: 'Try a different search term or filter.',
      actionLabel: 'Clear Filters',
      onAction: () {
        _search.clear();
        setState(() => _filter = 'All');
      },
    );
  }

  Widget _buildLogisticsHub() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF021824), Color(0xFF063447)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_rounded,
                color: AppColors.accent,
                size: 16,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'ACTIVE LOGISTICS TRACKING HUB',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'BlueDart Express',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _logisticsStage(
            'Kit Packed & Sealed',
            'Haridwar Vedic Facility',
            true,
          ),
          _logisticsLine(true),
          _logisticsStage(
            'Handed to BlueDart',
            'Dispatched via Air Cargo',
            true,
          ),
          _logisticsLine(true),
          _logisticsStage(
            'In Transit to Mandap',
            'ETA: Today • 05:00 PM',
            true,
            isCurrent: true,
          ),
          _logisticsLine(false),
          _logisticsStage('Handover to Devotee', 'Pending Arrival', false),
        ],
      ),
    );
  }

  Widget _logisticsStage(
    String title,
    String subtitle,
    bool done, {
    bool isCurrent = false,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: done
                ? AppColors.success
                : Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: done
                  ? AppColors.success
                  : Colors.white.withValues(alpha: 0.3),
              width: isCurrent ? 2.5 : 1.5,
            ),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
              : Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: done
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  color: done
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
        if (isCurrent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'CURRENT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _logisticsLine(bool done) {
    return Container(
      width: 2,
      height: 20,
      margin: const EdgeInsets.only(left: 13),
      color: done ? AppColors.success : Colors.white.withValues(alpha: 0.15),
    );
  }

  Widget _orderCard(Map<String, dynamic> o) {
    final status = (o['status'] ?? 'pending').toString();
    final amount =
        o['total_price'] ?? o['total'] ?? o['total_amount'] ?? o['amount'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _orderId(o),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              StatusBadge(
                label: status,
                color: _statusColor(status),
                dense: true,
              ),
            ],
          ),
          const Divider(height: 20),
          InfoRow(
            label: 'Items',
            value: _itemsSummary(o),
            icon: Icons.local_florist_outlined,
          ),
          if (o['created_at'] != null)
            InfoRow(
              label: 'Ordered on',
              value: o['created_at'].toString(),
              icon: Icons.calendar_today_outlined,
            ),
          if (o['delivery_date'] != null)
            InfoRow(
              label: 'Delivery',
              value: o['delivery_date'].toString(),
              icon: Icons.delivery_dining_outlined,
            ),
          if (amount != null)
            InfoRow(
              label: 'Total',
              value: amount is num ? Fmt.inr(amount) : amount.toString(),
              icon: Icons.payments_outlined,
            ),
        ],
      ),
    );
  }
}

/// Mobile counterpart of the web "Book Custom Eco-Samagri Kit" modal
/// (UserDashboardPage.jsx MODAL 6): searchable catalogue + category pills,
/// custom item entry, qty-managed cart with grand total and the delivery
/// form (address, required-by date, notes) submitted to `POST /samagri/order`.
class _CustomKitSheet extends StatefulWidget {
  const _CustomKitSheet();

  @override
  State<_CustomKitSheet> createState() => _CustomKitSheetState();
}

class _CustomKitSheetState extends State<_CustomKitSheet> {
  final SamagriService _service = SamagriService();
  final TextEditingController _search = TextEditingController();
  final TextEditingController _customName = TextEditingController();
  final TextEditingController _customPrice = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  String _category = 'all';
  final List<SamagriItem> _cart = <SamagriItem>[];
  DateTime? _date;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profile;
    final address = profile?.address?.trim() ?? '';
    if (address.isNotEmpty) {
      _address.text = address;
    } else {
      final parts = [
        if (profile?.city?.trim().isNotEmpty ?? false) profile!.city!.trim(),
        if (profile?.state?.trim().isNotEmpty ?? false)
          profile!.state!.trim(),
      ];
      _address.text = parts.join(', ');
    }
  }

  @override
  void dispose() {
    for (final c in [
      _search,
      _customName,
      _customPrice,
      _address,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<SamagriItem> get _visible {
    final q = _search.text.trim().toLowerCase();
    return CeremonySamagriData.catalogue.where((i) {
      if (_category != 'all' && i.category != _category) return false;
      if (q.isNotEmpty && !i.name.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  num get _total => _cart.fold<num>(0, (sum, i) => sum + i.lineTotal);

  void _add(SamagriItem item) {
    setState(() {
      final idx = _cart.indexWhere((c) => c.id == item.id);
      if (idx >= 0) {
        _cart[idx] = _cart[idx].copyWith(qty: _cart[idx].qty + 1);
      } else {
        _cart.add(item.copyWith(qty: 1));
      }
    });
  }

  void _bump(SamagriItem item, int delta) {
    setState(() {
      final idx = _cart.indexWhere((c) => c.id == item.id);
      if (idx < 0) return;
      final next = _cart[idx].qty + delta;
      if (next <= 0) {
        _cart.removeAt(idx);
      } else {
        _cart[idx] = _cart[idx].copyWith(qty: next);
      }
    });
  }

  void _addCustom() {
    final name = _customName.text.trim();
    if (name.isEmpty) {
      showAppToast(
        context,
        'Please enter custom item name.',
        type: ToastType.warning,
        title: 'Custom Item',
      );
      return;
    }
    final price = double.tryParse(_customPrice.text.trim()) ?? 100;
    setState(() {
      _cart.add(SamagriItem(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        quantity: '1 Unit',
        category: 'Custom',
        price: price,
        icon: '🎁',
        qty: 1,
      ));
      _customName.clear();
      _customPrice.clear();
    });
    showAppToast(
      context,
      'Custom item "$name" added to kit.',
      type: ToastType.success,
      title: 'Custom Item',
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static const List<String> _monthNames = [
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december',
  ];

  /// QA: delivery date rendered as `14/october/2026` (day/month-name/year).
  static String _prettyDate(DateTime d) =>
      '${d.day}/${_monthNames[d.month - 1]}/${d.year}';

  Future<void> _submit() async {
    final address = _address.text.trim();
    if (_cart.isEmpty) {
      showAppToast(
        context,
        'Your Eco-Kit cart is empty. Please add items from catalogue.',
        type: ToastType.warning,
        title: 'Custom Kit',
      );
      return;
    }
    if (address.isEmpty) {
      showAppToast(
        context,
        'Please enter the delivery address.',
        type: ToastType.warning,
        title: 'Custom Kit',
      );
      return;
    }
    if (_date == null) {
      showAppToast(
        context,
        'Please select a required delivery date.',
        type: ToastType.warning,
        title: 'Custom Kit',
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await _service.createOrder(
      deliveryAddress: address,
      deliveryDate: _iso(_date!),
      specialNotes: _notes.text,
      items: _cart
          .map(
            (i) => <String, dynamic>{
              'item_id': i.id,
              'name': i.name,
              'quantity': i.qty,
              'price': i.price,
            },
          )
          .toList(),
      totalPrice: _total,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!ok) {
      showAppToast(
        context,
        'Could not place the samagri order. Please try again.',
        type: ToastType.error,
        title: 'Custom Kit',
      );
      return;
    }
    showAppToast(
      context,
      'Eco-Samagri Kit Confirmed! Scheduled for delivery by '
      '${_prettyDate(_date!)}.',
      type: ToastType.success,
      title: 'Custom Kit',
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 18,
                        color: AppColors.successDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book Custom Eco-Samagri Kit',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '100% Organic, Vedic-Certified Ingredients '
                            'Delivered to Your Doorstep',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 17,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Search items (Ghee, Hawan herbs, Kalash, Agarbatti)...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 19,
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.cream,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.success),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: CeremonySamagriData.samagriCategories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 7),
                    itemBuilder: (ctx, i) {
                      final cat =
                          CeremonySamagriData.samagriCategories[i];
                      final selected = cat == _category;
                      return ChoiceChip(
                        label: Text(
                          cat == 'all'
                              ? 'ALL'
                              : cat.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: selected
                                ? Colors.white
                                : AppColors.textDark,
                          ),
                        ),
                        selected: selected,
                        selectedColor: AppColors.success,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: selected
                              ? AppColors.success
                              : AppColors.border,
                        ),
                        onSelected: (_) => setState(() => _category = cat),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Text(
                            'No items match your search.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 7),
                          itemBuilder: (ctx, i) {
                            final item = items[i];
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.success
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    item.icon,
                                    style: const TextStyle(fontSize: 19),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textDark,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.quantity} • '
                                          '${Fmt.inr(item.price)}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.successDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _add(item),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        borderRadius:
                                            BorderRadius.circular(9),
                                      ),
                                      child: const Text(
                                        '+ Add',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ADD CUSTOM ITEM (ANY UNLISTED SAMAGRI)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _customName,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 12.5,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Item Name (e.g. Bilva Leaves)',
                                filled: true,
                                fillColor: AppColors.cream,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 9,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: TextField(
                              controller: _customPrice,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 12.5,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Price ₹',
                                filled: true,
                                fillColor: AppColors.cream,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 9,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          GestureDetector(
                            onTap: _addCustom,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '+ Add',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Your Kit Cart',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_cart.fold<int>(0, (s, i) => s + i.qty)} Items',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_cart.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Cart is empty. Add items from catalogue.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 170),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: _cart.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 10,
                              color: AppColors.border,
                            ),
                            itemBuilder: (ctx, i) {
                              final item = _cart[i];
                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        Text(
                                          '${Fmt.inr(item.price)} × '
                                          '${item.qty}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _qtyButton('−', () => _bump(item, -1)),
                                  SizedBox(
                                    width: 26,
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
                                  _qtyButton('+', () => _bump(item, 1)),
                                ],
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.only(top: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppColors.successDark,
                              width: 0.6,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Grand Total:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            Text(
                              Fmt.inr(_total),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.successDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Address *',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _address,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'House / Street, Area, City, PIN',
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: AppColors.successDark,
                          ),
                          filled: true,
                          fillColor: AppColors.cream,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 11,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: const BorderSide(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Required By Date *',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 7),
                      InkWell(
                        onTap: _submitting ? null : _pickDate,
                        borderRadius: BorderRadius.circular(11),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: AppColors.successDark,
                              ),
                              const SizedBox(width: 9),
                              Text(
                                _date == null
                                    ? 'Select delivery date'
                                    : _prettyDate(_date!),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _date == null
                                      ? AppColors.textMuted
                                      : AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Special Notes',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _notes,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Need extra Tulsi leaves',
                          filled: true,
                          fillColor: AppColors.cream,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 11,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: const BorderSide(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: _submitting
                              ? 'Placing Order...'
                              : 'Confirm & Place Samagri Order',
                          icon: Icons.check_circle_outline_rounded,
                          onPressed: _submitting ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _qtyButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
