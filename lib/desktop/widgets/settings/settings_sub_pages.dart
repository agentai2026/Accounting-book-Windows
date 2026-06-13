import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ezbookkeeping_desktop/desktop/constants/account_currency_catalog.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/category_icon_catalog.dart';
import 'package:ezbookkeeping_desktop/core/constants/app_constants.dart';
import 'package:ezbookkeeping_desktop/core/database/database_helper.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/core/models/receipt_scene.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/settings/month_start_day_picker.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/database_providers.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_page_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/tag_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/forms/tag_management_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/services/hotkey_service.dart';
import 'package:ezbookkeeping_desktop/desktop/services/notification_reminder_service.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/file_explorer_utils.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/background_presets.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_surface.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/common/glass_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/dialogs/ai_image_recognition_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/settings/backup_password_dialog.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/settings/custom_background_editor.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/settings/settings_actions.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/settings/settings_row_widgets.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/settings/settings_shared_widgets.dart';

class SettingsSubPage extends ConsumerWidget {
  const SettingsSubPage({super.key, required this.section});

  final SettingsSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (section) {
      SettingsSection.personalization => const PersonalizationSettingsPage(),
      SettingsSection.background => const BackgroundSettingsPage(),
      SettingsSection.transaction => const TransactionSettingsPage(),
      SettingsSection.display => const DisplaySettingsPage(),
      SettingsSection.aiAutoBookkeeping => const AiAutoBookkeepingSettingsPage(),
      SettingsSection.icons => const IconSettingsPage(),
      SettingsSection.data => const DataManagementSettingsPage(),
      SettingsSection.notificationFeedback =>
        const NotificationFeedbackSettingsPage(),
      SettingsSection.general => const GeneralSettingsPage(),
      SettingsSection.about => const AboutSettingsPage(),
    };
  }
}

/// 1. 个性化
class PersonalizationSettingsPage extends ConsumerWidget {
  const PersonalizationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    return SettingsPillScaffold(
      children: [
        const SettingsPageHeader(
          title: '个性化',
          subtitle: '主题与全局面板毛玻璃强度',
        ),
        const SizedBox(height: 16),
        SettingsSegmentRow<ThemeMode>(
          icon: Icons.palette_outlined,
          title: '颜色模式',
          options: ThemeMode.values,
          selected: s.themeMode,
          labelBuilder: (v) => switch (v) {
            ThemeMode.system => '系统',
            ThemeMode.light => '浅色',
            ThemeMode.dark => '深色',
          },
          onChanged: n.setThemeMode,
        ),
        SettingsSegmentRow<GlassStrength>(
          icon: Icons.blur_on_outlined,
          title: '毛玻璃强度',
          helpTooltip: '控制侧边栏、内容区、弹窗等 GlassSurface 面板的磨砂感',
          options: GlassStrength.values,
          selected: s.glassStrength,
          labelBuilder: (v) => v.label,
          onChanged: n.setGlassStrength,
        ),
        SettingsToggleRow(
          icon: Icons.animation_outlined,
          title: '页面切换动画',
          helpTooltip: '侧边栏切换页面时的淡入效果',
          value: s.pageAnimationEnabled,
          onChanged: n.setPageAnimationEnabled,
        ),
        SettingsToggleRow(
          icon: Icons.auto_awesome_outlined,
          title: '面板光晕效果',
          helpTooltip: '毛玻璃卡片边缘的柔和高光',
          value: s.glowEffectEnabled,
          onChanged: n.setGlowEffectEnabled,
        ),
        SettingsToggleRow(
          icon: Icons.tips_and_updates_outlined,
          title: '操作提示',
          helpTooltip: '关闭后隐藏设置项旁的帮助图标',
          value: s.operationTipsEnabled,
          onChanged: n.setOperationTipsEnabled,
        ),
      ],
    );
  }
}

/// 2. 背景样式
class BackgroundSettingsPage extends ConsumerWidget {
  const BackgroundSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SettingsPillScaffold(
      children: [
        const SettingsPageHeader(
          title: '背景样式',
          subtitle: '壁纸渐变 + 面板透视（与「个性化」毛玻璃联动）',
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            onPressed: () async {
              await n.applyRecommendedGlassLook();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已恢复推荐毛玻璃效果')),
                );
              }
            },
            icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
            label: const Text('恢复推荐毛玻璃'),
          ),
        ),
        SettingsToggleRow(
          icon: Icons.wallpaper_outlined,
          title: '启用渐变背景',
          helpTooltip: '关闭后使用纯色底，毛玻璃透视效果会减弱',
          value: s.backgroundEnabled,
          onChanged: n.setBackgroundEnabled,
        ),
        SettingsSliderRow(
          icon: Icons.water_drop_outlined,
          title: '壁纸虚化',
          value: s.backgroundBlur,
          valueLabel: '${(s.backgroundBlur * 100).round()}%',
          onChanged: n.setBackgroundBlur,
        ),
        SettingsSliderRow(
          icon: Icons.lightbulb_outline,
          title: '背景压暗',
          value: s.backgroundDim,
          valueLabel: '${(s.backgroundDim * 100).round()}%',
          onChanged: n.setBackgroundDim,
        ),
        SettingsSegmentRow<ForegroundMaterial>(
          icon: Icons.layers_outlined,
          title: '面板材质',
          helpTooltip: '「毛玻璃」为全局面板默认效果；轻透更通透，纯色无模糊',
          options: ForegroundMaterial.values,
          selected: s.foregroundMaterial,
          labelBuilder: (v) => v.label,
          onChanged: n.setForegroundMaterial,
        ),
        const SettingsSectionLabel('背景预设'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final style in BackgroundStyle.values)
              _BackgroundPreviewCard(
                style: style,
                settings: s,
                selected: s.backgroundStyle == style,
                isDark: isDark,
                onTap: () => n.setBackgroundStyle(style),
              ),
          ],
        ),
        if (s.backgroundStyle == BackgroundStyle.custom) ...[
          const SizedBox(height: 12),
          const CustomBackgroundEditor(),
        ],
      ],
    );
  }
}

class _BackgroundPreviewCard extends ConsumerWidget {
  const _BackgroundPreviewCard({
    required this.style,
    required this.settings,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final BackgroundStyle style;
  final SettingsState settings;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = previewColorsForStyle(settings, style, isDark);
    final colors = preview.colors;
    final showWallpaperPreview = style == BackgroundStyle.custom &&
        settings.hasCustomBackgroundImage;
    final wallpaperAsync = showWallpaperPreview
        ? ref.watch(customWallpaperAbsolutePathProvider)
        : null;
    final wallpaperPath = wallpaperAsync?.maybeWhen(
      data: (path) => path,
      orElse: () => null,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 156,
        height: 96,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.border.withValues(alpha: 0.6),
            width: selected ? 2 : 1,
          ),
          gradient: wallpaperPath == null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                )
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (wallpaperPath != null)
              Image.file(
                File(wallpaperPath),
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Row(
                children: [
                  Icon(style.icon, size: 15, color: AppColors.textPrimary),
                  const SizedBox(width: 4),
                  Text(
                    preview.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          shadows: wallpaperPath != null
                              ? const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                right: 8,
                top: 8,
                child: Icon(Icons.check_circle, color: AppColors.primary, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

/// 3. 账单表单
class TransactionSettingsPage extends ConsumerWidget {
  const TransactionSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    return SettingsPillScaffold(
      children: [
        const SettingsPageHeader(
          title: '账单表单',
          subtitle: '记账弹窗默认行为与可选按钮',
        ),
        const SizedBox(height: 16),
        SettingsSegmentRow<TransactionType>(
          icon: Icons.swap_vert_outlined,
          title: '新账单默认类型',
          options: const [
            TransactionType.expense,
            TransactionType.income,
            TransactionType.transfer,
          ],
          selected: s.defaultTransactionType,
          labelBuilder: (v) => v.settingLabel,
          onChanged: n.setDefaultTransactionType,
        ),
        SettingsSegmentRow<ImageCompressionLevel>(
          icon: Icons.photo_size_select_large_outlined,
          title: '账单图片压缩',
          options: ImageCompressionLevel.values,
          selected: s.imageCompression,
          labelBuilder: (v) => v.label,
          onChanged: n.setImageCompression,
        ),
        SettingsToggleRow(
          icon: Icons.exposure_zero_outlined,
          title: '账单金额可为零',
          value: s.amountCanBeZero,
          onChanged: n.setAmountCanBeZero,
        ),
        SettingsToggleRow(
          icon: Icons.schedule_outlined,
          title: '精确记账时间',
          helpTooltip: '允许选择具体时分秒',
          value: s.preciseTime,
          onChanged: n.setPreciseTime,
        ),
        SettingsToggleRow(
          icon: Icons.psychology_outlined,
          title: '记忆功能',
          helpTooltip: '记住上次使用的账户与分类',
          value: s.rememberLastAccount && s.rememberLastCategory,
          onChanged: (v) async {
            await n.setRememberLastAccount(v);
            await n.setRememberLastCategory(v);
          },
        ),
        SettingsToggleRow(
          icon: Icons.content_copy_outlined,
          title: '重复账单提醒',
          value: s.duplicateReminder,
          onChanged: n.setDuplicateReminder,
        ),
        SettingsToggleRow(
          icon: Icons.view_compact_outlined,
          title: '紧凑表单布局',
          value: s.formCompactMode,
          onChanged: n.setFormCompactMode,
        ),
        SettingsToggleRow(
          icon: Icons.touch_app_outlined,
          title: '再记按钮',
          value: s.recordAgainButton,
          onChanged: n.setRecordAgainButton,
        ),
        SettingsToggleRow(
          icon: Icons.event_available_outlined,
          title: '复制账单更新日期',
          value: s.copyBillUpdateDate,
          onChanged: n.setCopyBillUpdateDate,
        ),
        SettingsToggleRow(
          icon: Icons.event_repeat_outlined,
          title: '再记账单更新日期',
          value: s.recordAgainUpdateDate,
          onChanged: n.setRecordAgainUpdateDate,
        ),
        SettingsToggleRow(
          icon: Icons.photo_camera_outlined,
          title: '账单图片',
          value: s.billImageButton,
          onChanged: n.setBillImageButton,
        ),
        SettingsToggleRow(
          icon: Icons.bookmark_outline,
          title: '收支预算入口',
          value: s.budgetButton,
          onChanged: n.setBudgetButton,
        ),
        const SettingsSectionLabel('可选功能按钮'),
        SettingsToggleRow(
          icon: Icons.receipt_long_outlined,
          title: '报销按钮',
          value: s.reimbursableButton,
          onChanged: n.setReimbursableButton,
        ),
        SettingsToggleRow(
          icon: Icons.undo_outlined,
          title: '退款按钮',
          value: s.refundButton,
          onChanged: n.setRefundButton,
        ),
        SettingsToggleRow(
          icon: Icons.local_offer_outlined,
          title: '优惠按钮',
          value: s.discountButton,
          onChanged: n.setDiscountButton,
        ),
      ],
    );
  }
}

/// 显示与格式
class DisplaySettingsPage extends ConsumerWidget {
  const DisplaySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    return SettingsPillScaffold(
      children: [
        const SettingsPageHeader(
          title: '显示与格式',
          subtitle: '金额、日历、列表与详情展示',
        ),
        const SizedBox(height: 16),
        SettingsSegmentRow<AmountFormatStyle>(
          icon: Icons.pin_outlined,
          title: '金额格式化',
          options: AmountFormatStyle.values,
          selected: s.amountFormat,
          labelBuilder: (v) => v.label,
          onChanged: n.setAmountFormat,
        ),
        SettingsSegmentRow<WeekStartDay>(
          icon: Icons.date_range_outlined,
          title: '一周起始日',
          options: WeekStartDay.values,
          selected: s.weekStartDay,
          labelBuilder: (v) => v.label,
          onChanged: n.setWeekStartDay,
        ),
        SettingsLinkRow(
          icon: Icons.calendar_month_outlined,
          title: '每月起始日',
          subtitle: '自定义账期，影响首页与统计',
          value: s.monthStartDay.toString().padLeft(2, '0'),
          onTap: () => _pickMonthStartDay(context, s.monthStartDay, n),
        ),
        SettingsToggleRow(
          icon: Icons.color_lens_outlined,
          title: '收支颜色自定义',
          value: s.customIncomeExpenseColors,
          onChanged: n.setCustomIncomeExpenseColors,
        ),
        SettingsSegmentRow<IncomeExpenseColorScheme>(
          icon: Icons.compare_arrows_outlined,
          title: '收支颜色方案',
          options: IncomeExpenseColorScheme.values,
          selected: s.incomeExpenseColorScheme,
          labelBuilder: (v) => v.label,
          onChanged: n.setIncomeExpenseColorScheme,
        ),
        const SettingsSectionLabel('首页与列表'),
        SettingsToggleRow(
          icon: Icons.bar_chart_outlined,
          title: '首页本周卡片',
          value: s.homeWeekCard,
          onChanged: n.setHomeWeekCard,
        ),
        SettingsToggleRow(
          icon: Icons.sort_outlined,
          title: '账单日期倒序',
          value: s.billDateDesc,
          onChanged: n.setBillDateDesc,
        ),
        SettingsToggleRow(
          icon: Icons.access_time_outlined,
          title: '账单时间倒序',
          value: s.billTimeDesc,
          onChanged: n.setBillTimeDesc,
        ),
        SettingsSegmentRow<BillInfoDisplayMode>(
          icon: Icons.view_list_outlined,
          title: '账单信息展示',
          helpTooltip: '控制列表行中时间与备注列的显示',
          options: BillInfoDisplayMode.values,
          selected: s.billInfoMode,
          labelBuilder: (v) => v.label,
          onChanged: n.setBillInfoMode,
        ),
        const SettingsSectionLabel('日历'),
        SettingsSegmentRow<CalendarFontWeight>(
          icon: Icons.format_bold_outlined,
          title: '日历字体粗细',
          options: CalendarFontWeight.values,
          selected: s.calendarFontWeight,
          labelBuilder: (v) => v.label,
          onChanged: n.setCalendarFontWeight,
        ),
        SettingsSegmentRow<CalendarFontSize>(
          icon: Icons.format_size_outlined,
          title: '日历字体大小',
          options: CalendarFontSize.values,
          selected: s.calendarFontSize,
          labelBuilder: (v) => v.label,
          onChanged: n.setCalendarFontSize,
        ),
        SettingsToggleRow(
          icon: Icons.view_day_outlined,
          title: '日历仅显示单日账单',
          value: s.calendarSingleDay,
          onChanged: n.setCalendarSingleDay,
        ),
        SettingsToggleRow(
          icon: Icons.my_location_outlined,
          title: '日历金额精确显示',
          value: s.calendarPreciseAmount,
          onChanged: n.setCalendarPreciseAmount,
        ),
        const SettingsSectionLabel('详情与图表'),
        SettingsToggleRow(
          icon: Icons.image_outlined,
          title: '详情显示图片',
          value: s.detailShowImages,
          onChanged: n.setDetailShowImages,
        ),
        SettingsToggleRow(
          icon: Icons.article_outlined,
          title: '详情显示技术信息',
          value: s.detailShowMeta,
          onChanged: n.setDetailShowMeta,
        ),
        SettingsToggleRow(
          icon: Icons.pie_chart_outline,
          title: '饼图动态旋转',
          value: s.pieChartRotate,
          onChanged: n.setPieChartRotate,
        ),
      ],
    );
  }

  Future<void> _pickMonthStartDay(
    BuildContext context,
    int current,
    SettingsNotifier n,
  ) async {
    final picked = await showMonthStartDayPicker(
      context: context,
      currentDay: current,
    );
    if (picked != null) await n.setMonthStartDay(picked);
  }
}

/// 4. AI 自动记账
class AiAutoBookkeepingSettingsPage extends ConsumerWidget {
  const AiAutoBookkeepingSettingsPage({super.key});

  static String _sceneLabel(int index) {
    if (index < 0) return '自动识别';
    final scenes = ReceiptScene.values
        .where((s) => s != ReceiptScene.unknown)
        .toList(growable: false);
    if (index >= scenes.length) return '自动识别';
    return scenes[index].label;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    return SettingsPillScaffold(
      children: [
        const SettingsPageHeader(
          title: 'AI自动记账',
          subtitle: '本机 OCR 识图，无需联网 · 实验功能，识别结果请人工核对',
        ),
        const SizedBox(height: 16),
        SettingsToggleRow(
          icon: Icons.auto_fix_high_outlined,
          title: '启用 AI 自动记账',
          helpTooltip: '关闭后账单列表不再显示 AI 识图入口。识图准确率因截图差异而不同，提交前请核对金额与分类',
          value: s.aiAutoBookkeepingEnabled,
          onChanged: n.setAiAutoBookkeepingEnabled,
        ),
        SettingsLinkRow(
          icon: Icons.document_scanner_outlined,
          title: '试用 AI 识图',
          onTap: s.aiAutoBookkeepingEnabled
              ? () => showAiImageRecognitionDialog(context)
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请先在上方开启 AI 自动记账')),
                  );
                },
        ),
        const SettingsSectionLabel('识别规则'),
        SettingsToggleRow(
          icon: Icons.compare_arrows_outlined,
          title: '仅识别支出/收入',
          helpTooltip: '不识别转账类账单',
          value: s.aiExpenseIncomeOnly,
          onChanged: n.setAiExpenseIncomeOnly,
        ),
        SettingsToggleRow(
          icon: Icons.content_copy_outlined,
          title: '重复账单检测',
          helpTooltip: '识别结果与近期账单相似时提示',
          value: s.aiDuplicateCheck,
          onChanged: n.setAiDuplicateCheck,
        ),
        SettingsToggleRow(
          icon: Icons.warning_amber_outlined,
          title: '低置信度提醒',
          value: s.aiLowConfidenceWarn,
          onChanged: n.setAiLowConfidenceWarn,
        ),
        SettingsToggleRow(
          icon: Icons.crop_free_outlined,
          title: 'OCR 裁剪增强',
          helpTooltip: '对小票局部区域增强识别，可能略慢',
          value: s.aiEnhanceOcr,
          onChanged: n.setAiEnhanceOcr,
        ),
        SettingsLinkRow(
          icon: Icons.image_search_outlined,
          title: '默认识别场景',
          value: _sceneLabel(s.aiDefaultSceneIndex),
          onTap: () => _pickDefaultScene(context, s.aiDefaultSceneIndex, n),
        ),
        const SettingsSectionLabel('入账策略'),
        SettingsToggleRow(
          icon: Icons.category_outlined,
          title: '自动匹配分类',
          helpTooltip: '关闭后识图结果不预选分类，需手动选择',
          value: s.aiAutoCategory,
          onChanged: n.setAiAutoCategory,
        ),
        SettingsSegmentRow<AiEntryStrategy>(
          icon: Icons.playlist_add_check_outlined,
          title: '入账策略',
          helpTooltip: '高置信识别结果可跳过确认直接入账',
          options: AiEntryStrategy.values,
          selected: s.aiEntryStrategy,
          labelBuilder: (v) => v.label,
          onChanged: n.setAiEntryStrategy,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassSurface(
            borderRadius: BorderRadius.circular(26),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '使用说明',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '在账单列表将鼠标悬停在「添加」按钮上 3 秒，可唤起 AI识图；拖拽或粘贴支付截图即可识别。'
                    '所有识别在本机完成，图片与文字不会上传云端。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDefaultScene(
    BuildContext context,
    int current,
    SettingsNotifier n,
  ) async {
    final scenes = ReceiptScene.values
        .where((s) => s != ReceiptScene.unknown)
        .toList(growable: false);

    final picked = await showGlassListPickerDialog<int>(
      context: context,
      title: '默认识别场景',
      width: 320,
      height: 360,
      items: [
        GlassListPickerItem(
          value: -1,
          label: '自动识别（推荐）',
          selected: current < 0,
        ),
        for (var i = 0; i < scenes.length; i++)
          GlassListPickerItem(
            value: i,
            label: scenes[i].label,
            selected: current == i,
          ),
      ],
    );
    if (picked != null) await n.setAiDefaultSceneIndex(picked);
  }
}

/// 5. 图标编辑
class IconSettingsPage extends ConsumerWidget {
  const IconSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    return SettingsPillScaffold(
      children: [
        const SettingsPageHeader(
          title: '图标编辑',
          subtitle: '全局图标风格与管理入口',
        ),
        const SizedBox(height: 16),
        SettingsSegmentRow<SettingsIconSize>(
          icon: Icons.photo_size_select_small_outlined,
          title: '图标大小',
          helpTooltip: '分类与账户选择器中的图标尺寸',
          options: SettingsIconSize.values,
          selected: s.iconSize,
          labelBuilder: (v) => v.label,
          onChanged: n.setIconSize,
        ),
        SettingsSegmentRow<IconColumnCount>(
          icon: Icons.grid_view_outlined,
          title: '图标列数',
          helpTooltip: '图标网格每行显示的个数',
          options: IconColumnCount.values,
          selected: s.iconColumnCount,
          labelBuilder: (v) => v.label,
          onChanged: n.setIconColumnCount,
        ),
        SettingsToggleRow(
          icon: Icons.border_style_outlined,
          title: '圆角图标底',
          value: s.useRoundedIcons,
          onChanged: n.setUseRoundedIcons,
        ),
        SettingsToggleRow(
          icon: Icons.invert_colors_off_outlined,
          title: '图标单色模式',
          helpTooltip: '统一使用主题色显示分类图标',
          value: s.iconMonochromeMode,
          onChanged: n.setIconMonochromeMode,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassSurface(
            borderRadius: BorderRadius.circular(26),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  for (final key in ['1', '71', '110'])
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: buildCategoryIconWidget(
                        key,
                        context: context,
                        size: 30,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        SettingsLinkRow(
          icon: Icons.category_outlined,
          title: '交易分类图标',
          onTap: () => context.go('/categories'),
        ),
        SettingsLinkRow(
          icon: Icons.account_balance_wallet_outlined,
          title: '账户图标',
          onTap: () => context.go('/accounts'),
        ),
      ],
    );
  }
}

/// 5. 数据管理
class DataManagementSettingsPage extends ConsumerStatefulWidget {
  const DataManagementSettingsPage({super.key});

  @override
  ConsumerState<DataManagementSettingsPage> createState() =>
      _DataManagementSettingsPageState();
}

class _DataManagementSettingsPageState
    extends ConsumerState<DataManagementSettingsPage> {
  String? _dbPath;
  String? _backupDir;
  List<File> _backups = [];
  bool _loadingBackups = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dbPath = await DatabaseHelper.instance.getDatabasePath();
    final service = await ref.read(backupServiceProvider.future);
    final dir = await service.getBackupDirectory();
    final listResult = await service.listBackups();
    if (!mounted) return;
    setState(() {
      _dbPath = dbPath;
      _backupDir = dir;
      _backups = listResult.when(
        success: (files) => files.whereType<File>().toList(),
        failure: (_) => [],
      );
      _loadingBackups = false;
    });
  }

  Future<void> _openInExplorer(
    BuildContext context, {
    required String? path,
    required bool revealFile,
  }) async {
    if (path == null || path.isEmpty) return;
    final ok = revealFile
        ? await FileExplorerUtils.revealFile(path)
        : await FileExplorerUtils.openFolder(path);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开，请检查路径是否存在')),
      );
    }
  }

  Future<void> _configureBackupEncryption(
    BuildContext context,
    SettingsNotifier n, {
    required bool enable,
  }) async {
    if (!enable) {
      await n.disableBackupEncryption();
      return;
    }
    final password = await showBackupPasswordDialog(
      context,
      title: '设置备份密码',
      hint: '密码保存在本机，用于加密 .ezb 备份文件。遗忘密码将无法恢复加密备份。',
    );
    if (password == null) return;
    await n.enableBackupEncryption(password);
  }

  Future<void> _changeBackupPassword(
    BuildContext context,
    SettingsNotifier n,
  ) async {
    final password = await showBackupPasswordDialog(
      context,
      title: '修改备份密码',
      confirmLabel: '保存',
      hint: '新密码仅影响之后创建的加密备份。',
    );
    if (password == null) return;
    await n.setBackupEncryptionPassword(password);
    if (!ref.read(settingsProvider).backupEncryptionEnabled) {
      await n.enableBackupEncryption(password);
    }
  }

  Future<void> _pickRetentionDays(
    BuildContext context,
    int current,
    SettingsNotifier n,
  ) async {
    final picked = await showGlassListPickerDialog<int>(
      context: context,
      title: '备份保留天数',
      width: 280,
      height: 240,
      items: [
        for (var i = 0; i < 30; i++)
          GlassListPickerItem(
            value: i + 1,
            label: '${i + 1} 天',
            selected: current == i + 1,
          ),
      ],
    );
    if (picked != null) await n.setBackupRetentionDays(picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final actions = SettingsActions(ref, context);
    final busy = ref.watch(settingsBusyProvider);
    final tagCountLabel = ref.watch(tagListProvider).maybeWhen(
          data: (tags) => '${tags.length} 个',
          orElse: () => '…',
        );

    return SettingsPillScaffold(
      children: [
        const SettingsPageHeader(
          title: '数据管理',
          subtitle: '导入、导出、备份与清理',
        ),
        const SizedBox(height: 16),
        const SettingsSectionLabel('导入 / 导出'),
        SettingsLinkRow(
          icon: Icons.upload_file_outlined,
          title: '导入数据库',
          subtitle: '覆盖当前全部数据（.db）',
          onTap: busy ? () {} : actions.importDatabase,
          enabled: !busy,
        ),
        SettingsLinkRow(
          icon: Icons.table_view_outlined,
          title: '导入账单表格',
          subtitle: '支持 CSV / Excel',
          onTap: busy ? () {} : () => actions.importSpreadsheet(),
          enabled: !busy,
        ),
        SettingsLinkRow(
          icon: Icons.download_outlined,
          title: '导出数据库',
          subtitle: '完整备份 SQLite 文件',
          onTap: busy ? () {} : actions.exportDatabase,
          enabled: !busy,
        ),
        SettingsLinkRow(
          icon: Icons.grid_on_outlined,
          title: '导出 Excel',
          onTap: busy ? () {} : actions.exportExcel,
          enabled: !busy,
        ),
        SettingsLinkRow(
          icon: Icons.table_rows_outlined,
          title: '导出 CSV',
          onTap: busy ? () {} : actions.exportCsv,
          enabled: !busy,
        ),
        SettingsLinkRow(
          icon: Icons.delete_sweep_outlined,
          title: '清空交易',
          subtitle: '仅删除账单，保留账户与分类',
          onTap: busy ? () {} : actions.clearAllTransactions,
          enabled: !busy,
        ),
        const SettingsSectionLabel('标签库'),
        SettingsLinkRow(
          icon: Icons.local_offer_outlined,
          title: '标签管理',
          subtitle: '查看、添加、编辑或删除标签',
          value: tagCountLabel,
          onTap: busy ? () {} : () => showTagManagementDialog(context),
          enabled: !busy,
        ),
        const SettingsSectionLabel('备份'),
        SettingsToggleRow(
          icon: Icons.exit_to_app_outlined,
          title: '退出时自动备份',
          helpTooltip: '仅在应用运行且正常退出时生效',
          value: s.autoBackupEnabled,
          onChanged: n.setAutoBackupEnabled,
        ),
        SettingsSegmentRow<BackupCycle>(
          icon: Icons.update_outlined,
          title: '定时备份周期',
          helpTooltip: '应用保持运行时才按周期自动备份',
          options: BackupCycle.values,
          selected: s.backupCycle,
          labelBuilder: (v) => v.label,
          onChanged: n.setBackupCycle,
        ),
        SettingsToggleRow(
          icon: Icons.lock_outline,
          title: '加密备份',
          helpTooltip: '启用后备份为 .ezb 加密文件，需记住备份密码',
          value: s.backupEncryptionEnabled,
          onChanged: (value) => _configureBackupEncryption(context, n, enable: value),
        ),
        if (s.backupEncryptionEnabled)
          SettingsLinkRow(
            icon: Icons.password_outlined,
            title: '修改备份密码',
            subtitle: '密码已设置',
            onTap: () => _changeBackupPassword(context, n),
          ),
        SettingsToggleRow(
          icon: Icons.notifications_active_outlined,
          title: '备份成功提示',
          helpTooltip: '自动或手动备份完成后显示系统通知',
          value: s.showBackupPrompt,
          onChanged: n.setShowBackupPrompt,
        ),
        SettingsLinkRow(
          icon: Icons.sd_storage_outlined,
          title: '备份保留天数',
          value: '${s.backupRetentionDays} 天',
          onTap: () => _pickRetentionDays(context, s.backupRetentionDays, n),
        ),
        SettingsLinkRow(
          icon: Icons.list_alt_outlined,
          title: '备份文件列表',
          value: _loadingBackups ? '…' : '${_backups.length} 个',
          onTap: () => _showBackupList(context, actions, busy),
        ),
        if (_backupDir != null)
          SettingsPillRow(
            icon: Icons.folder_outlined,
            title: '备份目录',
            subtitle: _backupDir,
            helpTooltip: '点击在资源管理器中打开',
            onTap: () => _openInExplorer(
              context,
              path: _backupDir,
              revealFile: false,
            ),
            trailing: const Icon(
              Icons.open_in_new,
              size: 18,
              color: AppColors.textHint,
            ),
          ),
        if (_dbPath != null)
          SettingsPillRow(
            icon: Icons.insert_drive_file_outlined,
            title: '数据库文件',
            subtitle: _dbPath,
            helpTooltip: '点击在资源管理器中定位文件',
            onTap: () => _openInExplorer(
              context,
              path: _dbPath,
              revealFile: true,
            ),
            trailing: const Icon(
              Icons.open_in_new,
              size: 18,
              color: AppColors.textHint,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 10),
          child: GlassSurface(
            borderRadius: BorderRadius.circular(26),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            await actions.createBackup();
                            final service =
                                await ref.read(backupServiceProvider.future);
                            await service.pruneOldBackups(
                              retentionDays: s.backupRetentionDays,
                            );
                            await _load();
                          },
                    icon: const Icon(Icons.backup_outlined, size: 18),
                    label: const Text('立即备份'),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : actions.seedDemoTransactions,
                    icon: const Icon(Icons.dataset_outlined, size: 18),
                    label: const Text('演示数据'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showBackupList(
    BuildContext context,
    SettingsActions actions,
    bool busy,
  ) {
    showGlassDialog<void>(
      context: context,
      builder: (ctx) => GlassAlertDialog(
        maxWidth: 520,
        title: const Text('备份文件'),
        content: SizedBox(
          width: 420,
          child: _loadingBackups
              ? const Center(child: CircularProgressIndicator())
              : _backups.isEmpty
                  ? const Text('暂无备份文件')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _backups.length,
                      itemBuilder: (_, i) {
                        final file = _backups[i];
                        return ListTile(
                          title: Text(
                            file.uri.pathSegments.last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: TextButton(
                            onPressed: busy
                                ? null
                                : () async {
                                    Navigator.pop(ctx);
                                    await actions.restoreBackup(file.path);
                                    await _load();
                                  },
                            child: const Text('恢复'),
                          ),
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

/// 6. 通知与反馈
class NotificationFeedbackSettingsPage extends ConsumerStatefulWidget {
  const NotificationFeedbackSettingsPage({super.key});

  @override
  ConsumerState<NotificationFeedbackSettingsPage> createState() =>
      _NotificationFeedbackSettingsPageState();
}

class _NotificationFeedbackSettingsPageState
    extends ConsumerState<NotificationFeedbackSettingsPage> {
  final _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    SettingsState s,
    SettingsNotifier n,
  ) async {
    final initial = TimeOfDay(hour: s.reminderHour, minute: s.reminderMinute);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      await n.setReminderTime(picked.hour, picked.minute);
      if (!context.mounted) return;
      NotificationReminderService.instance.syncFromSettings(
        ref.read(settingsProvider),
        readSettings: () => ref.read(settingsProvider),
      );
    }
  }

  String _formatReminderTime(SettingsState s) {
    final h = s.reminderHour.toString().padLeft(2, '0');
    final m = s.reminderMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);

    return SettingsPillScaffold(
      children: [
        const SettingsPageHeader(
          title: '提醒与反馈',
          subtitle: '每日记账提醒与意见反馈',
        ),
        const SizedBox(height: 16),
        const SettingsSectionLabel('记账提醒'),
        SettingsToggleRow(
          icon: Icons.notifications_outlined,
          title: '每日记账提醒',
          helpTooltip: '需应用保持运行；关闭软件后不会触发系统级定时提醒',
          value: s.reminderEnabled,
          onChanged: (v) async {
            await n.setReminderEnabled(v);
            NotificationReminderService.instance.syncFromSettings(
              ref.read(settingsProvider),
              readSettings: () => ref.read(settingsProvider),
            );
          },
        ),
        SettingsLinkRow(
          icon: Icons.schedule_outlined,
          title: '提醒时间',
          value: _formatReminderTime(s),
          onTap: () {
            if (!s.reminderEnabled) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请先开启每日记账提醒')),
              );
              return;
            }
            _pickReminderTime(context, s, n);
          },
        ),
        SettingsToggleRow(
          icon: Icons.volume_up_outlined,
          title: '提醒提示音',
          value: s.notificationSoundEnabled,
          onChanged: n.setNotificationSoundEnabled,
        ),
        SettingsSegmentRow<NotificationSoundStyle>(
          icon: Icons.music_note_outlined,
          title: '提示音风格',
          helpTooltip: '电脑端使用系统通知音；所选风格会显示在通知文案中',
          options: NotificationSoundStyle.values,
          selected: s.notificationSoundStyle,
          labelBuilder: (v) => v.label,
          onChanged: n.setNotificationSoundStyle,
        ),
        SettingsLinkRow(
          icon: Icons.play_circle_outline,
          title: '试听提醒',
          onTap: () => NotificationReminderService.instance.preview(s),
        ),
        const SettingsSectionLabel('意见反馈'),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassSurface(
            borderRadius: BorderRadius.circular(26),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '意见反馈',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: '描述你遇到的问题或改进建议…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      final text = _feedbackController.text.trim();
                      if (text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请先输入反馈内容')),
                        );
                        return;
                      }
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('反馈内容已复制到剪贴板')),
                      );
                    },
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: const Text('复制反馈内容'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '数据本地存储，反馈不会自动上传。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _pickDefaultCurrency(
  BuildContext context,
  WidgetRef ref,
  String currentCode,
) async {
  final picked = await showGlassListPickerDialog<String>(
    context: context,
    title: '默认货币',
    width: 360,
    height: 420,
    maxWidth: 420,
    items: [
      for (final item in kAccountCurrencyCatalog)
        GlassListPickerItem(
          value: item.$1,
          label: '${item.$2} (${item.$1})',
          selected: item.$1 == currentCode,
        ),
    ],
  );
  if (picked == null || picked == currentCode) return;
  await ref.read(settingsProvider.notifier).setCurrencyCode(picked);
}

/// 7. 通用
class GeneralSettingsPage extends ConsumerWidget {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);

    return SettingsPillScaffold(
      children: [
        const SettingsPageHeader(
          title: '通用',
          subtitle: '格式与快捷键',
        ),
        const SizedBox(height: 16),
        SettingsToggleRow(
          icon: Icons.visibility_off_outlined,
          title: '后台隐私保护',
          helpTooltip: '窗口失去焦点时模糊界面内容',
          value: s.privacyProtection,
          onChanged: ref.read(settingsProvider.notifier).setPrivacyProtection,
        ),
        SettingsToggleRow(
          icon: Icons.flash_on_outlined,
          title: '启用全局快捷键',
          helpTooltip: Platform.isWindows
              ? 'Windows 下可用 ${AppConstants.quickAddHotkey} 快速记账'
              : '当前仅 Windows 支持全局快捷键',
          value: s.hotkeyEnabled,
          onChanged: Platform.isWindows
              ? (v) async {
                  await ref.read(settingsProvider.notifier).setHotkeyEnabled(v);
                  if (v) {
                    await HotkeyService.instance.registerDefaults();
                  } else {
                    await HotkeyService.instance.dispose();
                  }
                }
              : (_) {},
        ),
        SettingsPillRow(
          icon: Icons.payments_outlined,
          title: '默认货币',
          subtitle:
              '${accountCurrencyLabel(s.currencyCode)} · ${accountCurrencySymbol(s.currencyCode)}',
          trailing: Text(
            s.currencyCode,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          onTap: () => _pickDefaultCurrency(context, ref, s.currencyCode),
        ),
        SettingsPillRow(
          icon: Icons.keyboard_outlined,
          title: '快速记账',
          subtitle: Platform.isWindows
              ? AppConstants.quickAddHotkey
              : '仅 Windows 可用（${AppConstants.quickAddHotkey}）',
        ),
      ],
    );
  }
}

/// 8. 关于
class AboutSettingsPage extends StatelessWidget {
  const AboutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPillScaffold(
      children: [
        const SettingsPageHeader(
          title: '关于',
          subtitle: '版本与隐私说明',
        ),
        const SizedBox(height: 16),
        SettingsPillRow(
          icon: Icons.account_balance_wallet_outlined,
          title: AppConstants.appName,
          subtitle: '个人记账 · 电脑端 · v${AppConstants.appVersion}',
        ),
        const SettingsPillRow(
          icon: Icons.offline_bolt_outlined,
          title: '本地优先',
          subtitle: '账本数据默认仅存储在本机',
        ),
        const SettingsPillRow(
          icon: Icons.phone_android_outlined,
          title: '双端协同（预留）',
          subtitle: '后续支持局域网与手机端同步',
        ),
        const SettingsPillRow(
          icon: Icons.code_outlined,
          title: '技术栈',
          subtitle: 'Flutter · SQLite · Riverpod',
        ),
      ],
    );
  }
}
