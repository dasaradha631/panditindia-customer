import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/profile_provider.dart';
import '../../features/booking/booking_flow_screen.dart';
import '../../features/bookings/my_bookings_screen.dart';
import '../../services/ai_chat_service.dart';
import '../constants/app_config.dart';
import '../theme/app_theme.dart';
import '../utils/contact_actions.dart';
import 'common.dart';

/// Global floating "Acharya AI • VedaGPT" assistant — the mobile counterpart
/// of the web `FloatingSupportWidget`. Mounted once in `MaterialApp.builder`
/// so it rides above every route (including signup/login), can be dragged
/// anywhere on the screen and collapses back into its sparkle bubble.
class FloatingAiAssistant extends StatefulWidget {
  const FloatingAiAssistant({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<FloatingAiAssistant> createState() => _FloatingAiAssistantState();
}

class _ChatMsg {
  const _ChatMsg(this.fromBot, this.text, {this.actions = const []});

  final bool fromBot;
  final String text;

  /// Chips rendered underneath the bubble — the mobile counterpart of the
  /// web widget's `msg.actions` (`book` | `navigate` | `callback`).
  final List<_ChatAction> actions;
}

/// Mirrors the web `actions[].type` values handled by
/// `FloatingSupportWidget.handleActionClick` (line 118).
class _ChatAction {
  const _ChatAction(this.label, this.type);

  final String label;
  final String type;
}

class _FloatingAiAssistantState extends State<FloatingAiAssistant> {
  static const double _bubbleSize = 56;
  static const String _waNumber = '9118008908334';
  static const String _telNumber = '18008908334';

  static const List<String> _quickPrompts = [
    '🏠 Griha Pravesh',
    '💰 Puja Pricing',
    '🗓️ Shubh Muhurat',
    '📦 Samagri Kit',
    '🗣️ Pandit Languages',
    '🛡️ Verified Pandits',
  ];

  /// Opening chips — the web widget's greeting actions (line 20).
  static const List<_ChatAction> _greetingActions = [
    _ChatAction('🏠 Griha Pravesh (₹5,100)', 'book'),
    _ChatAction('💰 View Ceremony Pricing', 'navigate'),
    _ChatAction('📞 Request Acharya Call', 'callback'),
  ];

  /// Active panel tab — the web widget's `activeTab` ('chat' | 'helpline').
  String _tab = 'chat';

  final AiChatService _ai = AiChatService();

  /// Distance of the bubble from the right/bottom screen edges.
  double _right = 16;
  double _bottom = 96;
  bool _open = false;
  bool _typing = false;

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMsg> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages.add(
      const _ChatMsg(
        true,
        '🙏 Namaste! I am Acharya AI · VedaGPT. Ask me anything about Pujas, '
        'Muhurats, Samagri, Pricing or Pandits — or pick a quick question below.',
        actions: _greetingActions,
      ),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _typing) return;
    final history = [
      for (final m in _messages) AiChatTurn(fromUser: !m.fromBot, text: m.text),
    ];
    setState(() {
      _messages.add(_ChatMsg(false, text));
      _input.clear();
      _typing = true;
    });
    _scrollDown();

    final aiReply = await _ai.queryVedicAI(text, history: history);
    final String reply;
    if (aiReply != null && aiReply.isNotEmpty) {
      reply = aiReply;
    } else {
      // Same graceful degradation as the web widget: on error/timeout run the
      // built-in reply engine (with its 400 ms typing beat) instead.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      reply = _localReply(text);
    }
    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMsg(true, reply));
      _typing = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _resetChat() {
    setState(() {
      _typing = false;
      _messages
        ..clear()
        ..add(
          const _ChatMsg(
            true,
            '🙏 Namaste! I am Acharya AI · VedaGPT. Ask me anything about '
            'Pujas, Muhurats, Samagri, Pricing or Pandits.',
            actions: _greetingActions,
          ),
        );
    });
  }

  void _openBookingFlow() {
    final nav = widget.navigatorKey?.currentState;
    if (nav == null) return;
    final ctx = nav.context;
    final auth = ctx.read<AuthProvider>();
    final profile = ctx.read<ProfileProvider>();
    final bookings = ctx.read<BookingProvider>();
    bookings.resetDraft(
      devoteeName: profile.profile?.fullName ?? auth.session?.name,
      mobile: profile.profile?.phonenumber ?? auth.session?.phone,
      email: profile.profile?.email ?? auth.session?.email,
      address: profile.profile?.address,
      city: profile.profile?.city,
      state: profile.profile?.state,
    );
    nav.push(MaterialPageRoute(builder: (_) => const BookingFlowScreen()));
  }

  /// Destination for the web `navigate` action (web routes to a shell path;
  /// the drawer's Bookings pane is the mobile equivalent). Wrapped exactly
  /// like `NotificationsScreenState._bookingsPane` so the pane gets a back
  /// affordance when pushed on its own.
  void _openMyBookings() {
    final nav = widget.navigatorKey?.currentState;
    if (nav == null) return;
    nav.push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.cream,
          appBar: const GradientAppBar(title: 'My Bookings'),
          body: const MyBookingsScreen(),
        ),
      ),
    );
  }

  /// Mirrors the web `handleActionClick` (FloatingSupportWidget line 118).
  void _handleAction(_ChatAction action) {
    switch (action.type) {
      case 'book':
        setState(() => _open = false);
        _openBookingFlow();
      case 'navigate':
        setState(() => _open = false);
        _openMyBookings();
      case 'callback':
        // The web callback form posts nowhere (`handleCallbackSubmit` is
        // client-side only), so it just opens the helpline tab — which here
        // offers the toll-free Call / WhatsApp options.
        setState(() => _tab = 'helpline');
      case 'call':
        callNumber(_telNumber);
      case 'whatsapp':
        openWhatsApp(
          _waNumber,
          message: 'Namaste PanditIndia Team! I need guidance from an Acharya.',
        );
      default:
        return;
    }
  }

  String _localReply(String q) {
    final t = q.toLowerCase();
    if (RegExp(r'griha|pravesh|house|vastu').hasMatch(t)) {
      return '🏠 Griha Pravesh & Vastu Shanti is our most-booked ceremony — '
          '₹3,100 onwards, including Acharya dakshina. Tap "Book Now" and pick '
          'a Shubh Muhurat in step 2.';
    }
    if (RegExp(r'price|cost|charge|fee|₹|rs\b').hasMatch(t)) {
      return '💰 Ceremony prices start at ₹1,800. Travel Dakshina is FREE '
          'within 8 km, ₹150 for 8–20 km and ₹300 up to 40 km. Eco-Samagri '
          'kits are ₹800 (Premium) / ₹500 (Standard) or self-arrange at ₹0.';
    }
    if (RegExp(r'muhurat|auspicious|shubh|date|time slot').hasMatch(t)) {
      return '🗓️ Choose your Shubh Muhurat in the booking flow — Brahma '
          'Muhurat (05:30–08:00 AM) and Abhijit (08:00–11:30 AM) are ideal '
          'for most pujas and homams.';
    }
    if (RegExp(r'samagri|kit|item').hasMatch(t)) {
      return '📦 Three options: Premium Sealed Eco-Samagri Kit ₹800, Standard '
          'Vedic Samagri Kit ₹500, or Devotee Will Arrange Own Items (free — '
          'you get a verified checklist). You can switch anytime before '
          'checkout.';
    }
    if (RegExp(r'language|speak|hindi|telugu|tamil').hasMatch(t)) {
      return '🗣️ Our Acharyas perform pujas in Hindi, Sanskrit, Telugu, '
          'Tamil, Kannada, Marathi, Gujarati, Bengali, Odia, Malayalam and '
          'English — pick your language at checkout.';
    }
    if (RegExp(r'pandit|priest|acharya|verified|trust').hasMatch(t)) {
      return '🛡️ Every Acharya is ID-verified, background-checked and '
          'rating-reviewed before joining PanditIndia. You can follow their '
          'live location on the Track tab on ceremony day.';
    }
    if (RegExp(r'cancel|reschedul|refund').hasMatch(t)) {
      return 'You can cancel free of cost until the Acharya accepts, and '
          'reschedule from My Bookings anytime before the ceremony starts.';
    }
    if (RegExp(r'hello|hi\b|namaste|hey|namaskar').hasMatch(t)) {
      return '🙏 Namaste! How may I assist your puja booking today?';
    }
    if (RegExp(r'call|contact|support|help|number|whatsapp').hasMatch(t)) {
      return '📞 Call us on 1800-890-8334 or tap the WhatsApp button above — '
          'Devotee Care replies in minutes, 24x7.';
    }
    return 'I can help with Pujas 🏠, Pricing 💰, Muhurats 🗓️, Samagri 📦, '
        'Verified Pandits 🛡️ and more. For anything else, tap WhatsApp above '
        'and our Devotee Care team will help instantly.';
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final size = MediaQuery.sizeOf(context);
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    final usableH = math.max(320.0, size.height - kb);
    setState(() {
      _right = (_right - d.delta.dx).clamp(
        8.0,
        math.max(8.0, size.width - _bubbleSize - 8),
      );
      _bottom = (_bottom - d.delta.dy).clamp(
        8.0,
        math.max(8.0, usableH - _bubbleSize - 8),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    final usableH = math.max(320.0, size.height - kb);

    final bubbleTop = usableH - _bottom - _bubbleSize;
    final bubbleLeft = size.width - _right - _bubbleSize;

    final panelW = math.min(410.0, size.width - 24);
    final panelH = math.min(560.0, usableH - 24);
    final panelLeft = (bubbleLeft + _bubbleSize / 2 - panelW / 2)
        .clamp(8.0, math.max(8.0, size.width - panelW - 8))
        .toDouble();
    var panelTop = bubbleTop - panelH - 10;
    if (panelTop < 8) {
      panelTop = math.min(
        bubbleTop + _bubbleSize + 10,
        math.max(8.0, usableH - panelH - 8),
      );
    }

    return Positioned.fill(
      child: Stack(
        children: [
          if (_open)
            Positioned(
              top: panelTop,
              left: panelLeft,
              child: _buildPanel(context, panelW, panelH),
            ),
          Positioned(
            top: bubbleTop,
            left: bubbleLeft,
            child: _buildBubble(),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble() {
    return GestureDetector(
      key: const ValueKey<String>('ai-assistant-bubble'),
      onPanUpdate: _onPanUpdate,
      onTap: () => setState(() => _open = !_open),
      child: Container(
        width: _bubbleSize,
        height: _bubbleSize,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.accent, Color(0xFFFF7A00), AppColors.gold],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x73FF8C00),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          _open ? Icons.close_rounded : Icons.auto_awesome,
          color: Colors.white,
          size: _open ? 22 : 26,
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context, double width, double height) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D000000),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              _panelHeader(context),
              _tabBar(),
              if (_tab == 'chat') ...[
                _promptChips(),
                Expanded(child: _messageList()),
                if (_typing) _typingRow(),
                _inputBar(),
              ] else Expanded(child: _helplineTab()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panelHeader(BuildContext context) {
    final chat = _tab == 'chat';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight, Color(0xFF0D3B66)],
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.accent, AppColors.gold],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  chat ? Icons.auto_awesome : Icons.headset_mic,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        chat
                            ? 'Acharya AI • VedaGPT'
                            : 'Devotee Care & Helpline',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (chat) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.7),
                          ),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                const Text(
                  '24x7 Vedic Instant Support',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          if (chat)
            IconButton(
              tooltip: 'Reset chat',
              onPressed: _resetChat,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          IconButton(
            tooltip: 'Minimize',
            onPressed: () => setState(() => _open = false),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Chat / Helpline switcher — the web widget's tab buttons (line 282).
  Widget _tabBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
            Color(0xFF0D3B66),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            _tabButton('chat', Icons.chat_rounded, 'VedaGPT AI'),
            const SizedBox(width: 4),
            _tabButton('helpline', Icons.phone_rounded, 'Direct Helpline'),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String id, IconData icon, String label) {
    final active = _tab == id;
    final color = active ? Colors.white : Colors.white.withValues(alpha: 0.65);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = id),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [AppColors.accent, AppColors.accentHover],
                  )
                : null,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// TAB 2 — the web widget's helpline pane (line 467): the toll-free number
  /// with Call / WhatsApp actions plus the callback shortcut. The web callback
  /// form posts nowhere (`handleCallbackSubmit` is client-side only), so the
  /// callback action lands here on the direct channels instead.
  Widget _helplineTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Text(
                'Toll-Free Devotional Helpline',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                AppConfig.supportPhone,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '24x7 Devotee Care · Verified Vedic Acharyas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _callAction()),
                  const SizedBox(width: 8),
                  Expanded(child: _whatsAppAction()),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
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
              const Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color: AppColors.accent,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Request Free Expert Acharya Callback',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'An Acharya calls you back within 15 minutes to guide on '
                'Muhurat, Samagri & Dakshina. Reach Devotee Care instantly on '
                'the toll-free line or WhatsApp:',
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.4,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _callAction()),
                  const SizedBox(width: 8),
                  Expanded(child: _whatsAppAction()),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentLight, Color(0xFFFFF7ED)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to book online?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Select date, time & language',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _open = false);
                  _openBookingFlow();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentHover],
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _callAction() => _miniAction(
    icon: Icons.call_rounded,
    label: 'Call Now',
    color: AppColors.accent,
    onTap: () => callNumber(_telNumber),
  );

  Widget _whatsAppAction() => _miniAction(
    icon: Icons.chat_rounded,
    label: 'WhatsApp',
    color: const Color(0xFF10B981),
    onTap: () => openWhatsApp(
      _waNumber,
      message: 'Namaste! I need help with my PanditIndia puja booking.',
    ),
  );

  Widget _miniAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _promptChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        itemCount: _quickPrompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, i) {
          final prompt = _quickPrompts[i];
          return GestureDetector(
            onTap: () => _send(prompt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                prompt,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentHover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _messageList() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      itemCount: _messages.length,
      itemBuilder: (context, i) => _bubble(_messages[i]),
    );
  }

  Widget _bubble(_ChatMsg msg) {
    final bot = msg.fromBot;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: bot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (bot) ...[
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.gold],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 12,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: bot ? AppColors.cream : AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(bot ? 4 : 14),
                  topRight: Radius.circular(bot ? 14 : 4),
                  bottomLeft: const Radius.circular(14),
                  bottomRight: const Radius.circular(14),
                ),
                border: bot ? Border.all(color: AppColors.border) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: bot ? AppColors.textDark : Colors.white,
                    ),
                  ),
                  if (msg.actions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.only(top: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final action in msg.actions)
                            _actionChip(action),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!bot) ...[
            const SizedBox(width: 7),
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 14,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Chip rendered under a bot bubble — the mobile counterpart of the web
  /// widget's `msg.actions` buttons (FloatingSupportWidget line 377).
  Widget _actionChip(_ChatAction action) {
    return GestureDetector(
      onTap: () => _handleAction(action),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 12,
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _typingRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.gold],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Acharya AI is chanting & preparing answer…',
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    final canSend = _input.text.trim().isNotEmpty && !_typing;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Ask about Pujas, Muhurats, Samagri, Pricing...',
                hintStyle: const TextStyle(fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                filled: true,
                fillColor: AppColors.cream,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.accent,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: canSend ? _send : null,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: canSend
                    ? const LinearGradient(
                        colors: [AppColors.accent, AppColors.gold],
                      )
                    : null,
                color: canSend ? null : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                size: 17,
                color: canSend ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
