class AppConfig {
  static const String baseUrl = 'https://api.panditindia.com';

  /// Resolves a site-relative asset path to a full URL. Absolute `http(s)`
  /// URLs (e.g. the `image_url` values returned by `GET /pujas`) are passed
  /// through unchanged.
  static String assetUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final clean = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$clean';
  }

  static const String appName = 'PanditIndia';
  static const String tagline = 'Vedic Enterprise Platform';

  /// Toll-free helpline — digit-only form for `tel:` URIs (same as web
  /// `tel:18008908334`). Do NOT put `+`, spaces or dashes here.
  static const String supportPhone = '18008908334';

  /// Human-readable form for on-screen display.
  static const String supportPhoneDisplay = '1800-890-VEDA (8334)';

  /// WhatsApp support line — digits only, for `wa.me/<number>` (same as web
  /// `https://wa.me/919876543210`).
  static const String supportWhatsApp = '919876543210';

  static const String supportEmail = 'info@panditindia.com';
  static const Duration requestTimeout = Duration(seconds: 15);
}
