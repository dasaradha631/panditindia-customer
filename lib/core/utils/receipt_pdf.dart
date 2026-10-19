import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../models/booking.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Official 80G receipt PDF generation and sharing — mobile parity for the
/// web `receiptGenerator.js` (same GSTIN, Section 80G copy and helpline).
class ReceiptPdf {
  ReceiptPdf._();

  static const String gstin = '07AAACP0123M1Z9';
  static const String helpline = '1800-890-8334';
  static const String supportEmail = 'info@panditindia.com';

  static String _money(String value) => value.replaceAll('\u20B9', 'Rs. ');

  static pw.Widget _row(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 130,
              child: pw.Text(
                label,
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: const pw.TextStyle(fontSize: 9.5),
              ),
            ),
          ],
        ),
      );

  static pw.Widget _section(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.amber800,
          ),
        ),
      );

  static pw.Document build(Booking b) {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.amber700, width: 1.2),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PANDITINDIA',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.amber800,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Official Vedic Ceremony Receipt & 80G Tax Invoice',
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Receipt ID: ${b.displayId}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'GSTIN: $gstin',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _section('Ceremony Details'),
          _row('Ceremony', b.ceremony ?? 'Sacred Ceremony'),
          _row('Booking Reference', b.displayId),
          _row('Date', Fmt.date(b.bookingDate)),
          _row('Muhurat Slot', b.timeSlot ?? '-'),
          _row('Language', b.language ?? 'Hindi & Sanskrit'),
          _row('Devotee', b.fullName ?? '-'),
          _row('Mobile', b.mobile ?? '-'),
          _row(
            'Venue',
            '${b.address ?? ''} ${b.city ?? ''} ${b.pincode ?? ''}'.trim(),
          ),
          _row('Assigned Acharya', b.assignedPandit ?? '-'),
          _section('Payment Summary'),
          _row('Amount Paid', _money(b.priceDisplay)),
          if ((b.ecokitPrice ?? 0) > 0)
            _row('of which Eco-Samagri Kit', 'Rs. ${b.ecokitPrice!.toInt()}'),
          if ((b.samagri ?? '').isNotEmpty) _row('Samagri', b.samagri!),
          _section('Tax Exemption Benefit'),
          pw.Text(
            'Eligible for deduction under Section 80G of the Indian Income Tax '
            'Act, 1961, on donations made towards propagation of Indian '
            'cultural heritage and religious ceremonies.',
            style: const pw.TextStyle(fontSize: 9.5),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 4),
          pw.Text(
            'Thank you for choosing PanditIndia. Our certified Acharya will '
            'arrive with all ritual arrangements as booked.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            '24/7 Devotional Helpline: $helpline | Support: $supportEmail',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
    return doc;
  }

  static Future<void> _shareAll(
    BuildContext context,
    List<Booking> bookings,
  ) async {
    if (bookings.isEmpty) return;
    try {
      final dir = await getTemporaryDirectory();
      final files = <XFile>[];
      for (final b in bookings) {
        final bytes = await build(b).save();
        final cleanId = b.displayId.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '');
        final file = File('${dir.path}/PanditIndia_Receipt_$cleanId.pdf');
        await file.writeAsBytes(bytes);
        files.add(XFile(file.path));
      }
      await SharePlus.instance.share(
        ShareParams(
          files: files,
          text: 'PanditIndia official 80G receipts (${files.length})',
        ),
      );
    } catch (_) {
      if (context.mounted) {
        showAppToast(
          context,
          'Could not generate receipt PDFs. Please try again.',
          type: ToastType.error,
          title: 'Receipt',
        );
      }
    }
  }

  static Future<void> share(BuildContext context, Booking b) =>
      _shareAll(context, [b]);

  static Future<void> shareAll(BuildContext context, List<Booking> bookings) =>
      _shareAll(context, bookings);
}
