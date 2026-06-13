import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ezbookkeeping_desktop/desktop/constants/settings_models.dart';
import 'package:ezbookkeeping_desktop/desktop/providers/settings_provider.dart';
import 'package:ezbookkeeping_desktop/desktop/theme/app_colors.dart';

import 'package:ezbookkeeping_desktop/core/constants/icon_constants.dart';
import 'package:ezbookkeeping_desktop/desktop/constants/line_awesome_icon_resolver.dart';

class CategoryIconOption {
  const CategoryIconOption({
    required this.key,
    required this.icon,
  });

  final String key;
  final IconData icon;
}

/// Same IDs and order as ezBookkeeping `ALL_CATEGORY_ICONS`.
final kCategoryIconCatalog = [
  for (final id in categoryIconIdsInOrder)
    CategoryIconOption(
      key: id,
      icon: lineAwesomeIconFromCssClass(categoryIconCssClass(id)),
    ),
];

/// Legacy Material icon names used in early desktop seed data.
const _legacyCategoryIconKeyAliases = {
  'restaurant': '1',
  'local_cafe': '31',
  'cookie': '71',
  'checkroom': '110',
  'diamond': '170',
  'face_retouching_natural': '180',
  'content_cut': '190',
  'home': '200',
  'chair': '222',
  'devices': '431',
  'build': '251',
  'cleaning_services': '260',
  'bolt': '231',
  'real_estate_agent': '200',
  'directions_car': '330',
  'directions_bus': '310',
  'local_taxi': '320',
  'train': '370',
  'flight': '390',
  'forum': '460',
  'phone': '420',
  'wifi': '440',
  'local_shipping': '480',
  'movie': '550',
  'fitness_center': '510',
  'groups': '901',
  'sports_esports': '560',
  'subscriptions': '553',
  'pets': '580',
  'beach_access': '590',
  'school': '640',
  'menu_book': '611',
  'assignment': '660',
  'card_giftcard': '710',
  'redeem': '710',
  'volunteer_activism': '780',
  'local_hospital': '810',
  'medical_services': '821',
  'medication': '862',
  'healing': '863',
  'account_balance': '900',
  'receipt_long': '920',
  'paid': '930',
  'health_and_safety': '560',
  'percent': '970',
  'savings': '981',
  'more_horiz': '1010',
  'work': '2000',
  'payments': '930',
  'emoji_events': '2020',
  'schedule': '2080',
  'badge': '570',
  'trending_up': '2101',
  'home_work': '201',
  'confirmation_number': '510',
  'auto_awesome': '5010',
  'swap_horiz': '4000',
  'credit_card': '980',
  'request_quote': '950',
  'call_received': '4900',
  'call_made': '3010',
  'assignment_turned_in': '960',
  'account_balance_wallet': '2010',
  'receipt': '701',
  'shopping_cart': '5102',
};

String resolveCategoryIconKey(String? key) {
  if (key == null || key.isEmpty) return defaultCategoryIconId;
  return _legacyCategoryIconKeyAliases[key] ?? key;
}

CategoryIconOption categoryIconOptionOf(String? key) {
  final resolved = resolveCategoryIconKey(key);
  for (final option in kCategoryIconCatalog) {
    if (option.key == resolved) return option;
  }
  return CategoryIconOption(
    key: resolved,
    icon: lineAwesomeIconFromCssClass(categoryIconCssClass(resolved)),
  );
}

Widget buildCategoryIconWidget(
  String? iconKey, {
  Color? color,
  double size = 22,
  BuildContext? context,
}) {
  final option = categoryIconOptionOf(iconKey);
  var resolvedColor = color ?? Colors.black87;
  var rounded = false;
  var monochrome = false;
  var scale = 1.0;

  if (context != null) {
    try {
      final container = ProviderScope.containerOf(context);
      final settings = container.read(settingsProvider);
      rounded = settings.useRoundedIcons;
      monochrome = settings.iconMonochromeMode;
      scale = switch (settings.iconSize) {
        SettingsIconSize.small => 0.88,
        SettingsIconSize.medium => 1.0,
        SettingsIconSize.large => 1.16,
      };
    } catch (_) {}
  }

  final iconSize = size * scale;
  if (monochrome && color == null) {
    resolvedColor = AppColors.primary;
  }

  Widget icon = Icon(option.icon, size: iconSize, color: resolvedColor);

  if (rounded) {
    icon = Container(
      padding: EdgeInsets.all(iconSize * 0.2),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(iconSize * 0.32),
      ),
      child: icon,
    );
  }

  return icon;
}

IconData categoryIconData(String? iconKey) {
  return categoryIconOptionOf(iconKey).icon;
}
