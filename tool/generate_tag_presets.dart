// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';

const target = 10000;
const maxLen = 20;

void add(Set<String> tags, String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty || trimmed.length > maxLen) return;
  tags.add(trimmed);
}

void main() {
  final random = Random(20260613);
  final tags = <String>{};

  const scenes = [
    '日常', '工作', '生活', '家庭', '社交', '旅行', '出差', '学习', '健身', '娱乐',
    '周末', '节假日', '通勤', '加班', '夜宵', '早餐', '午餐', '晚餐', '下午茶',
    '网购', '线下', '团购', '秒杀', '预售', '会员', '订阅', '续费', '充值',
    '报销', '垫付', '代付', '分摊', 'AA', '礼金', '红包', '转账', '还款',
    '应急', '备用', '临时', '必要', '非必要', '奢侈', '节俭', '健康', '医疗',
    '保养', '维修', '清洁', '收纳', '搬家', '装修', '租房', '育儿', '宠物',
    '养老', '赡养', '孝敬', '聚会', '约会', '婚礼', '生日', '纪念日', '毕业',
    '升学', '考试', '培训', '考证', '兴趣', '爱好', '计划内', '计划外', '犒劳',
    '居家', '办公', '户外', '露营', '自驾', '探亲', '访友', '团建', '年会',
  ];

  const categories = [
    '餐饮', '美食', '外卖', '堂食', '咖啡', '奶茶', '甜品', '零食', '水果', '蔬菜',
    '交通', '打车', '地铁', '公交', '高铁', '飞机', '停车', '加油', '充电', '过路费',
    '购物', '服饰', '鞋帽', '美妆', '护肤', '数码', '家电', '家具', '文具', '图书',
    '住房', '物业', '水电', '燃气', '宽带', '话费', '保险', '税费', '手续费', '利息',
    '药品', '体检', '牙科', '眼科', '瑜伽', '游泳', '球类', '学费', '网课', '教材',
    '辅导', '留学', '旅游', '酒店', '民宿', '门票', '电影', '游戏', '音乐', '演出',
    '展览', '直播', '打赏', '理财', '基金', '股票', '债券', '黄金', '外汇', '存款',
    '借贷', '请客', '送礼', '慈善', '捐赠', '公益', '志愿', '互助', '人情', '礼金',
    '母婴', '童装', '玩具', '厨具', '床品', '清洁用品', '洗护', '香水', '饰品', '箱包',
  ];

  const people = [
    '自己', '配偶', '父母', '子女', '兄弟姐妹', '亲戚', '朋友', '同事', '领导', '客户',
    '同学', '老师', '邻居', '室友', '伴侣', '宝宝', '老人', '宠物', '团队', '公司',
    '甲方', '乙方', '供应商', '合作方', '房东', '租客', '师傅', '教练', '医生', '护士',
  ];

  const moods = [
    '开心', '奖励', '解压', '放松', '治愈', '冲动', '后悔', '值得', '划算', '超值',
    '踩雷', '避雷', '推荐', '回购', '尝鲜', '限量', '经典', '必备', '可选', '满意',
    '刚需', '改善', '升级', '替换', '补货', '囤货', '清仓', '特价', '秒杀', '预售',
  ];

  const platforms = [
    '淘宝', '天猫', '京东', '拼多多', '抖音', '快手', '小红书', '美团', '饿了么',
    '盒马', '山姆', '闲鱼', '得物', '唯品会', '苏宁', '微信', '支付宝', '云闪付',
    '星巴克', '瑞幸', '喜茶', '奈雪', '蜜雪冰城', '肯德基', '麦当劳', '必胜客',
    '海底捞', '西贝', '老乡鸡', '华为', '小米', '苹果', '耐克', '阿迪', '优衣库',
    'B站', '爱奇艺', '腾讯视频', '网易云', 'Keep', '滴滴', '高德', '携程', '飞猪',
  ];

  const foods = [
    '火锅', '烧烤', '麻辣烫', '米线', '拉面', '寿司', '披萨', '汉堡', '炸鸡', '烤鸭',
    '饺子', '包子', '粥', '炒饭', '盖饭', '轻食', '沙拉', '牛排', '海鲜', '小龙虾',
    '蛋糕', '面包', '冰淇淋', '巧克力', '坚果', '酸奶', '豆浆', '茶饮', '川菜', '粤菜',
    '湘菜', '鲁菜', '浙菜', '闽菜', '徽菜', '苏菜', '东北菜', '西北菜', '日料', '韩餐',
    '泰餐', '西餐', '法餐', '意餐', '东南亚', '清真', '素食', '减脂餐', '冒菜', '串串',
    '烤鱼', '干锅', '卤味', '煎饼', '凉皮', '肉夹馍', '螺蛳粉', '酸辣粉', '肠粉', '早茶',
  ];

  const hobbies = [
    '跑步', '骑行', '徒步', '露营', '登山', '滑雪', '潜水', '钓鱼', '棋类', '绘画',
    '书法', '吉他', '钢琴', '舞蹈', '唱歌', '追剧', '动漫', '手办', '模型', '乐高',
    '烘焙', '烹饪', '花艺', '园艺', '茶艺', '品酒', '收藏', '摄影', '剪辑', '编程',
    '写作', '阅读', '冥想', '普拉提', '拳击', '羽毛球', '网球', '篮球', '足球', '乒乓',
    '游泳', '瑜伽', '攀岩', '滑板', '轮滑', '射箭', '台球', '麻将', '桌游', '剧本杀',
  ];

  const holidays = [
    '春节', '元宵', '清明', '端午', '中秋', '国庆', '元旦', '情人节', '妇女节', '劳动节',
    '儿童节', '教师节', '万圣节', '感恩节', '圣诞节', '七夕', '腊八', '小年', '除夕', '重阳',
  ];

  const merchants = [
    '超市', '便利店', '菜市场', '药店', '医院', '诊所', '加油站', '停车场', '理发店',
    '美容院', '健身房', '游泳馆', '电影院', 'KTV', '网吧', '书店', '文具店', '五金店',
    '家具城', '建材城', '4S店', '洗车店', '快递', '物流', '家政', '物业', '银行', '邮局',
    '营业厅', '车管所', '派出所', '政务大厅', '菜市场', '水果店', '面包店', '咖啡店',
  ];

  const adjectives = [
    '大额', '小额', '固定', '浮动', '月度', '季度', '年度', '单次', '长期', '短期',
    '线上', '线下', '国内', '国外', '本地', '异地', '紧急', '常规', '特殊', '普通',
    '首次', '再次', '补差', '退款', '返现', '优惠', '折扣', '满减', '包邮', '自提',
    '分期', '免息', '预付', '尾款', '定金', '押金', '违约金', '滞纳金', '服务费', '会员价',
  ];

  const times = [
    '清晨', '上午', '中午', '下午', '傍晚', '夜晚', '深夜', '周一', '周二', '周三',
    '周四', '周五', '周六', '周日', '月初', '月中', '月末', '年初', '年中', '年末',
    '春季', '夏季', '秋季', '冬季', '寒假', '暑假', '黄金周', '小长假', '工作日', '休息日',
  ];

  const items = [
    '手机', '电脑', '平板', '耳机', '键盘', '鼠标', '显示器', '路由器', '充电宝', '数据线',
    '冰箱', '洗衣机', '空调', '电视', '微波炉', '电饭煲', '吸尘器', '净水器', '热水器', '台灯',
    '衬衫', '外套', '裤子', '裙子', '运动鞋', '皮鞋', '袜子', '内衣', '围巾', '帽子',
    '口红', '粉底', '面膜', '洗发水', '牙膏', '纸巾', '洗衣液', '垃圾袋', '保鲜膜', '洗洁精',
  ];

  const payments = [
    '花呗', '信用卡', '储蓄卡', '零钱', '余额宝', '白条', '分期乐', '数字人民币', '现金', '刷卡',
  ];

  const seasons = ['春装', '夏装', '秋装', '冬装', '换季', '反季'];

  for (final lst in [
    scenes, categories, people, moods, platforms, foods, hobbies, holidays,
    merchants, adjectives, times, items, payments, seasons,
  ]) {
    for (final item in lst) {
      add(tags, item);
    }
  }

  for (final s in scenes) {
    for (final c in categories) {
      add(tags, '$s$c');
    }
  }

  for (final p in people) {
    for (final s in scenes) {
      add(tags, '$p$s');
    }
    for (final c in categories) {
      add(tags, '$p$c');
    }
  }

  for (final pl in platforms) {
    for (final c in categories) {
      add(tags, '$pl$c');
    }
    for (final f in foods) {
      add(tags, '$pl$f');
    }
    for (final m in moods.take(20)) {
      add(tags, '$pl$m');
    }
  }

  for (final h in holidays) {
    for (final s in scenes) {
      add(tags, '$h$s');
    }
    for (final c in categories) {
      add(tags, '$h$c');
    }
  }

  for (final m in moods) {
    for (final c in categories) {
      add(tags, '$m$c');
    }
    for (final f in foods) {
      add(tags, '$m$f');
    }
  }

  for (final hb in hobbies) {
    for (final s in scenes.take(30)) {
      add(tags, '$hb$s');
    }
    for (final t in times.take(20)) {
      add(tags, '$hb$t');
    }
    for (final c in categories.take(25)) {
      add(tags, '$hb$c');
    }
  }

  for (final adj in adjectives) {
    for (final c in categories) {
      add(tags, '$adj$c');
    }
    for (final item in items.take(25)) {
      add(tags, '$adj$item');
    }
  }

  for (final t in times) {
    for (final c in categories) {
      add(tags, '$t$c');
    }
    for (final s in scenes.take(35)) {
      add(tags, '$t$s');
    }
  }

  for (final f in foods) {
    for (final s in scenes.take(30)) {
      add(tags, '$f$s');
    }
    for (final c in categories.take(20)) {
      add(tags, '$f$c');
    }
  }

  for (final m in merchants) {
    for (final c in categories.take(30)) {
      add(tags, '$m$c');
    }
    for (final s in scenes.take(20)) {
      add(tags, '$m$s');
    }
  }

  for (final pay in payments) {
    for (final c in categories.take(40)) {
      add(tags, '$pay$c');
    }
    for (final pl in platforms.take(25)) {
      add(tags, '$pay$pl');
    }
  }

  for (final item in items) {
    for (final s in scenes.take(15)) {
      add(tags, '$item$s');
    }
    for (final adj in adjectives.take(10)) {
      add(tags, '$adj$item');
    }
  }

  final years = [for (var y = 2018; y <= 2030; y++) '$y'];
  for (final y in years) {
    for (final h in holidays) {
      add(tags, '$y$h');
    }
    for (final s in scenes.take(25)) {
      add(tags, '$y$s');
    }
    for (final c in categories.take(25)) {
      add(tags, '$y$c');
    }
    for (var mo = 1; mo <= 12; mo++) {
      add(tags, '${y}年$mo月');
      for (final c in categories.take(10)) {
        add(tags, '$y${mo}月$c');
      }
    }
  }

  final bases = [...scenes, ...categories, ...foods, ...hobbies, ...items];
  const suffixes = ['支出', '收入', '消费', '账单', '记录', '预算', '备用', '专项', '项目', '科目'];
  for (final b in bases) {
    for (final suf in suffixes) {
      add(tags, '$b$suf');
    }
  }

  final poolA = [
    ...scenes, ...categories, ...people, ...moods, ...foods, ...hobbies,
    ...adjectives, ...items, ...payments, ...platforms.take(25),
  ];
  final poolB = [
    ...categories, ...scenes, ...merchants, ...times, ...moods, ...items,
  ];
  var attempts = 0;
  while (tags.length < target && attempts < 800000) {
    attempts++;
    final a = poolA[random.nextInt(poolA.length)];
    final b = poolB[random.nextInt(poolB.length)];
    if (a == b) continue;
    add(tags, '$a$b');
    if (random.nextDouble() < 0.35) {
      final extras = random.nextBool() ? times : moods;
      final c = extras[random.nextInt(extras.length)];
      add(tags, '$a$b$c');
    }
  }

  if (tags.length < target) {
    stderr.writeln('仅生成 ${tags.length} 条，未达 $target');
    exit(1);
  }

  final ordered = tags.toList()..sort();
  final result = ordered.take(target).toList(growable: false);

  final outFile = File('assets/data/tag_presets.txt');
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync('${result.join('\n')}\n');

  print('已写入 ${result.length} 条标签 -> ${outFile.path}');
  assert(result.length == result.toSet().length);
}
