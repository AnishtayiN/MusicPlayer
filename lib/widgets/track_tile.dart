import 'package:flutter/material.dart';

import '../models/track.dart';
import '../theme/app_theme.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final bool isCurrentTrack;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final ValueChanged<String>? onMenuAction;

  const TrackTile({
    super.key,
    required this.track,
    required this.isCurrentTrack,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
    this.onMenuAction,
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
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert,
                    color: AppTheme.textMuted, size: 20),
                color: AppTheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (v) => onMenuAction?.call(v),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: AppTheme.textSecondary, size: 18),
                        const SizedBox(width: 10),
                        Text('تغییر نام',
                            style: TextStyle(color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, color: AppTheme.textSecondary, size: 18),
                        const SizedBox(width: 10),
                        Text('ارسال',
                            style: TextStyle(color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 10),
                        Text('حذف',
                            style: TextStyle(color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
