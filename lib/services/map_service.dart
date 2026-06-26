import 'package:url_launcher/url_launcher.dart';

class MapService {
  Uri googleMapsUri({
    required String address,
    double? latitude,
    double? longitude,
  }) {
    final query = latitude != null && longitude != null
        ? '$latitude,$longitude'
        : address.trim();
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
  }

  Future<void> openInGoogleMaps({
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    final uri = googleMapsUri(
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('cannot_open_maps');
    }
  }
}
