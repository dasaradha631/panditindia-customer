import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../../core/constants/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/contact_actions.dart';
import '../../core/widgets/common.dart';
import '../../models/misc_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/ticket_service.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TicketService _service = TicketService();
  List<SupportTicket> tickets = [];
  bool loading = true;

  static const _categories = [
    'Samagri Customization Request',
    'Booking Issue',
    'Payment / Receipt',
    'Pandit Not Arrived',
    'Reschedule Request',
    'Refund',
    'App Feedback',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final list = await _service.myTickets(
      email: auth.session?.email,
      userId: auth.session?.id,
    );
    if (!mounted) return;
    setState(() {
      tickets = list;
      loading = false;
    });
  }

  Future<void> _raiseTicket() async {
    final auth = context.read<AuthProvider>();
    final formKey = GlobalKey<_TicketFormState>();
    final created = await showDialog<SupportTicket>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Raise a Ticket'),
        content: SizedBox(
          width: double.maxFinite,
          child: _TicketForm(key: formKey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => formKey.currentState?.submit(auth),
            child: const Text(
              'Submit',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
    if (created == null || !mounted) return;
    showAppToast(
      context,
      'Ticket ${created.displayId} created. Our team will respond shortly.',
      type: ToastType.success,
      title: 'Ticket Created',
    );
    await _load();
  }

  Future<void> _callSupport() async {
    final ok = await callNumber(AppConfig.supportPhone);
    if (!mounted) return;
    if (!ok) {
      showAppToast(
        context,
        'Dialer could not be opened. Call us on ${AppConfig.supportPhoneDisplay}.',
        type: ToastType.warning,
        title: 'Call Support',
      );
    }
  }

  Future<void> _whatsappSupport() async {
    final ok = await openWhatsApp(
      AppConfig.supportWhatsApp,
      message: 'Namaste, I have a ceremony query.',
    );
    if (!mounted) return;
    if (!ok) {
      showAppToast(
        context,
        'WhatsApp could not be opened. Call us on ${AppConfig.supportPhoneDisplay} instead.',
        type: ToastType.warning,
        title: 'WhatsApp Support',
      );
    }
  }

  /// Ticket "Open" — full ticket info sheet (id, status, category, message,
  /// support reply, time).
  void _openTicket(SupportTicket t) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TicketDetailSheet(ticket: t),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const GradientAppBar(title: 'Help & Support'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text(
          'New Ticket',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        onPressed: _raiseTicket,
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHelplineCard(),
            const SizedBox(height: 16),
            _buildCareGuarantee(),
            const SizedBox(height: 16),
            _buildQueryForm(),
            const SizedBox(height: 22),
            const SectionHeader(
              title: 'My Support Escalations & Ticket Status',
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: LoadingView(label: 'Loading tickets...'),
              )
            else if (tickets.isEmpty)
              EmptyState(
                icon: Icons.confirmation_number_outlined,
                title: 'No tickets yet',
                subtitle: 'Raise a ticket if you need help with a booking, payment or the app.',
                actionLabel: 'Raise a Ticket',
                onAction: _raiseTicket,
              )
            else
              ...tickets.map(
                (t) => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => _openTicket(t),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.displayId,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              StatusBadge(
                                label: t.status ?? 'Open',
                                color: (t.status ?? '').toLowerCase() == 'resolved'
                                    ? AppColors.success
                                    : AppColors.warning,
                                dense: true,
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            t.message ?? '-',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (t.category != null && t.category!.isNotEmpty)
                                Text(
                                  t.category!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              const Spacer(),
                              if (t.createdAt != null)
                                Text(
                                  Fmt.relative(t.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }

  Widget _buildHelplineCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF021824), Color(0xFF063447)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.headset_mic_rounded,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Dedicated Devotional Support & Acharya Desk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '24/7 dedicated helpline for Muhurat queries, customized samagri, pandit logistics, and expedited priest coordination.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                const Text(
                  'Toll-Free Devotional Helpline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  AppConfig.supportPhoneDisplay,
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Available 06:00 AM - 10:00 PM IST daily with verified Gurukul Acharyas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _callSupport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.call_rounded, size: 16),
                        label: const Text(
                          'Call Now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _whatsappSupport,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.chat_rounded, size: 16),
                        label: const Text(
                          'WhatsApp',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareGuarantee() {
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
                Icons.verified_user_rounded,
                color: AppColors.success,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Dedicated Devotee Care Guarantee',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _guaranteeItem(
            Icons.check_circle_outline,
            'Automated Confirmation',
            'Instant ticket reference and email receipt.',
          ),
          _guaranteeItem(
            Icons.check_circle_outline,
            '< 15 Mins Turnaround',
            'High priority handling for ceremony adjustments.',
          ),
          _guaranteeItem(
            Icons.check_circle_outline,
            'Senior Acharya Consultation',
            'Direct Vedic guidance on Muhurat & Sankalpa.',
          ),
        ],
      ),
    );
  }

  Widget _guaranteeItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueryForm() {
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
                Icons.question_answer_outlined,
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Raise Dedicated Acharya Desk Query',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Submitting this form sends an alert to our operations desk and dispatches a confirmation email to you.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _raiseTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text(
                'Submit Dedicated Acharya Query',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketForm extends StatefulWidget {
  const _TicketForm({super.key});

  @override
  State<_TicketForm> createState() => _TicketFormState();
}

class _TicketFormState extends State<_TicketForm> {
  final _message = TextEditingController();
  String category = _SupportScreenState._categories.first;
  bool saving = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> submit(AuthProvider auth) async {
    if (_message.text.trim().length < 10) {
      showAppToast(
        context,
        'Please describe the issue in at least 10 characters.',
        type: ToastType.warning,
        title: 'Ticket',
      );
      return;
    }
    setState(() => saving = true);
    final ticket = await TicketService().createTicket(
      name: auth.session?.name ?? 'Devotee',
      email: auth.session?.email ?? '',
      mobile: auth.session?.phone ?? '',
      category: category,
      message: _message.text.trim(),
      userId: auth.session?.id,
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (ticket == null) {
      showAppToast(
        context,
        'Could not create the ticket. Please try again.',
        type: ToastType.error,
        title: 'Ticket',
      );
      return;
    }
    Navigator.of(context).pop(ticket);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How can we help you?',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          const Text(
            'CATEGORY',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _SupportScreenState._categories.map((c) {
              final selected = c == category;
              return ChoiceChip(
                label: Text(
                  c,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                selected: selected,
                selectedColor: AppColors.accent,
                backgroundColor: AppColors.cream,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textDark,
                ),
                side: BorderSide(
                  color: selected ? AppColors.accent : AppColors.border,
                ),
                onSelected: (_) => setState(() => category = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Describe your issue',
            controller: _message,
            hint: 'Tell us what happened, including your booking ID if relevant...',
            maxLines: 5,
          ),
          if (saving) ...[
            const SizedBox(height: 14),
            const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full ticket info shown when the devotee taps "Open" on a raised ticket.
class _TicketDetailSheet extends StatelessWidget {
  const _TicketDetailSheet({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final resolved = (ticket.status ?? '').toLowerCase() == 'resolved';
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ticket ${ticket.displayId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              StatusBadge(
                label: ticket.status ?? 'Open',
                color: resolved ? AppColors.success : AppColors.warning,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _detailRow('CATEGORY', ticket.category ?? '—'),
          _detailRow(
            'PRIORITY',
            (ticket.priority == null || ticket.priority!.isEmpty)
                ? 'Normal'
                : ticket.priority!,
          ),
          _detailRow(
            'RAISED',
            ticket.createdAt == null ? '—' : Fmt.relative(ticket.createdAt),
          ),
          if ((ticket.coordinator ?? '').isNotEmpty)
            _detailRow('HANDLED BY', ticket.coordinator!),
          const SizedBox(height: 10),
          const Text(
            'YOUR MESSAGE',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            ticket.message ?? '—',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
          if ((ticket.reply ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SUPPORT REPLY',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    ticket.reply!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
