import 'package:ezbookkeeping_desktop/core/models/enums.dart';

/// 默认分类子项
class DefaultCategoryChildPreset {
  const DefaultCategoryChildPreset({
    required this.name,
    required this.icon,
  });

  final String name;
  final String icon;
}

/// 默认分类一级分组（含二级子分类）
class DefaultCategoryGroupPreset {
  const DefaultCategoryGroupPreset({
    required this.name,
    required this.icon,
    required this.children,
  });

  final String name;
  final String icon;
  final List<DefaultCategoryChildPreset> children;
}

const kDefaultExpenseCategoryPresets = <DefaultCategoryGroupPreset>[
  DefaultCategoryGroupPreset(
    name: '食品饮料',
    icon: 'restaurant',
    children: [
      DefaultCategoryChildPreset(name: '食品', icon: 'restaurant'),
      DefaultCategoryChildPreset(name: '饮料', icon: 'local_cafe'),
      DefaultCategoryChildPreset(name: '水果零食', icon: 'cookie'),
    ],
  ),
  DefaultCategoryGroupPreset(
    name: '服饰外貌',
    icon: 'checkroom',
    children: [
      DefaultCategoryChildPreset(name: '衣服', icon: 'checkroom'),
      DefaultCategoryChildPreset(name: '饰品', icon: 'diamond'),
      DefaultCategoryChildPreset(name: '化妆品', icon: 'face_retouching_natural'),
      DefaultCategoryChildPreset(name: '美容美发', icon: 'content_cut'),
    ],
  ),
  DefaultCategoryGroupPreset(
    name: '住宅家居',
    icon: 'home',
    children: [
      DefaultCategoryChildPreset(name: '家居用品', icon: 'chair'),
      DefaultCategoryChildPreset(name: '电子产品', icon: 'devices'),
      DefaultCategoryChildPreset(name: '维修保养', icon: 'build'),
      DefaultCategoryChildPreset(name: '家政服务', icon: 'cleaning_services'),
      DefaultCategoryChildPreset(name: '水电燃气', icon: 'bolt'),
      DefaultCategoryChildPreset(name: '租金贷款', icon: 'real_estate_agent'),
    ],
  ),
  DefaultCategoryGroupPreset(
    name: '交通出行',
    icon: 'directions_car',
    children: [
      DefaultCategoryChildPreset(name: '公共交通', icon: 'directions_bus'),
      DefaultCategoryChildPreset(name: '打车租车', icon: 'local_taxi'),
      DefaultCategoryChildPreset(name: '私家车费用', icon: 'directions_car'),
      DefaultCategoryChildPreset(name: '火车票', icon: 'train'),
      DefaultCategoryChildPreset(name: '飞机票', icon: 'flight'),
    ],
  ),
  DefaultCategoryGroupPreset(
    name: '交流通讯',
    icon: 'forum',
    children: [
      DefaultCategoryChildPreset(name: '电话费', icon: 'phone'),
      DefaultCategoryChildPreset(name: '上网费', icon: 'wifi'),
      DefaultCategoryChildPreset(name: '快递费', icon: 'local_shipping'),
    ],
  ),
  DefaultCategoryGroupPreset(
    name: '休闲娱乐',
    icon: 'movie',
    children: [
      DefaultCategoryChildPreset(name: '运动健身', icon: 'fitness_center'),
      DefaultCategoryChildPreset(name: '聚会支出', icon: 'groups'),
      DefaultCategoryChildPreset(name: '电影演出', icon: 'movie'),
      DefaultCategoryChildPreset(name: '玩具游戏', icon: 'sports_esports'),
      DefaultCategoryChildPreset(name: '会员订阅', icon: 'subscriptions'),
      DefaultCategoryChildPreset(name: '宠物花费', icon: 'pets'),
      DefaultCategoryChildPreset(name: '旅游度假', icon: 'beach_access'),
    ],
  ),
  DefaultCategoryGroupPreset(
    name: '教育学习',
    icon: 'school',
    children: [
      DefaultCategoryChildPreset(name: '书报杂志', icon: 'menu_book'),
      DefaultCategoryChildPreset(name: '培训课程', icon: 'school'),
      DefaultCategoryChildPreset(name: '认证考试', icon: 'assignment'),
    ],
  ),
  DefaultCategoryGroupPreset(
    name: '礼物捐赠',
    icon: 'card_giftcard',
    children: [
      DefaultCategoryChildPreset(name: '礼物', icon: 'redeem'),
      DefaultCategoryChildPreset(name: '捐赠', icon: 'volunteer_activism'),
    ],
  ),
  DefaultCategoryGroupPreset(
    name: '医疗健康',
    icon: 'local_hospital',
    children: [
      DefaultCategoryChildPreset(name: '检查治疗', icon: 'medical_services'),
      DefaultCategoryChildPreset(name: '药品', icon: 'medication'),
      DefaultCategoryChildPreset(name: '医疗器械', icon: 'healing'),
    ],
  ),
  DefaultCategoryGroupPreset(
    name: '金融保险',
    icon: 'account_balance',
    children: [
      DefaultCategoryChildPreset(name: '税费支出', icon: 'receipt_long'),
      DefaultCategoryChildPreset(name: '手续费', icon: 'paid'),
      DefaultCategoryChildPreset(name: '保险支出', icon: 'health_and_safety'),
      DefaultCategoryChildPreset(name: '利息支出', icon: 'percent'),
      DefaultCategoryChildPreset(name: '投资贷款', icon: 'savings'),
    ],
  ),
  DefaultCategoryGroupPreset(
    name: '其他杂项',
    icon: 'more_horiz',
    children: [
      DefaultCategoryChildPreset(name: '其他支出', icon: 'more_horiz'),
    ],
  ),
];

const kDefaultIncomeCategoryPresets = <DefaultCategoryGroupPreset>[
  DefaultCategoryGroupPreset(
    name: '职业收入',
    icon: 'work',
    children: [
      DefaultCategoryChildPreset(name: '工资收入', icon: 'payments'),
      DefaultCategoryChildPreset(name: '奖金收入', icon: 'emoji_events'),
      DefaultCategoryChildPreset(name: '加班收入', icon: 'schedule'),
      DefaultCategoryChildPreset(name: '兼职收入', icon: 'badge'),
    ],
  ),
  DefaultCategoryGroupPreset(
    name: '金融投资',
    icon: 'account_balance',
    children: [
      DefaultCategoryChildPreset(name: '投资收入', icon: 'trending_up'),
      DefaultCategoryChildPreset(name: '租金收入', icon: 'home_work'),
      DefaultCategoryChildPreset(name: '利息收入', icon: 'savings'),
    ],
  ),
  DefaultCategoryGroupPreset(
    name: '其他杂项',
    icon: 'more_horiz',
    children: [
      DefaultCategoryChildPreset(name: '礼品红包', icon: 'redeem'),
      DefaultCategoryChildPreset(name: '中奖收入', icon: 'confirmation_number'),
      DefaultCategoryChildPreset(name: '意外收入', icon: 'auto_awesome'),
      DefaultCategoryChildPreset(name: '其他收入', icon: 'more_horiz'),
    ],
  ),
];

const kDefaultTransferCategoryPresets = <DefaultCategoryGroupPreset>[
  DefaultCategoryGroupPreset(
    name: '一般转账',
    icon: 'swap_horiz',
    children: [
      DefaultCategoryChildPreset(name: '银行转账', icon: 'account_balance'),
      DefaultCategoryChildPreset(name: '信用卡还款', icon: 'credit_card'),
      DefaultCategoryChildPreset(name: '存款取款', icon: 'savings'),
    ],
  ),
  DefaultCategoryGroupPreset(
    name: '贷款债务',
    icon: 'request_quote',
    children: [
      DefaultCategoryChildPreset(name: '借入', icon: 'call_received'),
      DefaultCategoryChildPreset(name: '借出', icon: 'call_made'),
      DefaultCategoryChildPreset(name: '还款', icon: 'payments'),
      DefaultCategoryChildPreset(name: '收债', icon: 'assignment_turned_in'),
    ],
  ),
  DefaultCategoryGroupPreset(
    name: '其他杂项',
    icon: 'more_horiz',
    children: [
      DefaultCategoryChildPreset(name: '垫付支出', icon: 'account_balance_wallet'),
      DefaultCategoryChildPreset(name: '报销', icon: 'receipt'),
      DefaultCategoryChildPreset(name: '其他转账', icon: 'swap_horiz'),
    ],
  ),
];

List<DefaultCategoryGroupPreset> defaultCategoryPresetsFor(CategoryType type) {
  return switch (type) {
    CategoryType.expense => kDefaultExpenseCategoryPresets,
    CategoryType.income => kDefaultIncomeCategoryPresets,
    CategoryType.transfer => kDefaultTransferCategoryPresets,
  };
}
