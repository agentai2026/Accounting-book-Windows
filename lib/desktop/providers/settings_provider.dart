import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ezbookkeeping_desktop/core/constants/app_constants.dart';
import 'package:ezbookkeeping_desktop/core/services/background_image_service.dart';
import 'package:ezbookkeeping_desktop/core/utils/result.dart';
import 'package:ezbookkeeping_desktop/core/models/enums.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/income_expense_palette.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/settings_bindings.dart';
import 'package:ezbookkeeping_desktop/desktop/utils/settings_secrets.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/custom_background.dart';

export 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';

const _keyThemeMode = 'theme_mode';
const _keyCurrencyCode = 'currency_code';
const _keyHotkeyEnabled = 'hotkey_enabled';
const _keyReminderEnabled = 'reminder_enabled';
const _keyReminderHour = 'reminder_hour';
const _keyReminderMinute = 'reminder_minute';
const _keyAutoBackup = 'auto_backup_enabled';
const _keyBackgroundStyle = 'background_style';
const _keyCustomBgLightStart = 'custom_bg_l_start';
const _keyCustomBgLightEnd = 'custom_bg_l_end';
const _keyCustomBgDarkStart = 'custom_bg_d_start';
const _keyCustomBgDarkEnd = 'custom_bg_d_end';
const _keyCustomBgImagePath = 'custom_bg_image';
const _keyGlassStrength = 'glass_strength';
const _keyDefaultTransactionType = 'default_transaction_type';
const _keyRememberLastAccount = 'remember_last_account';
const _keyRememberLastCategory = 'remember_last_category';
const _keyDetailShowImages = 'detail_show_images';
const _keyDetailShowMeta = 'detail_show_meta';
const _keyFormCompactMode = 'form_compact_mode';
const _keyIconSize = 'icon_size';
const _keyUseRoundedIcons = 'use_rounded_icons';
const _keyBackgroundEnabled = 'bg_enabled';
const _keyBackgroundBlur = 'bg_blur';
const _keyBackgroundDim = 'bg_dim';
const _keyForegroundMaterial = 'fg_material';
const _keyPageAnimation = 'page_animation';
const _keyGlowEffect = 'glow_effect';
const _keyOperationTips = 'operation_tips';
const _keyIconMonochrome = 'icon_monochrome';
const _keyImageCompression = 'image_compression';
const _keyIconColumns = 'icon_columns';
const _keyAmountCanBeZero = 'amount_can_be_zero';
const _keyRecordAgainButton = 'record_again_btn';
const _keyCopyBillUpdateDate = 'copy_bill_update_date';
const _keyRecordAgainUpdateDate = 'record_again_update_date';
const _keyBillImageButton = 'bill_image_btn';
const _keyBudgetButton = 'budget_btn';
const _keyReimbursableButton = 'reimbursable_btn';
const _keyRefundButton = 'refund_btn';
const _keyDiscountButton = 'discount_btn';
const _keyPreciseTime = 'precise_time';
const _keyDuplicateReminder = 'duplicate_reminder';
const _keyBillInfoMode = 'bill_info_mode';
const _keyCalendarFontWeight = 'cal_font_weight';
const _keyCalendarFontSize = 'cal_font_size';
const _keyCustomIncomeExpenseColors = 'custom_ie_colors';
const _keyIncomeExpenseColorScheme = 'ie_color_scheme';
const _keyWeekStartDay = 'week_start';
const _keyAmountFormat = 'amount_format';
const _keyHomeWeekCard = 'home_week_card';
const _keyCalendarSingleDay = 'cal_single_day';
const _keyPrivacyProtection = 'privacy_protection';
const _keyBillDateDesc = 'bill_date_desc';
const _keyBillTimeDesc = 'bill_time_desc';
const _keyCalendarPreciseAmount = 'cal_precise_amount';
const _keyPieChartRotate = 'pie_chart_rotate';
const _keyMonthStartDay = 'month_start_day';
const _keyBackupCycle = 'backup_cycle';
const _keyShowBackupPrompt = 'show_backup_prompt';
const _keyBackupRetentionDays = 'backup_retention_days';
const _keyBackupEncryptionEnabled = 'backup_encryption_enabled';
const _keyBackupEncryptionPassword = 'backup_encryption_password';
const _keyNotificationSound = 'notification_sound';
const _keyAiEnabled = 'ai_enabled';
const _keyAiExpenseIncomeOnly = 'ai_expense_income_only';
const _keyAiDuplicateCheck = 'ai_duplicate_check';
const _keyAiAutoCategory = 'ai_auto_category';
const _keyAiLowConfidenceWarn = 'ai_low_confidence_warn';
const _keyAiEnhanceOcr = 'ai_enhance_ocr';
const _keyAiEntryStrategy = 'ai_entry_strategy';
const _keyAiDefaultScene = 'ai_default_scene';
const _keyLastAccountPrefix = 'txn_last_account_';
const _keyLastCategoryPrefix = 'txn_last_category_';

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.currencyCode = AppConstants.kDefaultCurrency,
    this.hotkeyEnabled = true,
    this.reminderEnabled = false,
    this.reminderHour = 21,
    this.reminderMinute = 0,
    this.autoBackupEnabled = false,
    this.backgroundStyle = BackgroundStyle.warm,
    this.glassStrength = GlassStrength.standard,
    this.defaultTransactionType = TransactionType.expense,
    this.rememberLastAccount = true,
    this.rememberLastCategory = true,
    this.detailShowImages = true,
    this.detailShowMeta = true,
    this.formCompactMode = false,
    this.iconSize = SettingsIconSize.medium,
    this.useRoundedIcons = true,
    this.backgroundEnabled = true,
    this.backgroundBlur = 0.72,
    this.backgroundDim = 0.55,
    this.foregroundMaterial = ForegroundMaterial.blur,
    this.pageAnimationEnabled = true,
    this.glowEffectEnabled = true,
    this.operationTipsEnabled = true,
    this.iconMonochromeMode = false,
    this.imageCompression = ImageCompressionLevel.original,
    this.iconColumnCount = IconColumnCount.six,
    this.amountCanBeZero = false,
    this.recordAgainButton = false,
    this.copyBillUpdateDate = true,
    this.recordAgainUpdateDate = true,
    this.billImageButton = true,
    this.budgetButton = true,
    this.reimbursableButton = true,
    this.refundButton = true,
    this.discountButton = true,
    this.preciseTime = true,
    this.duplicateReminder = true,
    this.billInfoMode = BillInfoDisplayMode.all,
    this.calendarFontWeight = CalendarFontWeight.normal,
    this.calendarFontSize = CalendarFontSize.normal,
    this.customIncomeExpenseColors = false,
    this.incomeExpenseColorScheme = IncomeExpenseColorScheme.redGreen,
    this.weekStartDay = WeekStartDay.monday,
    this.amountFormat = AmountFormatStyle.tenThousands,
    this.homeWeekCard = true,
    this.calendarSingleDay = true,
    this.privacyProtection = false,
    this.billDateDesc = false,
    this.billTimeDesc = false,
    this.calendarPreciseAmount = true,
    this.pieChartRotate = true,
    this.monthStartDay = 1,
    this.backupCycle = BackupCycle.off,
    this.showBackupPrompt = false,
    this.backupRetentionDays = 21,
    this.backupEncryptionEnabled = false,
    this.backupEncryptionPassword = '',
    this.notificationSoundEnabled = true,
    this.notificationSoundStyle = NotificationSoundStyle.drum,
    this.aiAutoBookkeepingEnabled = true,
    this.aiExpenseIncomeOnly = true,
    this.aiDuplicateCheck = true,
    this.aiAutoCategory = true,
    this.aiLowConfidenceWarn = true,
    this.aiEnhanceOcr = true,
    this.aiEntryStrategy = AiEntryStrategy.standard,
    this.aiDefaultSceneIndex = -1,
    this.customBgLightStart = CustomBackgroundDefaults.lightStartValue,
    this.customBgLightEnd = CustomBackgroundDefaults.lightEndValue,
    this.customBgDarkStart = CustomBackgroundDefaults.darkStartValue,
    this.customBgDarkEnd = CustomBackgroundDefaults.darkEndValue,
    this.customBgImagePath = '',
  });

  final ThemeMode themeMode;
  final String currencyCode;
  final bool hotkeyEnabled;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final bool autoBackupEnabled;
  final BackgroundStyle backgroundStyle;
  final GlassStrength glassStrength;
  final TransactionType defaultTransactionType;
  final bool rememberLastAccount;
  final bool rememberLastCategory;
  final bool detailShowImages;
  final bool detailShowMeta;
  final bool formCompactMode;
  final SettingsIconSize iconSize;
  final bool useRoundedIcons;
  final bool backgroundEnabled;
  final double backgroundBlur;
  final double backgroundDim;
  final ForegroundMaterial foregroundMaterial;
  final bool pageAnimationEnabled;
  final bool glowEffectEnabled;
  final bool operationTipsEnabled;
  final bool iconMonochromeMode;
  final ImageCompressionLevel imageCompression;
  final IconColumnCount iconColumnCount;
  final bool amountCanBeZero;
  final bool recordAgainButton;
  final bool copyBillUpdateDate;
  final bool recordAgainUpdateDate;
  final bool billImageButton;
  final bool budgetButton;
  final bool reimbursableButton;
  final bool refundButton;
  final bool discountButton;
  final bool preciseTime;
  final bool duplicateReminder;
  final BillInfoDisplayMode billInfoMode;
  final CalendarFontWeight calendarFontWeight;
  final CalendarFontSize calendarFontSize;
  final bool customIncomeExpenseColors;
  final IncomeExpenseColorScheme incomeExpenseColorScheme;
  final WeekStartDay weekStartDay;
  final AmountFormatStyle amountFormat;
  final bool homeWeekCard;
  final bool calendarSingleDay;
  final bool privacyProtection;
  final bool billDateDesc;
  final bool billTimeDesc;
  final bool calendarPreciseAmount;
  final bool pieChartRotate;
  final int monthStartDay;
  final BackupCycle backupCycle;
  final bool showBackupPrompt;
  final int backupRetentionDays;
  final bool backupEncryptionEnabled;
  final String backupEncryptionPassword;
  final bool notificationSoundEnabled;
  final NotificationSoundStyle notificationSoundStyle;
  final bool aiAutoBookkeepingEnabled;
  final bool aiExpenseIncomeOnly;
  final bool aiDuplicateCheck;
  final bool aiAutoCategory;
  final bool aiLowConfidenceWarn;
  final bool aiEnhanceOcr;
  final AiEntryStrategy aiEntryStrategy;
  /// -1 表示自动识别场景
  final int aiDefaultSceneIndex;
  final int customBgLightStart;
  final int customBgLightEnd;
  final int customBgDarkStart;
  final int customBgDarkEnd;
  final String customBgImagePath;

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? currencyCode,
    bool? hotkeyEnabled,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? autoBackupEnabled,
    BackgroundStyle? backgroundStyle,
    GlassStrength? glassStrength,
    TransactionType? defaultTransactionType,
    bool? rememberLastAccount,
    bool? rememberLastCategory,
    bool? detailShowImages,
    bool? detailShowMeta,
    bool? formCompactMode,
    SettingsIconSize? iconSize,
    bool? useRoundedIcons,
    bool? backgroundEnabled,
    double? backgroundBlur,
    double? backgroundDim,
    ForegroundMaterial? foregroundMaterial,
    bool? pageAnimationEnabled,
    bool? glowEffectEnabled,
    bool? operationTipsEnabled,
    bool? iconMonochromeMode,
    ImageCompressionLevel? imageCompression,
    IconColumnCount? iconColumnCount,
    bool? amountCanBeZero,
    bool? recordAgainButton,
    bool? copyBillUpdateDate,
    bool? recordAgainUpdateDate,
    bool? billImageButton,
    bool? budgetButton,
    bool? reimbursableButton,
    bool? refundButton,
    bool? discountButton,
    bool? preciseTime,
    bool? duplicateReminder,
    BillInfoDisplayMode? billInfoMode,
    CalendarFontWeight? calendarFontWeight,
    CalendarFontSize? calendarFontSize,
    bool? customIncomeExpenseColors,
    IncomeExpenseColorScheme? incomeExpenseColorScheme,
    WeekStartDay? weekStartDay,
    AmountFormatStyle? amountFormat,
    bool? homeWeekCard,
    bool? calendarSingleDay,
    bool? privacyProtection,
    bool? billDateDesc,
    bool? billTimeDesc,
    bool? calendarPreciseAmount,
    bool? pieChartRotate,
    int? monthStartDay,
    BackupCycle? backupCycle,
    bool? showBackupPrompt,
    int? backupRetentionDays,
    bool? backupEncryptionEnabled,
    String? backupEncryptionPassword,
    bool? notificationSoundEnabled,
    NotificationSoundStyle? notificationSoundStyle,
    bool? aiAutoBookkeepingEnabled,
    bool? aiExpenseIncomeOnly,
    bool? aiDuplicateCheck,
    bool? aiAutoCategory,
    bool? aiLowConfidenceWarn,
    bool? aiEnhanceOcr,
    AiEntryStrategy? aiEntryStrategy,
    int? aiDefaultSceneIndex,
    int? customBgLightStart,
    int? customBgLightEnd,
    int? customBgDarkStart,
    int? customBgDarkEnd,
    String? customBgImagePath,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      currencyCode: currencyCode ?? this.currencyCode,
      hotkeyEnabled: hotkeyEnabled ?? this.hotkeyEnabled,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      glassStrength: glassStrength ?? this.glassStrength,
      defaultTransactionType:
          defaultTransactionType ?? this.defaultTransactionType,
      rememberLastAccount: rememberLastAccount ?? this.rememberLastAccount,
      rememberLastCategory: rememberLastCategory ?? this.rememberLastCategory,
      detailShowImages: detailShowImages ?? this.detailShowImages,
      detailShowMeta: detailShowMeta ?? this.detailShowMeta,
      formCompactMode: formCompactMode ?? this.formCompactMode,
      iconSize: iconSize ?? this.iconSize,
      useRoundedIcons: useRoundedIcons ?? this.useRoundedIcons,
      backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled,
      backgroundBlur: backgroundBlur ?? this.backgroundBlur,
      backgroundDim: backgroundDim ?? this.backgroundDim,
      foregroundMaterial: foregroundMaterial ?? this.foregroundMaterial,
      pageAnimationEnabled: pageAnimationEnabled ?? this.pageAnimationEnabled,
      glowEffectEnabled: glowEffectEnabled ?? this.glowEffectEnabled,
      operationTipsEnabled: operationTipsEnabled ?? this.operationTipsEnabled,
      iconMonochromeMode: iconMonochromeMode ?? this.iconMonochromeMode,
      imageCompression: imageCompression ?? this.imageCompression,
      iconColumnCount: iconColumnCount ?? this.iconColumnCount,
      amountCanBeZero: amountCanBeZero ?? this.amountCanBeZero,
      recordAgainButton: recordAgainButton ?? this.recordAgainButton,
      copyBillUpdateDate: copyBillUpdateDate ?? this.copyBillUpdateDate,
      recordAgainUpdateDate:
          recordAgainUpdateDate ?? this.recordAgainUpdateDate,
      billImageButton: billImageButton ?? this.billImageButton,
      budgetButton: budgetButton ?? this.budgetButton,
      reimbursableButton: reimbursableButton ?? this.reimbursableButton,
      refundButton: refundButton ?? this.refundButton,
      discountButton: discountButton ?? this.discountButton,
      preciseTime: preciseTime ?? this.preciseTime,
      duplicateReminder: duplicateReminder ?? this.duplicateReminder,
      billInfoMode: billInfoMode ?? this.billInfoMode,
      calendarFontWeight: calendarFontWeight ?? this.calendarFontWeight,
      calendarFontSize: calendarFontSize ?? this.calendarFontSize,
      customIncomeExpenseColors:
          customIncomeExpenseColors ?? this.customIncomeExpenseColors,
      incomeExpenseColorScheme:
          incomeExpenseColorScheme ?? this.incomeExpenseColorScheme,
      weekStartDay: weekStartDay ?? this.weekStartDay,
      amountFormat: amountFormat ?? this.amountFormat,
      homeWeekCard: homeWeekCard ?? this.homeWeekCard,
      calendarSingleDay: calendarSingleDay ?? this.calendarSingleDay,
      privacyProtection: privacyProtection ?? this.privacyProtection,
      billDateDesc: billDateDesc ?? this.billDateDesc,
      billTimeDesc: billTimeDesc ?? this.billTimeDesc,
      calendarPreciseAmount:
          calendarPreciseAmount ?? this.calendarPreciseAmount,
      pieChartRotate: pieChartRotate ?? this.pieChartRotate,
      monthStartDay: monthStartDay ?? this.monthStartDay,
      backupCycle: backupCycle ?? this.backupCycle,
      showBackupPrompt: showBackupPrompt ?? this.showBackupPrompt,
      backupRetentionDays: backupRetentionDays ?? this.backupRetentionDays,
      backupEncryptionEnabled:
          backupEncryptionEnabled ?? this.backupEncryptionEnabled,
      backupEncryptionPassword:
          backupEncryptionPassword ?? this.backupEncryptionPassword,
      notificationSoundEnabled:
          notificationSoundEnabled ?? this.notificationSoundEnabled,
      notificationSoundStyle:
          notificationSoundStyle ?? this.notificationSoundStyle,
      aiAutoBookkeepingEnabled:
          aiAutoBookkeepingEnabled ?? this.aiAutoBookkeepingEnabled,
      aiExpenseIncomeOnly: aiExpenseIncomeOnly ?? this.aiExpenseIncomeOnly,
      aiDuplicateCheck: aiDuplicateCheck ?? this.aiDuplicateCheck,
      aiAutoCategory: aiAutoCategory ?? this.aiAutoCategory,
      aiLowConfidenceWarn: aiLowConfidenceWarn ?? this.aiLowConfidenceWarn,
      aiEnhanceOcr: aiEnhanceOcr ?? this.aiEnhanceOcr,
      aiEntryStrategy: aiEntryStrategy ?? this.aiEntryStrategy,
      aiDefaultSceneIndex: aiDefaultSceneIndex ?? this.aiDefaultSceneIndex,
      customBgLightStart: customBgLightStart ?? this.customBgLightStart,
      customBgLightEnd: customBgLightEnd ?? this.customBgLightEnd,
      customBgDarkStart: customBgDarkStart ?? this.customBgDarkStart,
      customBgDarkEnd: customBgDarkEnd ?? this.customBgDarkEnd,
      customBgImagePath: customBgImagePath ?? this.customBgImagePath,
    );
  }

  bool get hasCustomBackgroundImage => customBgImagePath.isNotEmpty;
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  SharedPreferences? _prefs;

  T _enumAt<T extends Enum>(List<T> values, int index, T fallback) {
    if (index < 0 || index >= values.length) return fallback;
    return values[index];
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;

    state = SettingsState(
      themeMode: _enumAt(
        ThemeMode.values,
        p.getInt(_keyThemeMode) ?? ThemeMode.system.index,
        ThemeMode.system,
      ),
      currencyCode:
          p.getString(_keyCurrencyCode) ?? AppConstants.kDefaultCurrency,
      hotkeyEnabled: p.getBool(_keyHotkeyEnabled) ?? true,
      reminderEnabled: p.getBool(_keyReminderEnabled) ?? false,
      reminderHour: p.getInt(_keyReminderHour) ?? 21,
      reminderMinute: p.getInt(_keyReminderMinute) ?? 0,
      autoBackupEnabled: p.getBool(_keyAutoBackup) ?? false,
      backgroundStyle: _enumAt(
        BackgroundStyle.values,
        p.getInt(_keyBackgroundStyle) ?? 0,
        BackgroundStyle.warm,
      ),
      glassStrength: _enumAt(
        GlassStrength.values,
        p.getInt(_keyGlassStrength) ?? 1,
        GlassStrength.standard,
      ),
      defaultTransactionType: TransactionType.fromValue(
        p.getInt(_keyDefaultTransactionType) ?? TransactionType.expense.value,
      ),
      rememberLastAccount: p.getBool(_keyRememberLastAccount) ?? true,
      rememberLastCategory: p.getBool(_keyRememberLastCategory) ?? true,
      detailShowImages: p.getBool(_keyDetailShowImages) ?? true,
      detailShowMeta: p.getBool(_keyDetailShowMeta) ?? true,
      formCompactMode: p.getBool(_keyFormCompactMode) ?? false,
      iconSize: _enumAt(
        SettingsIconSize.values,
        p.getInt(_keyIconSize) ?? 1,
        SettingsIconSize.medium,
      ),
      useRoundedIcons: p.getBool(_keyUseRoundedIcons) ?? true,
      backgroundEnabled: p.getBool(_keyBackgroundEnabled) ?? true,
      backgroundBlur: p.getDouble(_keyBackgroundBlur) ?? 0.72,
      backgroundDim: p.getDouble(_keyBackgroundDim) ?? 0.55,
      foregroundMaterial: _enumAt(
        ForegroundMaterial.values,
        p.getInt(_keyForegroundMaterial) ?? ForegroundMaterial.blur.index,
        ForegroundMaterial.blur,
      ),
      pageAnimationEnabled: p.getBool(_keyPageAnimation) ?? true,
      glowEffectEnabled: p.getBool(_keyGlowEffect) ?? true,
      operationTipsEnabled: p.getBool(_keyOperationTips) ?? true,
      iconMonochromeMode: p.getBool(_keyIconMonochrome) ?? false,
      imageCompression: _enumAt(
        ImageCompressionLevel.values,
        p.getInt(_keyImageCompression) ?? ImageCompressionLevel.original.index,
        ImageCompressionLevel.original,
      ),
      iconColumnCount: _enumAt(
        IconColumnCount.values,
        p.getInt(_keyIconColumns) ?? IconColumnCount.six.index,
        IconColumnCount.six,
      ),
      amountCanBeZero: p.getBool(_keyAmountCanBeZero) ?? false,
      recordAgainButton: p.getBool(_keyRecordAgainButton) ?? false,
      copyBillUpdateDate: p.getBool(_keyCopyBillUpdateDate) ?? true,
      recordAgainUpdateDate: p.getBool(_keyRecordAgainUpdateDate) ?? true,
      billImageButton: p.getBool(_keyBillImageButton) ?? true,
      budgetButton: p.getBool(_keyBudgetButton) ?? true,
      reimbursableButton: p.getBool(_keyReimbursableButton) ?? true,
      refundButton: p.getBool(_keyRefundButton) ?? true,
      discountButton: p.getBool(_keyDiscountButton) ?? true,
      preciseTime: p.getBool(_keyPreciseTime) ?? true,
      duplicateReminder: p.getBool(_keyDuplicateReminder) ?? true,
      billInfoMode: _enumAt(
        BillInfoDisplayMode.values,
        p.getInt(_keyBillInfoMode) ?? BillInfoDisplayMode.all.index,
        BillInfoDisplayMode.all,
      ),
      calendarFontWeight: _enumAt(
        CalendarFontWeight.values,
        p.getInt(_keyCalendarFontWeight) ?? CalendarFontWeight.normal.index,
        CalendarFontWeight.normal,
      ),
      calendarFontSize: _enumAt(
        CalendarFontSize.values,
        p.getInt(_keyCalendarFontSize) ?? CalendarFontSize.normal.index,
        CalendarFontSize.normal,
      ),
      customIncomeExpenseColors: p.getBool(_keyCustomIncomeExpenseColors) ?? false,
      incomeExpenseColorScheme: _enumAt(
        IncomeExpenseColorScheme.values,
        p.getInt(_keyIncomeExpenseColorScheme) ??
            IncomeExpenseColorScheme.redGreen.index,
        IncomeExpenseColorScheme.redGreen,
      ),
      weekStartDay: _enumAt(
        WeekStartDay.values,
        p.getInt(_keyWeekStartDay) ?? WeekStartDay.monday.index,
        WeekStartDay.monday,
      ),
      amountFormat: _enumAt(
        AmountFormatStyle.values,
        p.getInt(_keyAmountFormat) ?? AmountFormatStyle.tenThousands.index,
        AmountFormatStyle.tenThousands,
      ),
      homeWeekCard: p.getBool(_keyHomeWeekCard) ?? true,
      calendarSingleDay: p.getBool(_keyCalendarSingleDay) ?? true,
      privacyProtection: p.getBool(_keyPrivacyProtection) ?? false,
      billDateDesc: p.getBool(_keyBillDateDesc) ?? false,
      billTimeDesc: p.getBool(_keyBillTimeDesc) ?? false,
      calendarPreciseAmount: p.getBool(_keyCalendarPreciseAmount) ?? true,
      pieChartRotate: p.getBool(_keyPieChartRotate) ?? true,
      monthStartDay: (p.getInt(_keyMonthStartDay) ?? 1).clamp(1, 28),
      backupCycle: _enumAt(
        BackupCycle.values,
        p.getInt(_keyBackupCycle) ?? BackupCycle.off.index,
        BackupCycle.off,
      ),
      showBackupPrompt: p.getBool(_keyShowBackupPrompt) ?? false,
      backupRetentionDays: p.getInt(_keyBackupRetentionDays) ?? 21,
      backupEncryptionEnabled: p.getBool(_keyBackupEncryptionEnabled) ?? false,
      backupEncryptionPassword: SettingsSecrets.decode(
        p.getString(_keyBackupEncryptionPassword) ?? '',
      ),
      notificationSoundEnabled: p.getBool(_keyNotificationSound) ?? true,
      notificationSoundStyle: _enumAt(
        NotificationSoundStyle.values,
        p.getInt('notification_sound_style') ??
            NotificationSoundStyle.drum.index,
        NotificationSoundStyle.drum,
      ),
      aiAutoBookkeepingEnabled: p.getBool(_keyAiEnabled) ?? true,
      aiExpenseIncomeOnly: p.getBool(_keyAiExpenseIncomeOnly) ?? true,
      aiDuplicateCheck: p.getBool(_keyAiDuplicateCheck) ?? true,
      aiAutoCategory: p.getBool(_keyAiAutoCategory) ?? true,
      aiLowConfidenceWarn: p.getBool(_keyAiLowConfidenceWarn) ?? true,
      aiEnhanceOcr: p.getBool(_keyAiEnhanceOcr) ?? true,
      aiEntryStrategy: _enumAt(
        AiEntryStrategy.values,
        p.getInt(_keyAiEntryStrategy) ?? AiEntryStrategy.standard.index,
        AiEntryStrategy.standard,
      ),
      aiDefaultSceneIndex: p.getInt(_keyAiDefaultScene) ?? -1,
      customBgLightStart:
          p.getInt(_keyCustomBgLightStart) ?? CustomBackgroundDefaults.lightStartValue,
      customBgLightEnd:
          p.getInt(_keyCustomBgLightEnd) ?? CustomBackgroundDefaults.lightEndValue,
      customBgDarkStart:
          p.getInt(_keyCustomBgDarkStart) ?? CustomBackgroundDefaults.darkStartValue,
      customBgDarkEnd:
          p.getInt(_keyCustomBgDarkEnd) ?? CustomBackgroundDefaults.darkEndValue,
      customBgImagePath: p.getString(_keyCustomBgImagePath) ?? '',
    );
    SettingsBindings.applyAmountFormat(state.amountFormat);
  }

  String _lastAccountKey(int bookId, TransactionType type) =>
      '$_keyLastAccountPrefix${bookId}_${type.value}';

  String _lastCategoryKey(int bookId, TransactionType type) =>
      '$_keyLastCategoryPrefix${bookId}_${type.value}';

  Future<void> persistTransactionFormMemory({
    required int bookId,
    required TransactionType type,
    int? accountId,
    int? categoryId,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (state.rememberLastAccount && accountId != null) {
      await _prefs!.setInt(_lastAccountKey(bookId, type), accountId);
    }
    if (state.rememberLastCategory && categoryId != null) {
      await _prefs!.setInt(_lastCategoryKey(bookId, type), categoryId);
    }
  }

  Future<({int? accountId, int? categoryId})> loadTransactionFormMemory({
    required int bookId,
    required TransactionType type,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    final accountId = state.rememberLastAccount
        ? _prefs!.getInt(_lastAccountKey(bookId, type))
        : null;
    final categoryId = state.rememberLastCategory
        ? _prefs!.getInt(_lastCategoryKey(bookId, type))
        : null;
    return (accountId: accountId, categoryId: categoryId);
  }

  Future<void> _saveInt(String key, int value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(key, value);
  }

  Future<void> _saveBool(String key, bool value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(key, value);
  }

  Future<void> _saveDouble(String key, double value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setDouble(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(key, value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _saveInt(_keyThemeMode, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setCurrencyCode(String code) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyCurrencyCode, code);
    state = state.copyWith(currencyCode: code);
  }

  Future<void> setHotkeyEnabled(bool enabled) async {
    await _saveBool(_keyHotkeyEnabled, enabled);
    state = state.copyWith(hotkeyEnabled: enabled);
  }

  Future<void> setReminderEnabled(bool enabled) async {
    await _saveBool(_keyReminderEnabled, enabled);
    state = state.copyWith(reminderEnabled: enabled);
  }

  Future<void> setReminderTime(int hour, int minute) async {
    await _saveInt(_keyReminderHour, hour);
    await _saveInt(_keyReminderMinute, minute);
    state = state.copyWith(reminderHour: hour, reminderMinute: minute);
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    await _saveBool(_keyAutoBackup, enabled);
    state = state.copyWith(autoBackupEnabled: enabled);
  }

  Future<void> setBackgroundStyle(BackgroundStyle style) async {
    await _saveInt(_keyBackgroundStyle, style.index);
    state = state.copyWith(backgroundStyle: style);
  }

  Future<void> setCustomBackgroundColors({
    required Color lightStart,
    required Color lightEnd,
    required Color darkStart,
    required Color darkEnd,
    bool selectCustom = true,
  }) async {
    final ls = lightStart.value;
    final le = lightEnd.value;
    final ds = darkStart.value;
    final de = darkEnd.value;
    await _saveInt(_keyCustomBgLightStart, ls);
    await _saveInt(_keyCustomBgLightEnd, le);
    await _saveInt(_keyCustomBgDarkStart, ds);
    await _saveInt(_keyCustomBgDarkEnd, de);
    if (selectCustom) {
      await _saveInt(_keyBackgroundStyle, BackgroundStyle.custom.index);
    }
    state = state.copyWith(
      customBgLightStart: ls,
      customBgLightEnd: le,
      customBgDarkStart: ds,
      customBgDarkEnd: de,
      backgroundStyle:
          selectCustom ? BackgroundStyle.custom : state.backgroundStyle,
    );
  }

  Future<void> applyCustomBackgroundMood(CustomBackgroundMood mood) async {
    await setCustomBackgroundColors(
      lightStart: mood.lightStart,
      lightEnd: mood.lightEnd,
      darkStart: mood.darkStart,
      darkEnd: mood.darkEnd,
    );
  }

  Future<Result<void>> importCustomBackgroundImage(String sourcePath) async {
    final service = BackgroundImageService();
    await service.deleteIfExists(state.customBgImagePath);
    final result = await service.importFromFile(sourcePath);
    if (result is Success<String>) {
      final relativePath = result.data;
      await _saveString(_keyCustomBgImagePath, relativePath);
      await _saveInt(_keyBackgroundStyle, BackgroundStyle.custom.index);
      state = state.copyWith(
        customBgImagePath: relativePath,
        backgroundStyle: BackgroundStyle.custom,
      );
      return const Success<void>(null);
    }
    return Failure<void>((result as Failure<String>).error);
  }

  Future<void> clearCustomBackgroundImage() async {
    final service = BackgroundImageService();
    await service.deleteIfExists(state.customBgImagePath);
    await _saveString(_keyCustomBgImagePath, '');
    state = state.copyWith(customBgImagePath: '');
  }

  Future<void> setGlassStrength(GlassStrength strength) async {
    await _saveInt(_keyGlassStrength, strength.index);
    state = state.copyWith(glassStrength: strength);
  }

  Future<void> setDefaultTransactionType(TransactionType type) async {
    await _saveInt(_keyDefaultTransactionType, type.value);
    state = state.copyWith(defaultTransactionType: type);
  }

  Future<void> setRememberLastAccount(bool value) async {
    await _saveBool(_keyRememberLastAccount, value);
    state = state.copyWith(rememberLastAccount: value);
  }

  Future<void> setRememberLastCategory(bool value) async {
    await _saveBool(_keyRememberLastCategory, value);
    state = state.copyWith(rememberLastCategory: value);
  }

  Future<void> setDetailShowImages(bool value) async {
    await _saveBool(_keyDetailShowImages, value);
    state = state.copyWith(detailShowImages: value);
  }

  Future<void> setDetailShowMeta(bool value) async {
    await _saveBool(_keyDetailShowMeta, value);
    state = state.copyWith(detailShowMeta: value);
  }

  Future<void> setFormCompactMode(bool value) async {
    await _saveBool(_keyFormCompactMode, value);
    state = state.copyWith(formCompactMode: value);
  }

  Future<void> setIconSize(SettingsIconSize size) async {
    await _saveInt(_keyIconSize, size.index);
    state = state.copyWith(iconSize: size);
  }

  Future<void> setUseRoundedIcons(bool value) async {
    await _saveBool(_keyUseRoundedIcons, value);
    state = state.copyWith(useRoundedIcons: value);
  }

  Future<void> setBackgroundEnabled(bool value) async {
    await _saveBool(_keyBackgroundEnabled, value);
    state = state.copyWith(backgroundEnabled: value);
  }

  Future<void> setBackgroundBlur(double value) async {
    await _saveDouble(_keyBackgroundBlur, value);
    state = state.copyWith(backgroundBlur: value);
  }

  Future<void> setBackgroundDim(double value) async {
    await _saveDouble(_keyBackgroundDim, value);
    state = state.copyWith(backgroundDim: value);
  }

  Future<void> setForegroundMaterial(ForegroundMaterial value) async {
    await _saveInt(_keyForegroundMaterial, value.index);
    var next = state.copyWith(foregroundMaterial: value);
    if (value == ForegroundMaterial.blur && state.backgroundBlur < 0.35) {
      await _saveDouble(_keyBackgroundBlur, 0.65);
      next = next.copyWith(backgroundBlur: 0.65);
    }
    state = next;
  }

  /// 恢复全局毛玻璃推荐参数（壁纸 + 面板联动）
  Future<void> applyRecommendedGlassLook() async {
    await _saveBool(_keyBackgroundEnabled, true);
    await _saveDouble(_keyBackgroundBlur, 0.72);
    await _saveDouble(_keyBackgroundDim, 0.55);
    await _saveInt(_keyForegroundMaterial, ForegroundMaterial.blur.index);
    await _saveInt(_keyGlassStrength, GlassStrength.standard.index);
    await _saveBool(_keyGlowEffect, true);
    state = state.copyWith(
      backgroundEnabled: true,
      backgroundBlur: 0.72,
      backgroundDim: 0.55,
      foregroundMaterial: ForegroundMaterial.blur,
      glassStrength: GlassStrength.standard,
      glowEffectEnabled: true,
    );
  }

  Future<void> setPageAnimationEnabled(bool value) async {
    await _saveBool(_keyPageAnimation, value);
    state = state.copyWith(pageAnimationEnabled: value);
  }

  Future<void> setGlowEffectEnabled(bool value) async {
    await _saveBool(_keyGlowEffect, value);
    state = state.copyWith(glowEffectEnabled: value);
  }

  Future<void> setOperationTipsEnabled(bool value) async {
    await _saveBool(_keyOperationTips, value);
    state = state.copyWith(operationTipsEnabled: value);
  }

  Future<void> setIconMonochromeMode(bool value) async {
    await _saveBool(_keyIconMonochrome, value);
    state = state.copyWith(iconMonochromeMode: value);
  }

  Future<void> setImageCompression(ImageCompressionLevel value) async {
    await _saveInt(_keyImageCompression, value.index);
    state = state.copyWith(imageCompression: value);
  }

  Future<void> setIconColumnCount(IconColumnCount value) async {
    await _saveInt(_keyIconColumns, value.index);
    state = state.copyWith(iconColumnCount: value);
  }

  Future<void> setAmountCanBeZero(bool value) async {
    await _saveBool(_keyAmountCanBeZero, value);
    state = state.copyWith(amountCanBeZero: value);
  }

  Future<void> setRecordAgainButton(bool value) async {
    await _saveBool(_keyRecordAgainButton, value);
    state = state.copyWith(recordAgainButton: value);
  }

  Future<void> setCopyBillUpdateDate(bool value) async {
    await _saveBool(_keyCopyBillUpdateDate, value);
    state = state.copyWith(copyBillUpdateDate: value);
  }

  Future<void> setRecordAgainUpdateDate(bool value) async {
    await _saveBool(_keyRecordAgainUpdateDate, value);
    state = state.copyWith(recordAgainUpdateDate: value);
  }

  Future<void> setBillImageButton(bool value) async {
    await _saveBool(_keyBillImageButton, value);
    state = state.copyWith(billImageButton: value);
  }

  Future<void> setBudgetButton(bool value) async {
    await _saveBool(_keyBudgetButton, value);
    state = state.copyWith(budgetButton: value);
  }

  Future<void> setReimbursableButton(bool value) async {
    await _saveBool(_keyReimbursableButton, value);
    state = state.copyWith(reimbursableButton: value);
  }

  Future<void> setRefundButton(bool value) async {
    await _saveBool(_keyRefundButton, value);
    state = state.copyWith(refundButton: value);
  }

  Future<void> setDiscountButton(bool value) async {
    await _saveBool(_keyDiscountButton, value);
    state = state.copyWith(discountButton: value);
  }

  Future<void> setPreciseTime(bool value) async {
    await _saveBool(_keyPreciseTime, value);
    state = state.copyWith(preciseTime: value);
  }

  Future<void> setDuplicateReminder(bool value) async {
    await _saveBool(_keyDuplicateReminder, value);
    state = state.copyWith(duplicateReminder: value);
  }

  Future<void> setBillInfoMode(BillInfoDisplayMode value) async {
    await _saveInt(_keyBillInfoMode, value.index);
    state = state.copyWith(billInfoMode: value);
  }

  Future<void> setCalendarFontWeight(CalendarFontWeight value) async {
    await _saveInt(_keyCalendarFontWeight, value.index);
    state = state.copyWith(calendarFontWeight: value);
  }

  Future<void> setCalendarFontSize(CalendarFontSize value) async {
    await _saveInt(_keyCalendarFontSize, value.index);
    state = state.copyWith(calendarFontSize: value);
  }

  Future<void> setCustomIncomeExpenseColors(bool value) async {
    await _saveBool(_keyCustomIncomeExpenseColors, value);
    state = state.copyWith(customIncomeExpenseColors: value);
  }

  Future<void> setIncomeExpenseColorScheme(IncomeExpenseColorScheme value) async {
    await _saveInt(_keyIncomeExpenseColorScheme, value.index);
    state = state.copyWith(incomeExpenseColorScheme: value);
  }

  Future<void> setWeekStartDay(WeekStartDay value) async {
    await _saveInt(_keyWeekStartDay, value.index);
    state = state.copyWith(weekStartDay: value);
  }

  Future<void> setAmountFormat(AmountFormatStyle value) async {
    await _saveInt(_keyAmountFormat, value.index);
    state = state.copyWith(amountFormat: value);
    SettingsBindings.applyAmountFormat(value);
  }

  Future<void> setHomeWeekCard(bool value) async {
    await _saveBool(_keyHomeWeekCard, value);
    state = state.copyWith(homeWeekCard: value);
  }

  Future<void> setCalendarSingleDay(bool value) async {
    await _saveBool(_keyCalendarSingleDay, value);
    state = state.copyWith(calendarSingleDay: value);
  }

  Future<void> setPrivacyProtection(bool value) async {
    await _saveBool(_keyPrivacyProtection, value);
    state = state.copyWith(privacyProtection: value);
  }

  Future<void> setBillDateDesc(bool value) async {
    await _saveBool(_keyBillDateDesc, value);
    state = state.copyWith(billDateDesc: value);
  }

  Future<void> setBillTimeDesc(bool value) async {
    await _saveBool(_keyBillTimeDesc, value);
    state = state.copyWith(billTimeDesc: value);
  }

  Future<void> setCalendarPreciseAmount(bool value) async {
    await _saveBool(_keyCalendarPreciseAmount, value);
    state = state.copyWith(calendarPreciseAmount: value);
  }

  Future<void> setPieChartRotate(bool value) async {
    await _saveBool(_keyPieChartRotate, value);
    state = state.copyWith(pieChartRotate: value);
  }

  Future<void> setMonthStartDay(int value) async {
    final clamped = value.clamp(1, 28);
    await _saveInt(_keyMonthStartDay, clamped);
    state = state.copyWith(monthStartDay: clamped);
  }

  Future<void> setBackupCycle(BackupCycle value) async {
    await _saveInt(_keyBackupCycle, value.index);
    state = state.copyWith(backupCycle: value);
  }

  Future<void> setShowBackupPrompt(bool value) async {
    await _saveBool(_keyShowBackupPrompt, value);
    state = state.copyWith(showBackupPrompt: value);
  }

  Future<void> setBackupRetentionDays(int value) async {
    await _saveInt(_keyBackupRetentionDays, value);
    state = state.copyWith(backupRetentionDays: value);
  }

  Future<void> setBackupEncryptionEnabled(bool value) async {
    if (value && state.backupEncryptionPassword.isEmpty) {
      return;
    }
    await _saveBool(_keyBackupEncryptionEnabled, value);
    state = state.copyWith(backupEncryptionEnabled: value);
  }

  Future<void> setBackupEncryptionPassword(String password) async {
    await _saveString(
      _keyBackupEncryptionPassword,
      SettingsSecrets.encode(password),
    );
    state = state.copyWith(
      backupEncryptionPassword: password,
      backupEncryptionEnabled: password.isNotEmpty
          ? state.backupEncryptionEnabled
          : false,
    );
    if (password.isEmpty) {
      await _saveBool(_keyBackupEncryptionEnabled, false);
    }
  }

  Future<void> enableBackupEncryption(String password) async {
    await _saveString(
      _keyBackupEncryptionPassword,
      SettingsSecrets.encode(password),
    );
    await _saveBool(_keyBackupEncryptionEnabled, true);
    state = state.copyWith(
      backupEncryptionPassword: password,
      backupEncryptionEnabled: true,
    );
  }

  Future<void> disableBackupEncryption() async {
    await _saveBool(_keyBackupEncryptionEnabled, false);
    state = state.copyWith(backupEncryptionEnabled: false);
  }

  Future<void> setNotificationSoundEnabled(bool value) async {
    await _saveBool(_keyNotificationSound, value);
    state = state.copyWith(notificationSoundEnabled: value);
  }

  Future<void> setNotificationSoundStyle(NotificationSoundStyle value) async {
    await _saveInt('notification_sound_style', value.index);
    state = state.copyWith(notificationSoundStyle: value);
  }

  Future<void> setAiAutoBookkeepingEnabled(bool value) async {
    await _saveBool(_keyAiEnabled, value);
    state = state.copyWith(aiAutoBookkeepingEnabled: value);
  }

  Future<void> setAiExpenseIncomeOnly(bool value) async {
    await _saveBool(_keyAiExpenseIncomeOnly, value);
    state = state.copyWith(aiExpenseIncomeOnly: value);
  }

  Future<void> setAiDuplicateCheck(bool value) async {
    await _saveBool(_keyAiDuplicateCheck, value);
    state = state.copyWith(aiDuplicateCheck: value);
  }

  Future<void> setAiAutoCategory(bool value) async {
    await _saveBool(_keyAiAutoCategory, value);
    state = state.copyWith(aiAutoCategory: value);
  }

  Future<void> setAiLowConfidenceWarn(bool value) async {
    await _saveBool(_keyAiLowConfidenceWarn, value);
    state = state.copyWith(aiLowConfidenceWarn: value);
  }

  Future<void> setAiEnhanceOcr(bool value) async {
    await _saveBool(_keyAiEnhanceOcr, value);
    state = state.copyWith(aiEnhanceOcr: value);
  }

  Future<void> setAiEntryStrategy(AiEntryStrategy value) async {
    await _saveInt(_keyAiEntryStrategy, value.index);
    state = state.copyWith(aiEntryStrategy: value);
  }

  Future<void> setAiDefaultSceneIndex(int value) async {
    await _saveInt(_keyAiDefaultScene, value);
    state = state.copyWith(aiDefaultSceneIndex: value);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

final currencyCodeProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).currencyCode;
});

final backgroundStyleProvider = Provider<BackgroundStyle>((ref) {
  return ref.watch(settingsProvider).backgroundStyle;
});

final settingsIconScaleProvider = Provider<double>((ref) {
  return switch (ref.watch(settingsProvider).iconSize) {
    SettingsIconSize.small => 0.88,
    SettingsIconSize.medium => 1.0,
    SettingsIconSize.large => 1.16,
  };
});

final settingsIconColumnCountProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider).iconColumnCount.columns;
});

final weekStartsOnProvider = Provider<int>((ref) {
  return SettingsBindings.weekStartsOn(ref.watch(settingsProvider).weekStartDay);
});

final monthStartDayProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider).monthStartDay;
});

final incomeColorProvider = Provider<Color>((ref) {
  final s = ref.watch(settingsProvider);
  return IncomeExpensePalette.income(
    customEnabled: s.customIncomeExpenseColors,
    scheme: s.incomeExpenseColorScheme,
  );
});

final expenseColorProvider = Provider<Color>((ref) {
  final s = ref.watch(settingsProvider);
  return IncomeExpensePalette.expense(
    customEnabled: s.customIncomeExpenseColors,
    scheme: s.incomeExpenseColorScheme,
  );
});

final backgroundImageServiceProvider =
    Provider<BackgroundImageService>((ref) => BackgroundImageService());

final customWallpaperAbsolutePathProvider =
    FutureProvider<String?>((ref) async {
  final settings = ref.watch(settingsProvider);
  if (!settings.hasCustomBackgroundImage) return null;

  final service = ref.watch(backgroundImageServiceProvider);
  final absolute =
      await service.resolveAbsolutePath(settings.customBgImagePath);
  if (!await File(absolute).exists()) return null;
  return absolute;
});
