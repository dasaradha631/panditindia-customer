import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'brand_logo.dart';

/// Mobile header: hamburger, centred brand lockup and a trailing action
/// slot (notification bell on Home). Navy by default to match the
/// reference design's chrome.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.onMenuTap,
    this.trailing,
    this.showBack = false,
    this.onBackTap,
    this.showTagline = true,
    this.background,
  });

  final VoidCallback? onMenuTap;
  final Widget? trailing;
  final bool showBack;
  final VoidCallback? onBackTap;
  final bool showTagline;
  final Color? background;

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    final Color bg = background ?? AppColors.navy;
    final bool dark = bg != AppColors.surface && bg != AppColors.cream;
    return Material(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Center(
                child: BrandLockup(
                  size: showTagline ? 40 : 34,
                  onDark: dark,
                  showTagline: showTagline,
                ),
              ),
              Positioned(
                left: 6,
                child: IconButton(
                  tooltip: 'Menu',
                  onPressed: onMenuTap ??
                      (showBack ? () => Navigator.of(context).maybePop() : null),
                  icon: Icon(
                    showBack ? Icons.arrow_back_ios_new_rounded : Icons.menu_rounded,
                    size: 22,
                    color: dark ? AppColors.onDark : AppColors.ink,
                  ),
                ),
              ),
              if (trailing != null) Positioned(right: 6, child: trailing!),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular soft icon button used for bell / profile actions.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.badge = false,
    this.dark = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool badge;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: badge,
        smallSize: 8,
        backgroundColor: AppColors.primary,
        child: Icon(
          icon,
          size: 22,
          color: dark ? AppColors.onDark : AppColors.ink,
        ),
      ),
    );
  }
}
