import 'package:flutter/material.dart';

import '../models/track.dart';
import '../theme/app_theme.dart';

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
                ? LinearGradient(
                    colors: [
                      AppTheme.accent.withOpacity(AppTheme.isDark ? 0.30 : 0.15),
                      AppTheme.accent2.withOpacity(AppTheme.isDark ? 0.16 : 0.08),
                    ],
                  )
                : null,
            border: isCurrentTrack
                ? Border.all(color: AppTheme.accent.withOpacity(0.55))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.placeholder,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: track.artworkUrl != null
                      ? Image.network(
                          track.artworkUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(Icons.music_note,
                                color: AppTheme.textMuted),
                          ),
                        )
                      : Center(
                          child: Icon(Icons.music_note,
                              color: AppTheme.textMuted),
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
                        color: AppTheme.textPrimary,
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
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrentTrack)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.equalizer,
                      color: AppTheme.textSecondary, size: 20),
                ),
              IconButton(
                onPressed: onFavoriteTap,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppTheme.accent : AppTheme.iconInactive,
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
