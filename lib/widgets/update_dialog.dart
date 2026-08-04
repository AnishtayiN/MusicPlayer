import 'package:flutter/material.dart';
import '../services/update_service.dart';

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
      backgroundColor: const Color(0xFF111827),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF8B5CF6),
                  Color(0xFF06B6D4),
                ],
              ),
            ),
            child: const Icon(
              Icons.system_update,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'نسخه جدید موجود است',
              style: TextStyle(
                color: Colors.white,
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
              color: Color(0xFF8B5CF6),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'تغییرات:',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: SingleChildScrollView(
              child: Text(
                updateInfo.releaseNotes,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onSkip,
          child: const Text(
            'رد کردن این نسخه',
            style: TextStyle(color: Colors.white54),
          ),
        ),
        TextButton(
          onPressed: onLater,
          child: const Text(
            'بعداً',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            updateService.openUrl(updateInfo.downloadUrl);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
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
