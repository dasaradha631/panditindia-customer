import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';
import 'theme/theme.dart';

/// Application root: theme + router (PDF section 7 - lib/app/app.dart).
class PanditIndiaApp extends StatefulWidget {
  const PanditIndiaApp({super.key, this.router});

  /// Injectable for widget tests / previews.
  final GoRouter? router;

  @override
  State<PanditIndiaApp> createState() => _PanditIndiaAppState();
}

class _PanditIndiaAppState extends State<PanditIndiaApp> {
  late final GoRouter _router = widget.router ?? createRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PanditIndia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        if (!kIsWeb) return child;
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 500) {
              return Container(
                color: const Color(0xFF181113), // Dark background for web desktop view
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              );
            }
            return child;
          },
        );
      },
    );
  }
}
