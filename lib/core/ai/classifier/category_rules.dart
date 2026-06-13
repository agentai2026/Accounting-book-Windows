/// 商户精确匹配数据库（等价 merchant-database.json）
const kMerchantDatabase = <String, String>{
  '麦当劳': '餐饮',
  '肯德基': '餐饮',
  '星巴克': '餐饮',
  '瑞幸咖啡': '餐饮',
  '海底捞': '餐饮',
  '滴滴出行': '交通',
  '高德打车': '交通',
  '中石油': '交通',
  '中石化': '交通',
  '京东': '购物',
  '淘宝': '购物',
  '拼多多': '购物',
  '永辉超市': '购物',
  '沃尔玛': '购物',
  '美团': '餐饮',
  '饿了么': '餐饮',
  '12306': '交通',
  '铁路12306': '交通',
};

/// 分类关键词规则（等价 category-rules.json）
class CategoryRuleEntry {
  const CategoryRuleEntry({
    required this.category,
    required this.appCategory,
    required this.keywords,
    this.priority = 50,
  });

  final String category;
  final String appCategory;
  final List<String> keywords;
  final int priority;
}

const kCategoryRules = <CategoryRuleEntry>[
  CategoryRuleEntry(
    category: '交通',
    appCategory: '打车租车',
    keywords: ['滴滴', '高德', '中石油', '中石化', '加油站', '出租'],
    priority: 90,
  ),
  CategoryRuleEntry(
    category: '交通',
    appCategory: '公共交通',
    keywords: ['地铁', '公交', '12306', '铁路', '火车'],
    priority: 88,
  ),
  CategoryRuleEntry(
    category: '餐饮',
    appCategory: '食品',
    keywords: ['麦当劳', '肯德基', '星巴克', '瑞幸', '火锅', '奶茶', '餐厅', '食堂'],
    priority: 80,
  ),
  CategoryRuleEntry(
    category: '购物',
    appCategory: '家居用品',
    keywords: ['淘宝', '京东', '拼多多', '超市', '便利店', '沃尔玛'],
    priority: 70,
  ),
  CategoryRuleEntry(
    category: '娱乐',
    appCategory: '休闲玩乐',
    keywords: ['电影', 'KTV', '游戏', '影院'],
    priority: 55,
  ),
  CategoryRuleEntry(
    category: '医疗',
    appCategory: '医疗药品',
    keywords: ['医院', '药店', '大药房'],
    priority: 50,
  ),
  CategoryRuleEntry(
    category: '教育',
    appCategory: '学费',
    keywords: ['学费', '培训', '教育'],
    priority: 48,
  ),
  CategoryRuleEntry(
    category: '居住',
    appCategory: '水电燃气',
    keywords: ['水电', '燃气', '物业', '房租'],
    priority: 45,
  ),
  CategoryRuleEntry(
    category: '生活',
    appCategory: '其他支出',
    keywords: ['快递', '话费', '充值'],
    priority: 40,
  ),
];

const kDefaultCategory = '其他';
