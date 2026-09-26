import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/ornament_divider.dart';
import '../../core/widgets/temple_scene.dart';
import '../../services/session_service.dart';

/// Splash (PDF section 11 / first-day checklist item 11).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  int _activeDot = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    bool signedIn = false;
    try {
      signedIn = await SessionService.instance.hasSession();
    } catch (_) {
      signedIn = false;
    }

    for (int i = 0; i < 4; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 520));
      if (!mounted) return;
      setState(() => _activeDot = i);
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    context.go(signedIn ? '/home' : '/welcome');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.darkStatus,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(
              AppAssets.splash,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext context, Object error,
                      StackTrace? stackTrace) =>
                  CustomPaint(painter: TempleScenePainter()),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0x66000000), Color(0xCC04101B)],
                  stops: <double>[0, 1],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 46),
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _controller,
                        curve: Curves.easeOut,
                      ),
                      child: Column(
                        children: <Widget>[
                          const BrandLogo(size: 96, onDark: true),
                          const SizedBox(height: 16),
                          const BrandLockup(
                            size: 54,
                            onDark: true,
                            alignment: CrossAxisAlignment.center,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(0.35, 1, curve: Curves.easeOut),
                      ),
                      child: Column(
                        children: <Widget>[
                          Text(
                            AppStrings.splashHeadline,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  color: AppColors.onDark,
                                  height: 1.32,
                                ),
                          ),
                          const SizedBox(height: 22),
                          const OrnamentDivider(),
                          const SizedBox(height: 26),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List<Widget>.generate(4, (int index) {
                              final bool active = index == _activeDot;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 320),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                width: active ? 10 : 7,
                                height: active ? 10 : 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.onDark.withValues(alpha: 0.35),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            AppStrings.loading,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppColors.onDarkMuted,
                                  letterSpacing: 0.6,
                                ),
                          ),
                          const SizedBox(height: 34),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
