import 'package:hive_flutter/hive_flutter.dart';

part 'track.g.dart';

@HiveType(typeId: 0)
class Track {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String artist;
  @HiveField(3)
  final String url;
  @HiveField(4)
  final String? artworkUrl;
  @HiveField(5)
  final bool isLocal;
  @HiveField(6)
  final String? localPath;
  @HiveField(7)
  final int? durationMs;
  @HiveField(8)
  final String? album;
  @HiveField(9)
  final int? year;
  @HiveField(10)
  final int? artworkId;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    this.artworkUrl,
    this.isLocal = false,
    this.localPath,
    this.durationMs,
    this.album,
    this.year,
    this.artworkId,
  });

  String get format {
    final p = (localPath ?? url).toLowerCase();
    final i = p.lastIndexOf('.');
    return i >= 0 ? p.substring(i + 1).toUpperCase() : '';
  }
}
