import 'dart:async';

import 'package:flutter/material.dart' hide Text;

import '../../core/theme/app_theme.dart';
import 'package:customer_app/core/l10n/localized_text.dart';

/// Opens the live ceremony stream modal (port of the web MODAL 7:
/// "LIVE CEREMONY STREAM").
Future<void> showLiveStreamModal(
  BuildContext context, {
  String? ceremony,
  String? acharya,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.8),
    // showDialog only injects a Material when its builder returns a Dialog
    // widget; this modal returns raw widgets, so supply one explicitly to
    // satisfy InkWell/DropdownButton/IconButton build-time assertions.
    builder: (_) => Material(
      type: MaterialType.transparency,
      child: LiveStreamModal(
        ceremony: ceremony ?? 'Puja',
        acharya: acharya ?? 'Acharya',
      ),
    ),
  );
}

class LiveStreamModal extends StatefulWidget {
  const LiveStreamModal({
    super.key,
    required this.ceremony,
    required this.acharya,
  });

  final String ceremony;
  final String acharya;

  @override
  State<LiveStreamModal> createState() => _LiveStreamModalState();
}

class _LiveStreamModalState extends State<LiveStreamModal> {
  static const List<(String, String)> _mantras = [
    ('gayatri', 'ॐ Gayatri Mantra (108 Times)'),
    ('mahamrityunjaya', 'ॐ Maha Mrityunjaya Mantra'),
    ('vishnu', 'ॐ Vishnu Sahasranama Stotram'),
    ('ganesh', 'ॐ Ganapati Atharvashirsha Chants'),
  ];

  String _mantra = 'gayatri';
  late final Timer _ticker;
  int _elapsed = 14 * 60 + 28;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += 1);
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  String get _clock {
    final h = (_elapsed ~/ 3600).toString().padLeft(2, '0');
    final m = ((_elapsed ~/ 60) % 60).toString().padLeft(2, '0');
    final s = (_elapsed % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: const Color(0xFF020617),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE11D48), Color(0xFFDC2626)],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            '1080P HD LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.ceremony,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Video canvas simulation ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B), width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 46)),
                    const SizedBox(height: 8),
                    const Text(
                      'Vedic Agni Hotra & Vastu Gayatri Chanting',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFCD34D),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Conducted by ${widget.acharya} • Live from Mandap',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _chip('👥 42 Devotees Connected', const Color(0xFFE2E8F0)),
                        _chip('⏱️ $_clock', const Color(0xFFFBBF24)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Mantra selector ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sacred Chants Channel:',
                      style: TextStyle(
                        color: Color(0xFFFCD34D),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF020617),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _mantra,
                          dropdownColor: const Color(0xFF0F172A),
                          isExpanded: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          items: _mantras
                              .map(
                                (m) => DropdownMenuItem<String>(
                                  value: m.$1,
                                  child: Text(m.$2),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(
                            () => _mantra = v ?? _mantra,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Close stream ──
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.stop_circle_outlined, size: 17),
                  label: const Text(
                    'Close Stream',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
