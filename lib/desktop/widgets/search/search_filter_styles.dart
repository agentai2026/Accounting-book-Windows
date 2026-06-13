import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_theme_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_styles.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/search/search_page_colors.dart';

/// 搜索筛选左栏共用样式
abstract final class SearchFilterStyles {
  static const panelWidth = 286.0;
  static const sectionGap = 16.0;
  static const labelWidth = 52.0;

  static InputDecoration fieldDecoration(
    BuildContext context, {
    required String hint,
    Widget? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppThemeColors.textHint(context), fontSize: 13),
      prefixIcon: prefix,
      prefixIconConstraints: prefix != null
          ? const BoxConstraints(minWidth: 0, minHeight: 0)
          : null,
      contentPadding: EdgeInsets.symmetric(
        horizontal: prefix != null ? 8 : 12,
        vertical: 11,
      ),
      filled: true,
      fillColor: GlassStyles.fieldFill(context),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: GlassStyles.isDark(context)
              ? Colors.white.withValues(alpha: 0.14)
              : AppColors.border.withValues(alpha: 0.65),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: SearchPageColors.accent,
          width: 1.2,
        ),
      ),
    );
  }
}

/// 区块标题（日期 / 金额 / 备注 / 其他）
class SearchFilterSectionLabel extends StatelessWidget {
  const SearchFilterSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SearchPageColors.chipSelectedBg.withValues(
          alpha: GlassStyles.isDark(context) ? 0.45 : 0.85,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SearchPageColors.accent.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: SearchPageColors.accent,
          height: 1.1,
        ),
      ),
    );
  }
}

/// 带标题的筛选分组
class SearchFilterSection extends StatelessWidget {
  const SearchFilterSection({
    super.key,
    required this.title,
    required this.child,
    this.inlineLabel = false,
  });

  final String title;
  final Widget child;
  final bool inlineLabel;

  @override
  Widget build(BuildContext context) {
    if (inlineLabel) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: SearchFilterStyles.labelWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SearchFilterSectionLabel(title),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SearchFilterSectionLabel(title),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class SearchFilterTextField extends StatelessWidget {
  const SearchFilterTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(fontSize: 13, color: AppThemeColors.textPrimary(context)),
      decoration: SearchFilterStyles.fieldDecoration(context, hint: hint),
      onChanged: onChanged != null ? (_) => onChanged!() : null,
    );
  }
}

class SearchFilterPanelDivider extends StatelessWidget {
  const SearchFilterPanelDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(
        height: 1,
        thickness: 1,
        color: GlassStyles.divider(context),
      ),
    );
  }
}
