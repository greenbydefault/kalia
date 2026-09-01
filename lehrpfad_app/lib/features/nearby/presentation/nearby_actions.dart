import 'package:url_launcher/url_launcher.dart';

/// Öffnet die Website in einer externen App.
Future<void> openNearbyWebsite(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// `tel:`-Link aus der hinterlegten Nummer.
Future<void> callNearbyPlace(String telefon) async {
  final digits = telefon.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.isEmpty) return;
  await launchUrl(Uri(scheme: 'tel', path: digits));
}
