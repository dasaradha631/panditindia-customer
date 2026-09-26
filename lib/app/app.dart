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
    );
  }
}
