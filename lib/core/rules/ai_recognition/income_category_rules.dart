/// 收入类商户/关键词 → 默认分类名
typedef IncomeCategoryRule = ({List<String> keywords, String category});

const kReceiptIncomeCategoryRules = <IncomeCategoryRule>[
  (keywords: ['工资', '薪资', '薪水'], category: '工资收入'),
  (keywords: ['奖金', '年终奖'], category: '奖金收入'),
  (keywords: ['兼职', '副业'], category: '兼职收入'),
  (keywords: ['利息', '理财', '基金', '股票'], category: '投资收入'),
  (keywords: ['租金'], category: '租金收入'),
  (keywords: ['红包', '礼金'], category: '礼品红包'),
  (keywords: ['报销'], category: '报销'),
];
