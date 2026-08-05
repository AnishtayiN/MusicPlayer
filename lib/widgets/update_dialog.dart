import 'package:flutter/material.dart';

import '../services/update_service.dart';
import '../theme/app_theme.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final UpdateService updateService;
  final VoidCallback onSkip;
  final VoidCallback onLater;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.updateService,
    required this.onSkip,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.accent, AppTheme.accent2],
              ),
            ),
            child: const Icon(Icons.system_update, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'نسخه جدید موجود است',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نسخه ${updateInfo.version}',
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'تغییرات:',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: SingleChildScrollView(
              child: Text(
                updateInfo.releaseNotes,
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onSkip,
          child: Text('رد کردن این نسخه',
              style: TextStyle(color: AppTheme.textMuted)),
        ),
        TextButton(
          onPressed: onLater,
          child: Text('بعداً',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            updateService.openUrl(updateInfo.downloadUrl);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('دانلود و نصب'),
        ),
      ],
    );
  }
}
