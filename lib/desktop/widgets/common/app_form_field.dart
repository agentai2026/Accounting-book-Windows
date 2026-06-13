import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_styles.dart';

/// 外置字段标签（显示在输入框上方，不挤占框内空间）
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
      ),
    );
  }
}

/// 外置标签 + 字段内容
class AppLabeledField extends StatelessWidget {
  const AppLabeledField({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFieldLabel(text: label),
        child,
      ],
    );
  }
}

/// 输入框外壳样式（不含 floating label）
InputDecoration appFieldBoxDecoration(
  BuildContext context, {
  String? hintText,
  bool focused = false,
  bool isDense = false,
}) {
  final borderColor = focused
      ? AppColors.primary
      : (GlassStyles.isDark(context)
          ? Colors.white.withValues(alpha: 0.18)
          : AppColors.border.withValues(alpha: 0.75));
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: AppColors.textHint),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: borderColor, width: focused ? 1.5 : 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: AppColors.border.withValues(alpha: 0.5),
      ),
    ),
    filled: true,
    fillColor: GlassStyles.fieldFill(context),
    contentPadding: EdgeInsets.symmetric(
      horizontal: isDense ? 12 : 14,
      vertical: isDense ? 12 : 14,
    ),
    isDense: isDense,
  );
}

/// 兼容旧调用；labelText 仅用于外置标签场景，请优先使用 [AppTextField]
InputDecoration appFieldDecoration(
  BuildContext context, {
  String? labelText,
  bool focused = false,
  Color? labelColor,
  String? hintText,
  bool isDense = false,
}) =>
    appFieldBoxDecoration(
      context,
      hintText: hintText ?? labelText,
      focused: focused,
      isDense: isDense,
    );

/// 统一样式文本输入框（外置标签）
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.style,
    this.enabled = true,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final TextStyle? style;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppLabeledField(
      label: label,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: style,
        onChanged: onChanged,
        decoration: appFieldBoxDecoration(context, hintText: hint),
      ),
    );
  }
}

/// 下拉选项
class AppSelectOption<T> {
  const AppSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
  });

  final T value;
  final String label;
  final String? subtitle;
  final Widget? leading;
}

/// 统一样式的选择字段（替代 DropdownButtonFormField）
class AppSelectField<T> extends StatefulWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.hint,
    this.enabled = true,
    this.isDense = false,
    this.maxMenuHeight = 280,
  });

  final String label;
  final T? value;
  final List<AppSelectOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final bool enabled;
  final bool isDense;
  final double maxMenuHeight;

  @override
  State<AppSelectField<T>> createState() => _AppSelectFieldState<T>();
}

class _AppSelectFieldState<T> extends State<AppSelectField<T>> {
  final _anchorKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _expanded = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_expanded) {
      _expanded = false;
    }
  }

  AppSelectOption<T>? get _selected {
    for (final option in widget.options) {
      if (option.value == widget.value) return option;
    }
    return null;
  }

  void _toggleOverlay() {
    if (!widget.enabled || widget.onChanged == null) return;
    if (_expanded) {
      _removeOverlay();
      setState(() {});
      return;
    }
    _showOverlay();
  }

  void _showOverlay() {
    final anchorContext = _anchorKey.currentContext;
    if (anchorContext == null) return;

    final renderBox = anchorContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final overlay = Overlay.of(context);
    final anchorGlobal = renderBox.localToGlobal(Offset.zero);
    final anchorSize = renderBox.size;
    final screenSize = MediaQuery.sizeOf(context);
    const gap = 4.0;
    final menuHeight =
        widget.maxMenuHeight.clamp(120.0, screenSize.height * 0.45);

    final spaceBelow =
        screenSize.height - anchorGlobal.dy - anchorSize.height - gap;
    final openAbove = spaceBelow < menuHeight && anchorGlobal.dy > menuHeight;
    final top = openAbove
        ? anchorGlobal.dy - menuHeight - gap
        : anchorGlobal.dy + anchorSize.height + gap;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _removeOverlay();
                if (mounted) setState(() {});
              },
            ),
          ),
          Positioned(
            left: anchorGlobal.dx,
            top: top.clamp(8.0, screenSize.height - menuHeight - 8),
            width: anchorSize.width,
            child: Material(
              color: Colors.transparent,
              child: GlassPickerShell(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: menuHeight),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    children: [
                      for (final option in widget.options)
                        _SelectMenuItem(
                          option: option,
                          selected: option.value == widget.value,
                          onTap: () {
                            widget.onChanged?.call(option.value);
                            _removeOverlay();
                            if (mounted) setState(() {});
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() => _expanded = true);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final displayText = selected?.label ?? widget.hint ?? '请选择';
    final muted = selected == null;
    final icon = _expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down;

    return AppLabeledField(
      label: widget.label,
      child: KeyedSubtree(
        key: _anchorKey,
        child: InkWell(
          onTap: _toggleOverlay,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: appFieldBoxDecoration(
              context,
              focused: _expanded,
              isDense: widget.isDense,
            ).copyWith(enabled: widget.enabled),
            child: Row(
              children: [
                if (selected?.leading != null) ...[
                  selected!.leading!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    displayText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: muted || !widget.enabled
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                          fontSize: widget.isDense ? 14 : null,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  icon,
                  color:
                      widget.enabled ? AppColors.textHint : AppColors.border,
                  size: widget.isDense ? 20 : 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectMenuItem extends StatelessWidget {
  const _SelectMenuItem({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppSelectOption<dynamic> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.selectedBackground : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              if (option.leading != null) ...[
                option.leading!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    if (option.subtitle != null)
                      Text(
                        option.subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check, size: 18, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// 工具栏等紧凑场景用的内联选择器
class AppInlineSelectField<T> extends StatelessWidget {
  const AppInlineSelectField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  final T value;
  final List<AppSelectOption<T>> options;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final selected = options.firstWhere(
      (o) => o.value == value,
      orElse: () => options.first,
    );

    return MenuAnchor(
      style: GlassStyles.menuStyle(context),
      menuChildren: [
        for (final option in options)
          MenuItemButton(
            onPressed: enabled ? () => onChanged(option.value) : null,
            leadingIcon: option.value == value
                ? const Icon(Icons.check, size: 18, color: AppColors.primary)
                : null,
            child: Text(option.label),
          ),
      ],
      builder: (context, controller, child) {
        return InkWell(
          onTap: enabled
              ? () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: GlassStyles.fieldFill(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selected.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Icon(Icons.arrow_drop_down,
                    size: 20, color: AppColors.textHint),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 统一样式的可点击字段（日期、跳转选择等）
class AppTappableField extends StatelessWidget {
  const AppTappableField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
    this.muted = false,
    this.enabled = true,
    this.isDense = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool muted;
  final bool enabled;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    return AppLabeledField(
      label: label,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: appFieldBoxDecoration(
            context,
            isDense: isDense,
          ).copyWith(enabled: enabled),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: muted || !enabled
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                        fontSize: isDense ? 14 : null,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(
                  Icons.calendar_today_outlined,
                  size: isDense ? 18 : 20,
                  color: enabled ? AppColors.textHint : AppColors.border,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
