import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/update_service.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback onThemeUpdated;
  final VoidCallback? onCheckUpdate;

  const SettingsScreen({
    super.key,
    required this.storageService,
    required this.onThemeUpdated,
    this.onCheckUpdate,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final v = await UpdateService.getCurrentVersion();
    if (mounted) setState(() => _version = v);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _setDark(bool value) async {
    await widget.storageService.setDarkTheme(value);
    widget.onThemeUpdated();
    setState(() {});
  }

  Future<void> _setDarkAccent(String id) async {
    await widget.storageService.setDarkAccent(id);
    widget.onThemeUpdated();
    setState(() {});
  }

  Future<void> _setLightAccent(String id) async {
    await widget.storageService.setLightAccent(id);
    widget.onThemeUpdated();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.storageService.isDarkTheme();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('تنظیمات', style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: IconThemeData(color: AppTheme.iconActive),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'ظاهر',
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppTheme.accent, AppTheme.accent2],
                        ),
                      ),
                      child: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تم تیره (شب)',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isDark ? 'فعال' : 'غیرفعال (روز)',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isDark,
                      activeColor: AppTheme.accent,
                      onChanged: _setDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildAccentCard(
                title: 'رنگ تم شب',
                hint: 'وقتی تم تاریک فعال است',
                currentId: widget.storageService.getDarkAccent(),
                onPick: _setDarkAccent,
              ),
              const SizedBox(height: 16),
              _buildAccentCard(
                title: 'رنگ تم روز',
                hint: 'وقتی تم روشن فعال است',
                currentId: widget.storageService.getLightAccent(),
                onPick: _setLightAccent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'به‌روزرسانی',
            children: [
              _buildActionCard(
                icon: Icons.system_update,
                title: 'بررسی آپدیت',
                subtitle: 'چک کردن آخرین نسخه از گیت‌هاب',
                onTap: () => widget.onCheckUpdate?.call(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'درباره سازنده',
            children: [
              _buildInfoCard(
                icon: Icons.person,
                title: 'سازنده',
                subtitle: 'AnishtayiN',
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.send,
                title: 'تلگرام',
                subtitle: '@AnishrayiN',
                onTap: () => _launchUrl('https://t.me/AnishrayiN'),
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.code,
                title: 'گیت‌هاب',
                subtitle: 'AnishtayiN',
                onTap: () => _launchUrl('https://github.com/AnishtayiN'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'اطلاعات برنامه',
            children: [
              _buildInfoCard(
                icon: Icons.info,
                title: 'نام برنامه',
                subtitle: 'SonicWave',
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                icon: Icons.tag,
                title: 'نسخه فعلی',
                subtitle: _version,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccentCard({
    required String title,
    required String hint,
    required String currentId,
    required Function(String) onPick,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($hint)',
                style: TextStyle(color: AppTheme.textFaint, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: AppTheme.accents.map((a) {
              final selected = a.id == currentId;
              return GestureDetector(
                onTap: () => onPick(a.id),
                child: Tooltip(
                  message: a.name,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [a.primary, a.secondary],
                      ),
                      border: selected
                          ? Border.all(color: AppTheme.textPrimary, width: 3)
                          : null,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: a.primary.withOpacity(0.5),
                                blurRadius: 14,
                              ),
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white)
                        : const SizedBox.shrink(),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.accent, AppTheme.accent2],
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.accent, AppTheme.accent2],
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: AppTheme.textFaint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
