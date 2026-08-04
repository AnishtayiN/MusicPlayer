import 'package:flutter/material.dart';
import '../models/track.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final bool isCurrentTrack;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const TrackTile({
    super.key,
    required this.track,
    required this.isCurrentTrack,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isCurrentTrack
                ? const LinearGradient(
                    colors: [
                      Color.fromRGBO(139, 92, 246, 0.30),
                      Color.fromRGBO(6, 182, 212, 0.16),
                    ],
                  )
                : null,
            border: isCurrentTrack
                ? Border.all(color: const Color.fromRGBO(139, 92, 246, 0.55))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF1E1B4B),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: track.artworkUrl != null
                      ? Image.network(
                          track.artworkUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.music_note,
                              color: Colors.white54,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.music_note,
                            color: Colors.white54,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isCurrentTrack
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrentTrack)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.equalizer,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              IconButton(
                onPressed: onFavoriteTap,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? const Color(0xFF8B5CF6)
                      : Colors.white38,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
