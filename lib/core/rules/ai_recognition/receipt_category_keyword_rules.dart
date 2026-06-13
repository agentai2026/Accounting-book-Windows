/// 5.1 小票商户 → 一级/二级分类关键词（硬规则）
class ReceiptCategoryKeywordRule {
  const ReceiptCategoryKeywordRule({
    required this.primary,
    this.secondary,
    required this.appCategory,
    required this.keywords,
    required this.priority,
  });

  /// 一级分类（如 餐饮）
  final String primary;

  /// 二级分类（如 早餐），可选
  final String? secondary;

  /// 映射到 App 默认分类名
  final String appCategory;
  final List<String> keywords;

  /// 多类冲突时：数值越大越优先（交通 > 餐饮 > 购物）
  final int priority;
}

const kReceiptCategoryKeywordRules = <ReceiptCategoryKeywordRule>[
  ReceiptCategoryKeywordRule(
    primary: '交通',
    secondary: '加油',
    appCategory: '打车租车',
    keywords: ['中石油', '中石化', '加油站', '壳牌'],
    priority: 90,
  ),
  ReceiptCategoryKeywordRule(
    primary: '交通',
    secondary: '打车',
    appCategory: '打车租车',
    keywords: ['滴滴', '高德打车', '花小猪', '曹操出行', 'T3出行'],
    priority: 88,
  ),
  ReceiptCategoryKeywordRule(
    primary: '交通',
    secondary: '公交地铁',
    appCategory: '公共交通',
    keywords: ['公交', '地铁', '铁路12306', '12306', '火车票'],
    priority: 86,
  ),
  ReceiptCategoryKeywordRule(
    primary: '餐饮',
    appCategory: '食品',
    keywords: [
      '麦当劳',
      '肯德基',
      '海底捞',
      '食堂',
      '餐厅',
      '面馆',
      '麻辣烫',
      '奶茶',
      '星巴克',
      '瑞幸',
      '必胜客',
      '汉堡',
      '烧烤',
      '火锅',
    ],
    priority: 80,
  ),
  ReceiptCategoryKeywordRule(
    primary: '购物',
    appCategory: '家居用品',
    keywords: [
      '淘宝',
      '京东',
      '拼多多',
      '永辉',
      '超市',
      '便利店',
      '名创优品',
      '无印良品',
      '沃尔玛',
      '山姆',
      '7-11',
      '全家',
      '罗森',
    ],
    priority: 70,
  ),
  ReceiptCategoryKeywordRule(
    primary: '居住',
    appCategory: '水电燃气',
    keywords: ['水电', '燃气', '物业', '电费', '水费'],
    priority: 60,
  ),
  ReceiptCategoryKeywordRule(
    primary: '娱乐',
    appCategory: '休闲玩乐',
    keywords: ['电影', 'KTV', '游戏', '影院', '万达影城'],
    priority: 55,
  ),
  ReceiptCategoryKeywordRule(
    primary: '医疗',
    appCategory: '医疗药品',
    keywords: ['医院', '药店', '大药房', '诊所'],
    priority: 50,
  ),
];

/// 规则未命中时的默认 App 分类
const kReceiptDefaultExpenseCategory = '其他支出';
const kReceiptDefaultIncomeCategory = '其他收入';
