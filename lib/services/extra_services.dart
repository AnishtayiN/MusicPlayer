import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/track.dart';
import '../utils/web_bridge.dart';

class TrackMeta {
  final String? coverDataUrl;
  final String? album;
  final int? year;
  final int? bitrateKbps;
  TrackMeta({this.coverDataUrl, this.album, this.year, this.bitrateKbps});
}

Future<TrackMeta?> fetchMetadata(Track t) async {
  if (kIsWeb && t.localPath != null) {
    final m = await getMetadataNative(t.localPath!);
    if (m != null) {
      return TrackMeta(
        coverDataUrl: m['cover'] as String?,
        album: m['album'] as String?,
        year: m['year'] as int?,
        bitrateKbps: m['bitrate'] as int?,
      );
    }
  }
  return null;
}

class LyricLine {
  final Duration time;
  final String text;
  LyricLine(this.time, this.text);
}

class LyricsResult {
  final List<LyricLine> synced;
  final String plain;
  LyricsResult({this.synced = const [], this.plain = ''});
  bool get isSynced => synced.isNotEmpty;
}

Future<LyricsResult?> loadLyrics(Track t, String? saved) async {
  if (saved != null && saved.trim().isNotEmpty) return _parse(saved);

  if (t.isLocal && t.localPath != null) {
    final base = t.localPath!.replaceAll(RegExp(r'\.[^.]+$'), '');
    for (final ext in ['.lrc', '.txt']) {
      final p = '$base$ext';
      String? text;
      if (kIsWeb) {
        text = await readFileTextNative(p);
      } else {
        final f = File(p);
        if (await f.exists()) text = await f.readAsString();
      }
      if (text != null && text.trim().isNotEmpty) {
        final r = _parse(text);
        if (r != null) return r;
      }
    }
  }

  try {
    final q = Uri.encodeComponent('${t.artist} ${t.title}');
    final r = await http
        .get(Uri.parse('https://lrclib.net/api/search?q=$q'))
        .timeout(const Duration(seconds: 8));
    if (r.statusCode == 200) {
      final list = jsonDecode(r.body) as List;
      if (list.isNotEmpty) {
        final m = list.first as Map<String, dynamic>;
        final text = (m['syncedLyrics'] as String?) ??
            (m['plainLyrics'] as String?) ??
            '';
        final res = _parse(text);
        if (res != null) return res;
      }
    }
  } catch (_) {}

  return null;
}

LyricsResult? _parse(String text) {
  final lines = <LyricLine>[];
  final plain = StringBuffer();
  for (final raw in text.split('\n')) {
    final m = RegExp(r'\[(\d+):(\d+)(?:[.:](\d+))?\]').firstMatch(raw);
    if (m != null) {
      final min = int.parse(m.group(1)!);
      final sec = int.parse(m.group(2)!);
      final frac = m.group(3);
      final ms = frac == null
          ? 0
          : int.parse(frac) * (frac.length >= 3 ? 1 : 10);
      final txt = raw.replaceFirst(RegExp(r'\[[^\]]*\]'), '').trim();
      lines.add(LyricLine(
          Duration(minutes: min, seconds: sec, milliseconds: ms), txt));
    } else if (raw.trim().isNotEmpty) {
      plain.writeln(raw.trim());
    }
  }
  if (lines.isNotEmpty) return LyricsResult(synced: lines);
  if (plain.toString().trim().isNotEmpty) {
    return LyricsResult(plain: plain.toString());
  }
  return null;
}
