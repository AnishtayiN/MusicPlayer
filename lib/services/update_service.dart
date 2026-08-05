import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String githubOwner = 'AnishtayiN';
  static const String githubRepo = 'MusicPlayer';

  static const String _definedVersion =
      String.fromEnvironment('APP_VERSION');

  static String get githubApiUrl =>
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  /// نسخه فعلی اپ (اول dart-define، بعد PackageInfo)
  static Future<String> getCurrentVersion() async {
    if (_definedVersion.isNotEmpty) return _definedVersion;
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version.trim().isEmpty ? '0.0.0' : info.version.trim();
    } catch (_) {
      return '0.0.0';
    }
  }

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(
            Uri.parse(githubApiUrl),
            headers: const {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String?;
      if (tagName == null) return null;

      final latestVersion = tagName.replaceFirst('v', '').trim();
      final currentVersion = await getCurrentVersion();

      if (!_isNewerVersion(latestVersion, currentVersion)) return null;

      final assets = (data['assets'] as List?) ?? const [];
      final downloadUrl = _pickAssetUrl(assets);
      if (downloadUrl == null) return null;

      return UpdateInfo(
        version: latestVersion,
        downloadUrl: downloadUrl,
        releaseNotes: (data['body'] as String?) ?? 'توضیحاتی ثبت نشده.',
      );
    } catch (_) {
      return null;
    }
  }

  String? _pickAssetUrl(List assets) {
    String? apkUrl;
    String? exeUrl;

    for (final item in assets) {
      final asset = item as Map<String, dynamic>;
      final name = (asset['name'] as String? ?? '').toLowerCase();
      final url = asset['browser_download_url'] as String?;
      if (url == null) continue;
      if (name.endsWith('.apk')) apkUrl = url;
      if (name.endsWith('.exe')) exeUrl = url;
    }

    if (kIsWeb) return exeUrl ?? apkUrl;

    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return exeUrl ?? apkUrl;
      case TargetPlatform.android:
      default:
        return apkUrl ?? exeUrl;
    }
  }

  bool _isNewerVersion(String latest, String current) {
    final latestParts =
        latest.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final currentParts =
        current.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final l = i < latestParts.length ? latestParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.platformDefault);
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
