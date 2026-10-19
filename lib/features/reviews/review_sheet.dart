import 'package:flutter/material.dart' hide Text;

import '../../core/storage/review_store.dart';
import '../../core/theme/app_theme.dart';
import '../../services/booking_service.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

/// Shows the "Rate your experience!" modal (matches the web ReviewModal) and
/// records the prompt so it never auto-opens twice for the same booking.
Future<void> showReviewSheet(
  BuildContext context, {
  required int bookingId,
  required String ceremonyName,
  String? panditName,
  String? devoteeName,
  VoidCallback? onDone,
}) async {
  await showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.8),
    builder: (_) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: ReviewSheet(
          bookingId: bookingId,
          ceremonyName: ceremonyName,
          panditName: panditName,
          devoteeName: devoteeName,
          onDone: onDone,
        ),
      ),
    ),
  );
  await ReviewStore.markPrompted(bookingId);
}

class ReviewSheet extends StatefulWidget {
  const ReviewSheet({
    super.key,
    required this.bookingId,
    required this.ceremonyName,
    this.panditName,
    this.devoteeName,
    this.onDone,
  });

  final int bookingId;
  final String ceremonyName;
  final String? panditName;
  final String? devoteeName;
  final VoidCallback? onDone;

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  final BookingService _service = BookingService();
  final _title = TextEditingController();
  final _text = TextEditingController();
  int rating = 0;
  bool saving = false;
  bool submitted = false;
  String? error;

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (rating == 0) {
      setState(() => error = 'Please select a star rating.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final err = await _service.submitReview(
      widget.bookingId,
      rating: rating,
      title: _title.text.trim().isEmpty
          ? 'Ceremony Review'
          : _title.text.trim(),
      text: _text.text.trim(),
      isAnonymous: false,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        saving = false;
        error = err;
      });
      return;
    }
    await ReviewStore.markReviewed(widget.bookingId);
    if (!mounted) return;
    setState(() {
      saving = false;
      submitted = true;
    });
    widget.onDone?.call();
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) Navigator.of(context).pop();
  }

  String get _initials {
    final name = (widget.panditName ?? widget.devoteeName ?? '').trim();
    if (name.isEmpty) return 'OM';
    return name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF021F2C), Color(0xFF01141D)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Orange header with straddling avatar ──
            SizedBox(
              height: 128,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent,
                            Color(0xFFFBBF24),
                            Color(0xFFE07B00),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: _close,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -40,
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF021F2C),
                            width: 4,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Body ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 52, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Rate your experience!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      text: 'Your ceremony ',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFCBD5E1),
                      ),
                      children: [
                        TextSpan(
                          text: widget.ceremonyName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const TextSpan(text: ' with '),
                        TextSpan(
                          text: widget.panditName ?? 'the Acharya',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const TextSpan(text: ' was completed successfully.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  if (submitted) _thankYou() else _form(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thankYou() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Color(0x3310B981),
            child: Icon(
              Icons.check_circle_rounded,
              size: 40,
              color: Color(0xFF34D399),
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Thank You!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your blessing has been shared with the Acharya.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFFA7F3D0)),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final filled = i < rating;
            return GestureDetector(
              onTap: () => setState(() {
                rating = i + 1;
                error = null;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 40,
                  color: filled
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF475569),
                  shadows: filled
                      ? const [Shadow(color: Color(0x99FBBF24), blurRadius: 10)]
                      : null,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        _label('Review Title (Optional)'),
        const SizedBox(height: 6),
        _textField(_title, 'e.g. Beautiful Ceremony'),
        const SizedBox(height: 12),
        _label('Any feedback? (Optional)'),
        const SizedBox(height: 6),
        _textField(
          _text,
          'Share your experience about the mantras, punctuality, and overall divine feeling...',
          maxLines: 4,
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFFFB7185)),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Skip',
                background: Colors.white.withValues(alpha: 0.05),
                border: Colors.white.withValues(alpha: 0.1),
                foreground: Colors.white,
                onPressed: saving ? null : _close,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: saving ? 'Submitting...' : 'Submit Review',
                gradient: const [Color(0xFF059669), Color(0xFF0D9488)],
                foreground: Colors.white,
                bold: true,
                busy: saving,
                onPressed: saving ? null : _submit,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: const Color(0xFFFDE68A).withValues(alpha: 0.9),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13.5, color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.foreground,
    required this.onPressed,
    this.background,
    this.border,
    this.gradient,
    this.bold = false,
    this.busy = false,
  });

  final String label;
  final Color foreground;
  final VoidCallback? onPressed;
  final Color? background;
  final Color? border;
  final List<Color>? gradient;
  final bool bold;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Colors.white,
            ),
          )
        : Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: foreground,
            ),
          );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            gradient: gradient != null
                ? LinearGradient(colors: gradient!)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: border != null ? Border.all(color: border!) : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
