/// Supported build environments (PDF section 16 - environment configuration).
enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment fromName(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'staging':
        return AppEnvironment.staging;
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      default:
        return AppEnvironment.development;
    }
  }

  bool get isProduction => this == AppEnvironment.production;
}
