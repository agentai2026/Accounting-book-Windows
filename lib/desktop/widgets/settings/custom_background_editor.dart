import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/background_presets.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/custom_background.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/settings/settings_row_widgets.dart';

class CustomBackgroundEditor extends ConsumerWidget {
  const CustomBackgroundEditor({super.key});

  Future<void> _pickWallpaper(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.single.path;
    if (path == null || path.isEmpty) return;

    final result =
        await ref.read(settingsProvider.notifier).importCustomBackgroundImage(
              path,
            );
    if (!context.mounted) return;
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('壁纸已设置')),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final wallpaperAsync = ref.watch(customWallpaperAbsolutePathProvider);
    final hasImage = settings.hasCustomBackgroundImage;

    return GlassSurface(
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '自定义壁纸',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '可上传图片作为全局背景，或使用下方渐变色',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemeColors.textHint(context),
                  ),
            ),
            const SizedBox(height: 14),
            SettingsSectionLabel('壁纸图片'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: wallpaperAsync.when(
                  data: (absolutePath) {
                    if (absolutePath == null) {
                      return _WallpaperPlaceholder(
                        onPick: () => _pickWallpaper(context, ref),
                      );
                    }
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(absolutePath),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '当前壁纸',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => _WallpaperPlaceholder(
                    onPick: () => _pickWallpaper(context, ref),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickWallpaper(context, ref),
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: Text(hasImage ? '更换图片' : '上传图片'),
                  ),
                ),
                if (hasImage) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await notifier.clearCustomBackgroundImage();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已移除壁纸图片')),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('移除图片'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const SettingsSectionLabel('渐变色（无图片时生效）'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mood in kCustomBackgroundMoods)
                  ActionChip(
                    label: Text(mood.label),
                    onPressed: () => notifier.applyCustomBackgroundMood(mood),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _ColorPairSection(
              title: '浅色模式',
              startLabel: '起始色',
              endLabel: '结束色',
              startColor: Color(settings.customBgLightStart),
              endColor: Color(settings.customBgLightEnd),
              onStartChanged: (color) => notifier.setCustomBackgroundColors(
                lightStart: color,
                lightEnd: Color(settings.customBgLightEnd),
                darkStart: Color(settings.customBgDarkStart),
                darkEnd: Color(settings.customBgDarkEnd),
              ),
              onEndChanged: (color) => notifier.setCustomBackgroundColors(
                lightStart: Color(settings.customBgLightStart),
                lightEnd: color,
                darkStart: Color(settings.customBgDarkStart),
                darkEnd: Color(settings.customBgDarkEnd),
              ),
            ),
            const SizedBox(height: 14),
            _ColorPairSection(
              title: '深色模式',
              startLabel: '起始色',
              endLabel: '结束色',
              startColor: Color(settings.customBgDarkStart),
              endColor: Color(settings.customBgDarkEnd),
              onStartChanged: (color) => notifier.setCustomBackgroundColors(
                lightStart: Color(settings.customBgLightStart),
                lightEnd: Color(settings.customBgLightEnd),
                darkStart: color,
                darkEnd: Color(settings.customBgDarkEnd),
              ),
              onEndChanged: (color) => notifier.setCustomBackgroundColors(
                lightStart: Color(settings.customBgLightStart),
                lightEnd: Color(settings.customBgLightEnd),
                darkStart: Color(settings.customBgDarkStart),
                darkEnd: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPairSection extends StatelessWidget {
  const _ColorPairSection({
    required this.title,
    required this.startLabel,
    required this.endLabel,
    required this.startColor,
    required this.endColor,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final String title;
  final String startLabel;
  final String endLabel;
  final Color startColor;
  final Color endColor;
  final ValueChanged<Color> onStartChanged;
  final ValueChanged<Color> onEndChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ColorPickerField(
                label: startLabel,
                color: startColor,
                onChanged: onStartChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ColorPickerField(
                label: endLabel,
                color: endColor,
                onChanged: onEndChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ColorPickerField extends StatelessWidget {
  const _ColorPickerField({
    required this.label,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (context) => _BackgroundColorPickerDialog(initial: color),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppThemeColors.border(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppThemeColors.border(context),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Icon(
              Icons.palette_outlined,
              size: 18,
              color: AppThemeColors.textHint(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundColorPickerDialog extends StatefulWidget {
  const _BackgroundColorPickerDialog({required this.initial});

  final Color initial;

  @override
  State<_BackgroundColorPickerDialog> createState() =>
      _BackgroundColorPickerDialogState();
}

class _BackgroundColorPickerDialogState
    extends State<_BackgroundColorPickerDialog> {
  late Color _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择颜色'),
      content: SizedBox(
        width: 320,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final color in kCustomBackgroundPalette)
              InkWell(
                onTap: () => setState(() => _selected = color),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selected == color
                          ? AppColors.primary
                          : AppThemeColors.border(context),
                      width: _selected == color ? 2.5 : 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

BackgroundPresetPreviewColors previewColorsForStyle(
  SettingsState settings,
  BackgroundStyle style,
  bool isDark,
) {
  if (style == BackgroundStyle.custom) {
    final preset = buildCustomBackgroundPreset(settings);
    return BackgroundPresetPreviewColors(
      colors: isDark ? preset.darkGradient : preset.lightGradient,
      label: preset.label,
    );
  }
  final preset = backgroundPresetFor(style);
  return BackgroundPresetPreviewColors(
    colors: isDark ? preset.darkGradient : preset.lightGradient,
    label: preset.label,
  );
}

class BackgroundPresetPreviewColors {
  const BackgroundPresetPreviewColors({
    required this.colors,
    required this.label,
  });

  final List<Color> colors;
  final String label;
}

class _WallpaperPlaceholder extends StatelessWidget {
  const _WallpaperPlaceholder({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppThemeColors.cardFill(context),
      child: InkWell(
        onTap: onPick,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 32,
                color: AppThemeColors.textHint(context),
              ),
              const SizedBox(height: 6),
              Text(
                '点击上传壁纸图片',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemeColors.textHint(context),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
