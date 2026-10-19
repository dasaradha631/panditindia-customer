import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/receipt_pdf.dart';
import '../../core/widgets/common.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../bookings/booking_details_screen.dart';
import '../pujas/puja_catalogue_screen.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<BookingProvider>();
      if (p.myBookings.isEmpty) p.loadMyBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BookingProvider>();
    final receipts = p.myBookings
        .where((b) => b.bookingId != null)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: GradientAppBar(title: 'Receipts & 80G Tax'),
      body: p.loadingBookings && receipts.isEmpty
          ? const LoadingView(label: 'Loading receipts...')
          : receipts.isEmpty
          ? EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No receipts yet',
              subtitle: 'Official 80G tax receipts appear here once a ceremony is completed.',
              actionLabel: 'Book a Sacred Ceremony',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PujaCatalogueScreen()),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: () =>
                        context.read<BookingProvider>().loadMyBookings(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildHeader(receipts),
                        const SizedBox(height: 16),
                        ...receipts.map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _receiptCard(b),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(List<Booking> receipts) {
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
              const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.purple,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Invoices & 80G Tax-Exempt Receipts',
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
            'Official digital receipts eligible for 100% tax deduction under Section 80G.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ReceiptPdf.shareAll(context, receipts),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.purple,
                side: const BorderSide(color: AppColors.purple),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text(
                'Download All Invoices',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptCard(Booking b) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              BookingDetailsScreen(bookingId: b.bookingId, initial: b),
        ),
      ),
      child: Container(
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.purple,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.displayId,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        b.ceremony ?? 'Ceremony',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(
                  label: b.displayStatus,
                  color: AppStatus.colorFor(b.rawStatus),
                  dense: true,
                ),
                const SizedBox(width: 8),
                Text(
                  b.priceDisplay,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: InfoRow(label: 'Date', value: Fmt.date(b.bookingDate)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Text(
                    '80G Tax Deductible',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
            if (b.isCompleted) ...[
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 14,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Fully Settled • Blessed & Handed Over',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successDark,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => ReceiptPdf.share(context, b),
                icon: const Icon(Icons.download_rounded, size: 15),
                label: const Text(
                  'Download PDF',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.purple,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
