import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _githubApiUrl =
      'https://api.github.com/repos/AnishtayiN/sonic_wave/releases/latest';

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(_githubApiUrl));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      final latestVersion = (data['tag_name'] as String).replaceFirst('v', '');

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isNewerVersion(latestVersion, currentVersion)) {
        final assets = data['assets'] as List;
        String? downloadUrl;

        for (final asset in assets) {
          final name = asset['name'] as String;
          if (name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String;
            break;
          }
        }

        if (downloadUrl != null) {
          return UpdateInfo(
            version: latestVersion,
            downloadUrl: downloadUrl,
            releaseNotes: data['body'] as String? ?? 'بدون توضیحات',
          );
        }
      }
    } catch (e) {
      // Network error or parsing error
    }

    return null;
  }

  bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final latestPart = i < latestParts.length ? latestParts[i] : 0;
      final currentPart = i < currentParts.length ? currentParts[i] : 0;

      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }

    return false;
  }

  Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
  });
}
