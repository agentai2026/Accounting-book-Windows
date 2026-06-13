import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 设置页分区
enum SettingsSection {
  personalization,
  background,
  transaction,
  display,
  aiAutoBookkeeping,
  icons,
  data,
  notificationFeedback,
  general,
  about,
}

extension SettingsSectionX on SettingsSection {
  String get title => switch (this) {
        SettingsSection.personalization => '个性化',
        SettingsSection.background => '背景样式',
        SettingsSection.transaction => '账单表单',
        SettingsSection.display => '显示与格式',
        SettingsSection.aiAutoBookkeeping => 'AI自动记账',
        SettingsSection.icons => '图标编辑',
        SettingsSection.data => '数据管理',
        SettingsSection.notificationFeedback => '意见反馈',
        SettingsSection.general => '通用',
        SettingsSection.about => '关于',
      };

  String get subtitle => switch (this) {
        SettingsSection.personalization => '主题与毛玻璃强度',
        SettingsSection.background => '渐变配色与装饰',
        SettingsSection.transaction => '记账表单与默认行为',
        SettingsSection.display => '金额、日历与列表展示',
        SettingsSection.aiAutoBookkeeping => '识图 OCR 与自动入账',
        SettingsSection.icons => '分类与账户图标',
        SettingsSection.data => '导出、备份与清理',
        SettingsSection.notificationFeedback => '问题与改进建议',
        SettingsSection.general => '货币、语言与快捷键',
        SettingsSection.about => '版本与隐私说明',
      };
}

class SettingsPageNotifier extends StateNotifier<SettingsSection> {
  SettingsPageNotifier() : super(SettingsSection.personalization);

  void select(SettingsSection section) => state = section;
}

final settingsPageProvider =
    StateNotifierProvider<SettingsPageNotifier, SettingsSection>((ref) {
  return SettingsPageNotifier();
});

final settingsBusyProvider = StateProvider<bool>((ref) => false);
