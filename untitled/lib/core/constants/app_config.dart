class AppConfig {
  AppConfig._();

  static const String baseUrl = 'http://76.13.14.130/api/v1';

  static String get storageHost {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null) return 'http://76.13.14.130';
    final port = uri.port > 0 && uri.port != 80 && uri.port != 443 ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  static String storageUrl(String relativePath) => '$storageHost/storage/$relativePath';

  static String absoluteUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final clean = path.startsWith('/storage/') ? path.substring(9) : path;
    return storageUrl(clean);
  }

  static const String termsUrl = 'https://sitter.app/terms';
  static const String privacyUrl = 'https://sitter.app/privacy';
}


