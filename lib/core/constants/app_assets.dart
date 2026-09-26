/// Central asset registry (PDF section 7 - core/constants/app_assets.dart).
///
/// Every path points at a file inside `assets/`. Drop real artwork into these
/// paths and it is picked up automatically - widgets built on top of these
/// paths fall back to painted placeholders while the files are still missing,
/// so the app never renders a broken image.
class AppAssets {
  AppAssets._();

  static const String images = 'assets/images';
  static const String logo = '$images/logo.png';
  static const String logoWhite = '$images/logo_white.png';
  static const String splash = '$images/splash/splash_bg.png';
  static const String banners = '$images/banners';
  static const String services = '$images/services';
  static const String pandits = '$images/pandits';
  static const String events = '$images/events';
  static const String icons = 'assets/icons';
}
