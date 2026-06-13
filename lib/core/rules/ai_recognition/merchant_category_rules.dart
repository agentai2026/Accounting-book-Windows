/// 支出类商户/关键词 → 默认分类名（AI 识图自动填分类）
typedef MerchantCategoryRule = ({List<String> keywords, String category});

const kReceiptMerchantCategoryRules = <MerchantCategoryRule>[
  (keywords: ['美团', '饿了么', '外卖', '餐饮', '饭店', '咖啡', '奶茶'], category: '食品'),
  (keywords: ['滴滴', '打车', '出租', '高德', '花小猪'], category: '打车租车'),
  (keywords: ['地铁', '公交', '火车', '高铁', '飞机', '机票', '车票'], category: '公共交通'),
  (keywords: ['超市', '便利店', '购物', '淘宝', '京东', '拼多多', '天猫'], category: '家居用品'),
  (keywords: ['电影', '游戏', 'KTV', '娱乐'], category: '休闲玩乐'),
  (keywords: ['医院', '药店', '医疗', '大药房'], category: '医疗药品'),
  (keywords: ['学费', '培训', '教育'], category: '学费'),
  (keywords: ['房租', '租金', '物业'], category: '租金贷款'),
  (keywords: ['水电', '燃气', '电费', '水费'], category: '水电燃气'),
  (keywords: ['话费', '流量', '宽带', '上网', '充值'], category: '电话费'),
  (keywords: ['快递', '运费'], category: '快递费'),
  (keywords: ['星巴克', '麦当劳', '肯德基', '瑞幸'], category: '餐饮'),
  (keywords: ['沃尔玛', '山姆'], category: '购物'),
];
