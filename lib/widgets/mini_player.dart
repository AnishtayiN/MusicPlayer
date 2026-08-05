import 'package:flutter/material.dart';

import '../models/track.dart';
import '../theme/app_theme.dart';

class MiniPlayer extends StatelessWidget {
  final Track? currentTrack;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onClose;

  const MiniPlayer({
    super.key,
    this.currentTrack,
    required this.isPlaying,
    required this.onTap,
    required this.onPlayPause,
    required this.onNext,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (currentTrack == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.cardBorder)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: currentTrack!.artworkUrl != null
                      ? Image.network(
                          currentTrack!.artworkUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: AppTheme.placeholder,
                            child: Icon(Icons.music_note,
                                color: AppTheme.textMuted),
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          color: AppTheme.placeholder,
                          child: Icon(Icons.music_note,
                              color: AppTheme.textMuted),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentTrack!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        currentTrack!.artist,
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
                IconButton(
                  onPressed: onPlayPause,
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppTheme.iconActive,
                  ),
                ),
                IconButton(
                  onPressed: onNext,
                  icon: Icon(Icons.skip_next, color: AppTheme.iconActive),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close, color: AppTheme.textMuted),
                  tooltip: 'بستن و قطع پخش',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
