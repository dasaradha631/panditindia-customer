import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../services/session_service.dart';

/// Navigation drawer (PDF section 13 - hamburger drawer destinations).
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
                trailing: const Icon(Icons.check_circle, color: AppColors.primary),
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
    final ThemeData theme = Theme.of(context);
    return Drawer(
      backgroundColor: AppColors.cream,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: FutureBuilder<Object?>(
                future: SessionService.instance.user(),
                builder: (BuildContext context, AsyncSnapshot<Object?> snap) {
                  final dynamic user = snap.data;
                  final String name =
                      '${user?.fullName ?? 'Devotee'}';
                  final String contact =
                      '${user?.email ?? user?.mobile ?? 'Sign in to sync your bookings'}';
                  final String initials = name
                      .trim()
                      .split(RegExp(r'\s+'))
                      .map((String p) => p.isEmpty ? '' : p.substring(0, 1))
                      .take(2)
                      .join()
                      .toUpperCase();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 58,
                            height: 58,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.onDark.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.8),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              initials.isEmpty ? 'P' : initials,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.onDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 19,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.onDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  contact,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.onDarkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go('/profile');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.onDark,
                            backgroundColor:
                                AppColors.onDark.withValues(alpha: 0.12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.person_outline_rounded,
                              size: 17),
                          label: const Text('View Profile'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: <Widget>[
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: AppStrings.menuHome,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/home');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.grid_view_outlined,
                    label: AppStrings.menuServices,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/services');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.face_outlined,
                    label: AppStrings.menuPandits,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/pandits');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.celebration_outlined,
                    label: AppStrings.menuEvents,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/events');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.photo_library_outlined,
                    label: AppStrings.menuGallery,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/gallery');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.article_outlined,
                    label: AppStrings.menuBlogs,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/blogs');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    label: AppStrings.menuAbout,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/about');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.mail_outline_rounded,
                    label: AppStrings.menuContact,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/contact');
                    },
                  ),
                  const Divider(indent: 18, endIndent: 18),
                  _DrawerItem(
                    icon: Icons.event_note_outlined,
                    label: AppStrings.menuBookings,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/bookings');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline_rounded,
                    label: AppStrings.menuProfile,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/profile');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.place_outlined,
                    label: AppStrings.menuAddresses,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/addresses');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.support_agent_rounded,
                    label: AppStrings.menuHelp,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/help');
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
                  const Divider(indent: 18, endIndent: 18),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    label: AppStrings.menuLogout,
                    destructive: true,
                    onTap: () => _logout(context),
                  ),
                ],
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
    this.destructive = false,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        size: 21,
        color: destructive ? AppColors.error : AppColors.muted,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: destructive ? AppColors.error : AppColors.ink,
        ),
      ),
      trailing: trailing == null
          ? null
          : Text(trailing!, style: theme.textTheme.labelSmall),
      onTap: onTap,
    );
  }
}
