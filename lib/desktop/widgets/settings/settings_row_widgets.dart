import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/operation_tips.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';

/// 手机端风格：胶囊毛玻璃设置行
class SettingsPillScaffold extends StatefulWidget {
  const SettingsPillScaffold({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  State<SettingsPillScaffold> createState() => _SettingsPillScaffoldState();
}

class _SettingsPillScaffoldState extends State<SettingsPillScaffold> {
  late final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(right: 8, bottom: 16),
        children: widget.children,
      ),
    );
  }
}

class SettingsPillRow extends StatelessWidget {
  const SettingsPillRow({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.helpTooltip,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? helpTooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: GlassSurface(
            borderRadius: BorderRadius.circular(26),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                            if (helpTooltip != null) ...[
                              const SizedBox(width: 4),
                              SettingsHelpTooltip(message: helpTooltip!),
                            ],
                          ],
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textHint,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.helpTooltip,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? helpTooltip;

  @override
  Widget build(BuildContext context) {
    return SettingsPillRow(
      icon: icon,
      title: title,
      helpTooltip: helpTooltip,
      trailing: Switch.adaptive(
        value: value,
        activeTrackColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}

class SettingsLinkRow extends StatelessWidget {
  const SettingsLinkRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.subtitle,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? value;
  final String? subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: SettingsPillRow(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: enabled ? onTap : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null)
              Text(
                value!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class SettingsSegmentRow<T> extends StatelessWidget {
  const SettingsSegmentRow({
    super.key,
    required this.icon,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.labelBuilder,
    this.helpTooltip,
  });

  final IconData icon;
  final String title;
  final List<T> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T value)? labelBuilder;
  final String? helpTooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        if (helpTooltip != null) ...[
                          const SizedBox(width: 4),
                          SettingsHelpTooltip(message: helpTooltip!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in options)
                    _SegmentChip(
                      label: labelBuilder?.call(option) ?? option.toString(),
                      selected: option == selected,
                      onTap: () => onChanged(option),
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

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border.withValues(alpha: 0.7),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ),
      ),
    );
  }
}

class SettingsSliderRow extends StatelessWidget {
  const SettingsSliderRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions = 20,
    this.valueLabel,
  });

  final IconData icon;
  final String title;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int divisions;
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  if (valueLabel != null)
                    Text(
                      valueLabel!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  thumbColor: Colors.white,
                  overlayColor: AppColors.primary.withValues(alpha: 0.12),
                  inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textHint,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
