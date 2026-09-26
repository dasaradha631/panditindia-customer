import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/empty_state.dart';

/// Branded holding screen for the destinations scheduled in later stages
/// (PDF sections 11/14 - Services, Pandits, Events, Gallery, Blogs, ...).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.subtitle = AppStrings.comingSoonSubtitle,
    this.icon,
    this.showBack = true,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppHeader(showBack: showBack),
      body: EmptyState(
        icon: icon ?? Icons.auto_awesome_rounded,
        title: title,
        subtitle: subtitle,
      ),
    );
  }
}
