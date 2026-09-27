import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../services/session_service.dart';

/// Side menu matching the reference design board: navy panel, brand + close
/// header, reference destinations, Language and the orange "Book Puja Now"
/// action (PDF section 13 - hamburger drawer destinations).
class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    await SessionService.instance.clear();
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.logoutSuccess)),
    );
    if (context.mounted) context.go('/welcome');
  }

  void _go(BuildContext context, String path) {
    Navigator.of(context).pop();
    context.go(path);
  }

  void _languageSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 14),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.menuLanguage,
                style: Theme.of(sheetContext).textTheme.titleSmall,
              ),
              ListTile(
                leading: const Icon(Icons.translate_rounded,
                    color: AppColors.primary),
                title: const Text('English'),
                trailing:
                    const Icon(Icons.check_circle, color: AppColors.primary),
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
              ListTile(
                leading: const Icon(Icons.translate_rounded,
                    color: AppColors.primary),
                title: const Text('हिन्दी'),
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentPath = GoRouterState.of(context).uri.path;

    return Drawer(
      backgroundColor: AppColors.navy,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
              child: Row(
                children: <Widget>[
                  const BrandLockup(
                    size: 38,
                    onDark: true,
                    showTagline: false,
                    alignment: CrossAxisAlignment.center,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        size: 26, color: AppColors.onDark),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.navySoft, thickness: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: <Widget>[
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: AppStrings.menuHome,
                    active: currentPath == '/home',
                    onTap: () => _go(context, '/home'),
                  ),
                  _DrawerItem(
                    icon: Icons.grid_view_outlined,
                    activeIcon: Icons.grid_view_rounded,
                    label: AppStrings.menuServices,
                    active: currentPath == '/services',
                    onTap: () => _go(context, '/services'),
                  ),
                  _DrawerItem(
                    icon: Icons.face_outlined,
                    activeIcon: Icons.face_rounded,
                    label: AppStrings.menuPandits,
                    active: currentPath == '/pandits',
                    onTap: () => _go(context, '/pandits'),
                  ),
                  _DrawerItem(
                    icon: Icons.celebration_outlined,
                    activeIcon: Icons.celebration_rounded,
                    label: AppStrings.menuEvents,
                    active: currentPath == '/events',
                    onTap: () => _go(context, '/events'),
                  ),
                  _DrawerItem(
                    icon: Icons.photo_library_outlined,
                    activeIcon: Icons.photo_library_rounded,
                    label: AppStrings.menuGallery,
                    active: currentPath == '/gallery',
                    onTap: () => _go(context, '/gallery'),
                  ),
                  _DrawerItem(
                    icon: Icons.article_outlined,
                    activeIcon: Icons.article_rounded,
                    label: AppStrings.menuBlogs,
                    active: currentPath == '/blogs',
                    onTap: () => _go(context, '/blogs'),
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    activeIcon: Icons.info_rounded,
                    label: AppStrings.menuAbout,
                    active: currentPath == '/about',
                    onTap: () => _go(context, '/about'),
                  ),
                  _DrawerItem(
                    icon: Icons.mail_outline_rounded,
                    activeIcon: Icons.mail_rounded,
                    label: AppStrings.menuContact,
                    active: currentPath == '/contact',
                    onTap: () => _go(context, '/contact'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Divider(color: AppColors.navySoft, thickness: 1),
                  ),
                  FutureBuilder<bool>(
                    future: SessionService.instance.hasSession(),
                    builder: (BuildContext context,
                        AsyncSnapshot<bool> snapshot) {
                      final bool signedIn = snapshot.data ?? false;
                      if (signedIn) {
                        return _DrawerItem(
                          icon: Icons.logout_rounded,
                          label: AppStrings.menuLogout,
                          onTap: () => _logout(context),
                        );
                      }
                      return _DrawerItem(
                        icon: Icons.login_rounded,
                        label: AppStrings.menuSignIn,
                        active: currentPath == '/login' ||
                            currentPath == '/register',
                        onTap: () => _go(context, '/login'),
                      );
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.translate_rounded,
                    label: AppStrings.menuLanguage,
                    trailing: 'English',
                    onTap: () {
                      Navigator.of(context).pop();
                      _languageSheet(context);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _go(context, '/services'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onDark,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.temple_buddhist_rounded, size: 19),
                      SizedBox(width: 9),
                      Text(AppStrings.bookPujaNow),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.activeIcon,
    this.trailing,
    this.active = false,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foreground =
        active ? AppColors.primary : AppColors.onDarkMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: active
            ? AppColors.primary.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: <Widget>[
                Icon(
                  active ? (activeIcon ?? icon) : icon,
                  size: 21,
                  color: foreground,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.onDarkMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
