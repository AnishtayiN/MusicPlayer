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

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
    this.artworkUrl,
    this.isLocal = false,
    this.localPath,
    this.durationMs,
  });

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? url,
    String? artworkUrl,
    bool? isLocal,
    String? localPath,
    int? durationMs,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      url: url ?? this.url,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      isLocal: isLocal ?? this.isLocal,
      localPath: localPath ?? this.localPath,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}
