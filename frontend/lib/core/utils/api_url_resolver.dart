class ApiUrlResolver {
  ApiUrlResolver._();

  static const _mediaLogoPrefix = '/api/v1/media/logos/';
  static const _localHosts = {
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
    '::1',
  };

  /// Resuelve rutas relativas, URLs locales antiguas y conserva URLs externas.
  static String resolve(String apiBaseUrl, String? pathOrUrl) {
    return resolveMediaUrl(apiBaseUrl, pathOrUrl);
  }

  static String resolveMediaUrl(String apiBaseUrl, String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) {
      return '';
    }

    final trimmed = pathOrUrl.trim();
    final apiOrigin = Uri.parse(apiBaseUrl).origin;

    if (trimmed.startsWith(_mediaLogoPrefix)) {
      return '$apiOrigin$trimmed';
    }

    if (trimmed.startsWith('/')) {
      return '$apiOrigin$trimmed';
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final parsed = Uri.tryParse(trimmed);
      if (parsed == null) {
        return trimmed;
      }

      final mediaPath = _extractMediaLogoPath(parsed);
      if (mediaPath != null && _isLocalApiHost(parsed.host)) {
        return '$apiOrigin$mediaPath';
      }

      return trimmed;
    }

    return '$apiOrigin/$trimmed';
  }

  static bool _isLocalApiHost(String host) {
    final normalized = host.toLowerCase();
    if (_localHosts.contains(normalized)) {
      return true;
    }
    return normalized == '0.0.0.0';
  }

  static String? _extractMediaLogoPath(Uri uri) {
    final path = uri.path;
    final markerIndex = path.indexOf(_mediaLogoPrefix);
    if (markerIndex >= 0) {
      return path.substring(markerIndex);
    }
    return null;
  }
}
