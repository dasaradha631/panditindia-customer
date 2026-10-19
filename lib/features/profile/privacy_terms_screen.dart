import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

/// Privacy Policy & Terms of Service screen — mobile counterpart of the
/// web footer's "Privacy Policy" / "Terms of Puja Service" links.
class PrivacyTermsScreen extends StatelessWidget {
  const PrivacyTermsScreen({super.key});

  static const String _privacy = '''
At PanditIndia, we are committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our application.

Information We Collect
• Personal details: name, email, phone number, date of birth, gender
• Birth details: date of birth, time of birth, birth place, and geographic coordinates (latitude / longitude) used for Vedic calculations
• Booking information: ceremony type, date, time slot, delivery address, and payment details
• Device data: IP address, device type, and app version for security and analytics

How We Use Your Information
• To create and manage your account
• To process bookings and connect you with verified Acharyas
• To generate Kundali, Panchang, and Muhurtham calculations based on your birth details
• To send booking confirmations, reminders, and ceremonial updates
• To improve the app experience and provide customer support

Data Sharing
• We share booking details only with the assigned Acharya and our logistics partners for ceremony fulfilment.
• We do not sell, rent, or trade your personal data to third parties.
• Payment processing is handled by secure, PCI-DSS compliant gateways.

Data Security
• All data in transit is encrypted using TLS/SSL.
• Personal data is stored on secure servers with access controls.
• You may request deletion of your account and associated data at any time by contacting support.

Cookies & Tracking
• The app uses local storage for session management and preferences.
• We do not use third-party advertising trackers.

Children's Privacy
• The app is not intended for users under 13 years of age.

Changes to This Policy
• We may update this policy periodically. Continued use of the app constitutes acceptance of the revised policy.

Contact Us
• For privacy-related questions, contact support through the in-app Support section or email support@panditindia.com.
''';

  static const String _terms = '''
Welcome to PanditIndia. By using this application you agree to the following Terms of Puja Service.

1. Service Description
PanditIndia connects devotees with verified Vedic Acharyas for conducting ceremonies (pujas, homams, and related rituals). We facilitate booking, coordination, and delivery of eco-samagri kits.

2. Booking & Confirmation
• All bookings are subject to Acharya availability and confirmation.
• A booking is confirmed only after payment is processed and an Acharya is assigned.
• You may reschedule a booking up to 24 hours before the ceremony date through the app.

3. Cancellation & Refund
• Cancellations made more than 48 hours before the ceremony are eligible for a full refund.
• Cancellations made between 24–48 hours before the ceremony are eligible for a 50% refund.
• Cancellations made less than 24 hours before the ceremony are non-refundable.
• Refunds are processed to the original payment method within 5–7 business days.

4. Eco-Samagri Kit
• Eco-samagri kits contain certified Vedic herbs and pure cow ghee sourced from verified suppliers.
• Kit contents are listed on the booking detail page and in the Eco-Kit specification sheet.
• Kits are delivered to the ceremony address provided at the time of booking.

5. Acharya Conduct
• All Acharyas on the platform are verified through partner Gurukuls.
• Dakshina (offering) amounts are listed at the time of booking and are not subject to additional demands.

6. User Responsibilities
• You agree to provide accurate birth details for Vedic calculations.
• You are responsible for ensuring the ceremony venue is accessible on the scheduled date.
• You agree to treat Acharyas with respect and dignity.

7. Limitation of Liability
• PanditIndia facilitates the connection between devotees and Acharyas. We are not responsible for ceremony outcomes.
• Our liability is limited to the booking amount paid.

8. Governing Law
• These terms are governed by the laws of India.

9. Contact
• For questions about these terms, contact support through the in-app Support section or email support@panditindia.com.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const GradientAppBar(title: 'Privacy & Terms'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              body: _privacy,
            ),
            const SizedBox(height: 16),
            _sectionCard(
              icon: Icons.description_outlined,
              title: 'Terms of Puja Service',
              body: _terms,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body.trim(),
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.55,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
