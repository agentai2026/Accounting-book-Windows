# AI 图片记账规则文档

> **版本**：v1.0  
> **适用项目**：轻记账（ezBookkeeping Desktop / 后续手机端）  
> **OCR 引擎**：PaddleOCR PP-OCRv5 ONNX（`mobile_ocr`，约 21MB，完全离线）  
> **设计原则**：硬规则优先 → 场景专用解析 → 小票通用提取 → 轻量本地模型兜底 → 用户可修正 → 本地持续学习  

---

## 0. 文档定位

本文档是 **OCR 输出 → 记账账单** 的开发规范，与代码目录 `lib/core/rules/ai_recognition/` 及 `lib/core/services/receipt_*` 一一对应。

**不在本文档范围**：云端 API、上传图片、LLM 大模型推理。所有处理均在设备本地完成。

### 0.1 代码映射速查

| 文档章节 | 规则配置 | 执行逻辑 |
|----------|----------|----------|
| 预处理 | `image_preprocess_rules.dart` | `receipt_image_preprocessor.dart` |
| OCR 参数 | `ocr_params_rules.dart` | `receipt_recognition_service.dart` |
| 行排序 | `ocr_params_rules.dart` | `ocr_line_utils.dart` |
| 支付截图解析 | `scene_keyword_rules.dart` 等 | `receipt_text_parser.dart` |
| 小票/发票解析 | `amount_keyword_rules.dart` 等 | `receipt_bill_extractor.dart` |
| 自动分类 | `receipt_category_keyword_rules.dart` | `receipt_category_classifier.dart` |
| 去重 | `dedup_rules.dart` | `receipt_duplicate_checker.dart` |
| OCR 容错 | `ocr_correction_rules.dart` | `receipt_ocr_text_corrector.dart` |
| 表单预填 | — | `recognition_draft_formatter.dart` |

---

## 1. 输出字段定义

AI 识图最终应产出 **`BillDraft`（账单草稿）**，写入「添加交易」表单。字段定义如下。

### 1.1 核心字段

| 字段 | 内部名 | 类型 | 必填 | 说明 |
|------|--------|------|------|------|
| 商户名 | `merchant` / `payer` | `String?` | 强烈建议 | 收款方、店名；支付截图中为「付款给 xxx」 |
| 交易日期 | `date` | `DateTime?` | **是** | 规范化为 `YYYY-MM-DD`（可含时分秒） |
| 交易金额 | `amountCents` | `int` | **是** | 以**分**存储；展示保留两位小数、正数 |
| 货币 | `currency` | `String` | 否 | 默认 `CNY` |
| 交易类型 | `type` | `TransactionType` | **是** | AI 入口仅 **`expense` / `income`**，默认支出 |
| 一级分类 | `primaryCategory` | `String?` | 否 | 如：餐饮、交通、购物（规则/模型推断） |
| 二级分类 | `secondaryCategory` | `String?` | 否 | 如：早餐、地铁（可选） |
| App 分类 | `categoryName` | `String?` | 否 | 映射到账本内置分类，如「食品」「打车租车」 |
| 备注 | `description` | `String?` | 否 | 用户可见摘要 + 「—— 识图 ——」核对块 |
| 原始 OCR 文本 | `rawText` | `String?` | 否 | 全文备查、去重、持续学习样本 |
| 识别场景 | `scene` | `ReceiptScene` | 否 | 微信/支付宝/银行月账单/购物小票/未知 |
| 置信度 | `confidence` | `double` | 否 | 0~1；低于阈值标记 `lowConfidence` |
| 低置信度标记 | `lowConfidence` | `bool` | 否 | `true` 时 UI 提示用户核对 |
| 标签 | `tagNames` | `List<String>` | 否 | 如「支出」「支付宝付款」「餐饮」 |

### 1.2 支付截图额外字段

| 字段 | 说明 |
|------|------|
| `accountName` | 付款账户：微信/支付宝/借记卡尾号 |
| `balanceCents` | 截图余额，仅写入备注核对，**不**作为交易金额 |

### 1.3 金额展示规范

```
存储：amountCents = 168800  （1688.00 元）
展示：¥1688.00
支出前缀：-（可选）
收入前缀：+（可选）
```

### 1.4 AI 识图约束（产品级）

1. **不输出「转账」类型**：银行「转账-xxx + 正金额」按**收入**处理；AI 打开的表单隐藏转账 Tab。  
2. **转账备注、再转一笔** 等字段名**不能**触发转账类型。  
3. 用户可在保存前手动修改任意字段；修正结果进入持续学习样本池（见第 9 章）。

---

## 2. 整体数据流

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────────┐
│  图片输入    │ -> │  预处理       │ -> │  PP-OCRv5   │ -> │  行排序       │
│  (本地)     │    │  灰阶/降噪    │    │  检测+识别   │    │  Y→X 合并行   │
└─────────────┘    └──────────────┘    └─────────────┘    └──────────────┘
                                                                    │
                    ┌───────────────────────────────────────────────┘
                    v
         ┌──────────────────────┐
         │  OCR 容错（错字修正）  │
         └──────────────────────┘
                    │
        ┌───────────┴───────────┐
        v                       v
┌───────────────┐       ┌──────────────────┐
│ 场景分类       │       │ 结构化行列表      │
│ (微信/支付宝…) │       │ text+bbox+conf   │
└───────────────┘       └──────────────────┘
        │                       │
        v                       v
┌───────────────┐       ┌──────────────────┐
│ 支付截图解析器 │       │ 小票/发票提取器   │
│ ReceiptText   │       │ ReceiptBill      │
│ Parser        │       │ Extractor        │
└───────────────┘       └──────────────────┘
        │                       │
        └───────────┬───────────┘
                    v
         ┌──────────────────────┐
         │  结果合并（取得分高者） │
         └──────────────────────┘
                    v
         ┌──────────────────────┐
         │  自动分类 + 类型规范化 │
         └──────────────────────┘
                    v
         ┌──────────────────────┐
         │  去重检测（入库前）    │
         └──────────────────────┘
                    v
         ┌──────────────────────┐
         │  BillDraft → 表单预填  │
         └──────────────────────┘
```

### 2.1 双路解析合并策略

| 条件 | 选用路径 |
|------|----------|
| 场景分类置信度 ≥ 0.45 且非 `unknown` | **支付截图解析器**（微信/支付宝/银行） |
| 否则，小票提取器有有效金额 | **小票/发票提取器** |
| 两路都有结果 | 取得分（`confidence`）较高者 |
| 仅一路有金额 | 使用该路 |

---

## 3. OCR 前预处理规则

**原则**：不干净的图片不进 OCR。预处理在 `ReceiptImagePreprocessor` 执行，参数见 `image_preprocess_rules.dart`。

### 3.1 强制管线（当前已实现）

| 步骤 | 操作 | 参数 | 目的 |
|------|------|------|------|
| 1 | 尺寸限制 | `maxEdge = 2400` | 过大图等比缩小，控制耗时 |
| 2 | 灰阶化 | `grayscale()` | 消除彩色噪声 |
| 3 | 对比度/亮度 | `contrast=0.15, brightness=0.03` | 增强文字边缘 |
| 4 | 降噪 | 高斯模糊 `radius=1` | 去除网点、底纹 |

### 3.2 推荐增强（后续迭代）

| 步骤 | 操作 | 建议参数 | 说明 |
|------|------|----------|------|
| 自适应二值化 | 高斯自适应阈值 | `blockSize=11~21`, `C=2~4` | 解决光照不均；需原生/OpenCV |
| 透视校正 | 最大四边形轮廓 + `warpPerspective` | — | 纸质小票倾斜时效果显著 |
| 方向校正 | 文本行角度检测 / OCR cls | `use_angle_cls=true` | 插件已含 `cls.onnx` |

### 3.3 移动端拍照 UX（预留）

- 提供票据对齐辅助框。  
- 未检测到四边形时仍允许 OCR，但降低整体置信度权重。  

### 3.4 预处理开关

```dart
const kReceiptPreprocessEnabled = true; // 关闭则直送 OCR（仅调试）
```

---

## 4. OCR 调用规则

### 4.1 引擎与模型

- **引擎**：`mobile_ocr`（PP-OCRv5 ONNX）  
- **模型文件**：`det.onnx` + `rec.onnx` + `cls.onnx` + `ppocrv5_dict.txt`  
- **首次启动**：解压到本地 Support 目录，之后离线可用  

### 4.2 目标参数（规范值 / 插件现状）

| 参数 | 规范目标 | 说明 |
|------|----------|------|
| `use_angle_cls` | `true` | 方向分类，插件内置 cls 模型 |
| `det_db_thresh` | `0.2` | 降低检测阈值，提高召回（插件原生默认约 0.5，待插件暴露 API） |
| `rec_batch_num` | `6` | 识别批大小 |
| `enhanceRecognitionCrops` | `true` | 裁剪增强 |
| `includeAllConfidenceScores` | `true` | 必须保留置信度 |

### 4.3 OCR 输出结构

每一识别行必须保留：

```dart
class OcrTextLine {
  String text;           // 文本内容
  double confidence;     // 行置信度 0~1
  Rect boundingBox;      // 四点外接矩形 (x, y, w, h)
  int index;             // 排序后行号
}
```

### 4.4 阅读顺序排序

1. 按 `boundingBox.top` **升序**（自上而下）。  
2. 同一行（`|ΔY| ≤ 12px`）按 `boundingBox.left` **升序**（从左到右）。  
3. 同行文本块合并为一行，置信度取平均。  

---

## 5. 关键字段提取规则

所有规则基于 **排序后的 `List<OcrTextLine>`**。支付截图另有 **`ReceiptTextParser`** 专用逻辑（场景标签、付款时间等）。

---

### 5.1 金额提取（核心）

#### 5.1.1 候选收集

对每行文本，用正则提取所有金额候选：

```dart
// 支持：¥/$ 前缀、千分位、正负号、两位小数
final pattern = RegExp(
  r'[+-]?\s*[¥$]?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)',
);
```

每个候选记录：

```dart
class AmountCandidate {
  double yuan;          // 元
  int lineIndex;
  String lineText;
  Rect bbox;
  double confidence;
  bool fromKeyword;
}
```

**排除行**：含 `单价、数量、找零、优惠、折扣、积分、订单号` 等（见 `kReceiptAmountExcludeLineKeywords`）。

#### 5.1.2 关键词锚定（优先级从高到低）

配置于 `kReceiptAmountKeywordRules`：

| 优先级 | 关键词 |
|--------|--------|
| 100 | 实付 |
| 98 | 实收 |
| 97 | 实退 |
| 96 | 应付总额、应收总额 |
| 94 | 应付、应收 |
| 92 | 本次支付 |
| 90 | 线上支付 |
| 88 | 成交金额 |
| 86 | 支付 |
| 84 | 消费 |
| 82 | 合计 |
| 80 | 总价、TOTAL |
| 40 | 小计 |
| 10 | 找零、找赎（低优先级，仅兜底） |

**规则**：按 priority **降序**扫描；命中关键词行后，取该行内**最大有效金额**作为最终金额。

#### 5.1.3 多金额冲突决策树

```
若关键词行含多个金额：
  1. 取数值最大者（排除明显单价）
  2. 若仍相同 → 取 bbox 更靠右下者
  3. 若仍相同 → 取 bbox.height 更大者（字号更大）
  4. 若仍相同 → 取 confidence 更高者
```

#### 5.1.4 无关键词兜底

```
1. 过滤 amount < 0.01 或 amount > 1_000_000
2. 在剩余候选中：
   - 优先 bbox.bottom 最大（靠近票据底部）
   - 其次 bbox.height 最大
   - 再次 confidence 最高
```

#### 5.1.5 数字/字母混淆修正（金额行强制）

| 误识 | 修正 |
|------|------|
| O, o | 0 |
| l, I | 1 |
| S | 5 |
| B | 8 |
| `38，00` | `38.00` |

#### 5.1.6 金额格式化

```
输入：¥1,688.00 / -1688 / 1688
处理：去符号 → 去千分位 → 四舍五入到分
输出：amountCents = 168800
展示：1688.00（始终正数，方向由 type 区分）
```

#### 5.1.7 支付截图特殊规则

- 带符号金额行 `-1,688.00` / `+5,417.00` **优先于**关键词。  
- **禁止**把「余额」「积分」「手机号」当金额。  
- 银行月账单：「5417.00 0.00 + 支出/收入列」按列判断。  

---

### 5.2 商户名提取

#### 5.2.1 标签优先

若行内含以下标签，提取冒号后内容：

```
商户名称、商户名、收款单位、收款方、店名、门店
付款给、收款方、交易对方
```

示例：

```
商户名称：星巴克咖啡（人民路店）  →  星巴克咖啡
付款给 美团外卖                  →  美团外卖
```

#### 5.2.2 位置 + 字号优先（无标签时）

```
1. 取 Y 坐标最小的前 6 行作为候选
2. 排除：纯金额行、纯日期行、噪声行
3. 噪声前缀：欢迎光临、凭此小票、谢谢惠顾、NO.、Tel
4. 在候选中选 bbox.height 最大且长度 2~32 的行
5. 若无，向下扫描至全文
```

#### 5.2.3 分店后缀处理

```dart
// 去除末尾分店标记，保留品牌主体
RegExp(r'(分店|门店|旗舰店|专卖店|体验店|NO\.\d+|#\d+)$')
```

示例：`麦当劳（万达分店）` → 分类仍命中「麦当劳」。

---

### 5.3 日期提取

#### 5.3.1 正则集合

```dart
// 完整日期
RegExp(r'(\d{4})[-/.年](\d{1,2})[-/.月](\d{1,2})')

// ISO
RegExp(r'(\d{4})-(\d{2})-(\d{2})')

// 仅月日（补当前年）
RegExp(r'(\d{1,2})[-/.月](\d{1,2})[日号]?')

// 中文
RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日')

// 粘连修复（OCR 容错后）
// 2026-06-0911:35:14 → 2026-06-09 11:35:14
```

#### 5.3.2 标签加权

含以下标签的行内日期优先：

```
日期、时间、开票日期、交易日期、打印时间、
创建时间、付款时间、支付时间、交易时间
```

支付截图专用优先级见 `kReceiptDateLabelRules`（如「付款时间」= 99 分）。

#### 5.3.3 过滤规则

- **丢弃**手机状态栏时间（如单独一行 `03:07`，无日期上下文）。  
- 月日-only：默认补**当前年**；若结果晚于今天，改用**上一年**（小票场景少见，可选）。  

#### 5.3.4 EXIF 兜底

```
若全文无有效日期：
  若图片含 EXIF DateTimeOriginal → 取日期部分，备注标记「日期来自照片信息」
  否则 date = null，UI 强制展开时间选择器
```

> 桌面端截图通常无 EXIF；手机端拍照应实现此兜底。

---

### 5.4 交易类型判断

**AI 入口仅两种：`expense`（支出）、`income`（收入）。**

```
默认：expense

若全文或金额行附近（±2 行）含以下词 → income：
  退款、退货、实退、存入、转入、收款、收入、
  向你转账、转账给你、收款成功、二维码收款

金额符号辅助：
  行首 + 且场景为银行/微信收入 → income
  行首 - 或支付成功/交易成功 → expense

禁止：
  「转账备注」「再转一笔」「转账-xxx」单独触发 transfer
  银行「转账-宋宁 + ¥5417 正数」→ income（不是转账）
```

---

## 6. 自动分类规则

### 6.1 设计原则

**硬规则优先**：本地关键词表 → 现有商户规则表 → 轻量本地模型 → 默认「其他支出/其他收入」。

### 6.2 关键词映射表结构

文件：`receipt_category_keyword_rules.dart`

```dart
class ReceiptCategoryKeywordRule {
  String primary;        // 一级：餐饮
  String? secondary;     // 二级：早餐（可选）
  String appCategory;    // App 内置分类名：食品
  List<String> keywords;
  int priority;          // 冲突时越大越优先
}
```

**JSON 等价结构**（便于运营导出/导入）：

```json
{
  "primary": "餐饮",
  "secondary": null,
  "appCategory": "食品",
  "priority": 80,
  "keywords": ["麦当劳", "肯德基", "星巴克", "瑞幸", "火锅", "奶茶"]
}
```

### 6.3 匹配优先级

```
1. 精确匹配商户名 == 关键词
2. 商户名 contains 关键词（长词优先）
3. 多类命中 → 取 rule.priority 最高
4. 预设优先级：交通(90) > 餐饮(80) > 购物(70) > 其他
```

### 6.4 分类表示例（节选）

| 一级 | 二级 | App 分类 | 关键词示例 |
|------|------|----------|------------|
| 交通 | 加油 | 打车租车 | 中石油、中石化、加油站 |
| 交通 | 打车 | 打车租车 | 滴滴、高德打车、花小猪 |
| 交通 | 公交地铁 | 公共交通 | 地铁、公交、12306 |
| 餐饮 | — | 食品 | 麦当劳、肯德基、星巴克、奶茶 |
| 购物 | — | 家居用品 | 淘宝、京东、永辉、便利店 |
| 居住 | — | 水电燃气 | 水电、燃气、物业 |
| 娱乐 | — | 休闲玩乐 | 电影、KTV、游戏 |
| 医疗 | — | 医疗药品 | 医院、药店 |

完整列表以代码为准，**新增商户优先改规则文件**，无需发版逻辑。

### 6.5 轻量本地模型兜底（规划）

当关键词表未命中：

| 项目 | 规格 |
|------|------|
| 模型 | fastText 或 1~2 层 MLP |
| 体积 | 2~5 MB |
| 输入 | 商户名（分词后） |
| 输出 | 一级分类 + App 分类 |
| 推理耗时 | < 10ms（手机中端机） |
| 部署 | ONNX / TFLite，随 App 打包 |

**当前实现**：模型未接入时，回退 `kReceiptDefaultExpenseCategory` / `kReceiptDefaultIncomeCategory`。

---

## 7. 去重规则

入库前执行，实现于 `ReceiptDuplicateChecker`。

### 7.1 精确重复

在 **近 7 日**（`kReceiptDedupExactWindowDays`）内查找：

```
exists(transaction where
  amountCents == draft.amountCents
  AND date.day == draft.date.day  (允许 ±0 天，可扩展 ±1)
  AND description contains merchant
)
→ 标记 duplicateSuspected = true，提示用户「疑似重复，是否仍要保存？」
```

### 7.2 模糊重复

```
若 amountCents 相同
AND Jaccard(ocrRawText, existing.description) >= 0.85
→ 视为同一票据多次扫描
```

Jaccard 计算：按空白分词，长度 > 1 的 token 集合。

### 7.3 产品行为

| 检测结果 | 行为 |
|----------|------|
| 精确重复 | 默认建议取消；用户可强制保存 |
| 模糊重复 | 弹窗展示已有记录对比 |
| 无重复 | 正常入库 |

---

## 8. OCR 容错与后处理

### 8.1 常见错字映射

配置于 `kReceiptOcrLiteralReplacements`（整词替换）：

| 误识 | 正确 |
|------|------|
| 合汁 | 合计 |
| 实什 | 实付 |
| 总阶 | 总价 |
| 应收金客 | 应收金额 |
| 支件宝 | 支付宝 |
| 月12025 | 11月 2025 |
| 转帐 | 转账 |

### 8.2 正则纠错

`kReceiptOcrRegexReplacements` 示例：

```dart
// 日期时间粘连
'2026-06-0911:35:14' → '2026-06-09 11:35:14'

// 时间用点号
'11.35.14' → '11:35:14'

// 金额逗号小数
'38,00' → '38.00'

// 字母 O 在数字之间
'1O88' → '1088'
```

### 8.3 模糊匹配（编辑距离 ≤ 1）

对金额关键词行，若未命中精确关键词，可对 `合计/实付/总价` 等核心词做 Levenshtein-1 匹配（后续增强）。

### 8.4 漏字补全

```
若某行 == '合计' 且无数字，且下一行匹配纯金额正则：
  合并两行：'合计 38.00'
  重新走金额提取
```

### 8.5 置信度过滤

| 规则 | 阈值 |
|------|------|
| 单字符行丢弃 | confidence < 0.6 |
| 金额行低置信度标记 | line confidence < 0.7 → `lowConfidence=true` |
| 整体低置信度 | total confidence < 0.65 → UI 提示核对 |

---

## 9. 整体决策伪代码

```text
function recognizeBill(imageBytes, userOptions) -> BillDraft | Error:

  // ── 1. 预处理 ──
  img = decode(imageBytes)
  img = preprocess(img)                    // 灰阶、对比度、降噪、缩放

  // ── 2. OCR ──
  blocks = PaddleOCR.detect(img, {
    angle_cls: true,
    enhance_crops: true,
    include_confidence: true
  })
  lines = sortAndMergeLines(blocks)         // Y→X，同行合并
  rawText = join(lines)

  if rawText.isEmpty:
    return Error("未能识别文字")

  // ── 3. OCR 容错 ──
  for line in lines:
    line.text = ocrCorrect(line.text)

  // ── 4. 双路解析 ──
  payment = ReceiptTextParser.parseForRecognition(rawText, userOptions)
  bill    = ReceiptBillExtractor.extract(lines, rawText)

  result = merge(payment, bill)            // 场景置信度高 → 支付；否则小票
  if result == null:
    return Error("无法提取金额")

  // ── 5. AI 入口规范化 ──
  result.type = coerceExpenseOrIncome(result.type)
  result.categoryName = remapTransferCategory(result)
  result.tags = normalizeTags(result)

  // ── 6. 分类 ──
  if result.categoryName is empty:
    match = CategoryClassifier.classify(result.merchant, result.type)
    result.primaryCategory = match.primary
    result.secondaryCategory = match.secondary
    result.categoryName = match.appCategory
  else:
    // 可选：用 fastText 校验/修正
    pass

  // ── 7. 组装草稿 ──
  draft = toFormDraft(result, imageBytes)
  draft.description = formatRemarks(result)  // 含识图核对块

  // ── 8. 去重（保存时触发，非阻塞识图）──
  draft.duplicateHint = DuplicateChecker.check(draft, recentTransactions)

  return draft
```

---

## 10. 持续学习机制

**原则**：数据不出设备；用户修正 = 标注样本。

### 10.1 样本采集

用户保存或修改以下字段时，写入本地 SQLite 表 `recognition_feedback`：

| 列 | 说明 |
|----|------|
| `id` | 自增 |
| `ocr_raw_text` | 原始 OCR 全文 |
| `ocr_lines_json` | 结构化行（可选） |
| `predicted_merchant` | 系统识别 |
| `corrected_merchant` | 用户最终值 |
| `predicted_category` | 系统分类 |
| `corrected_category` | 用户最终值 |
| `predicted_amount_cents` | 系统金额 |
| `corrected_amount_cents` | 用户最终值 |
| `scene` | 识别场景 |
| `created_at` | 时间戳 |

**触发条件**：任一字段 `predicted != corrected`。

### 10.2 规则热更新（立即可做）

```
每累计 50 条同一 corrected_merchant：
  若 corrected_category 一致率 > 80%：
    自动追加到 receipt_category_keyword_rules.dart 对应类
    或写入 user_category_overrides.json（用户级覆盖，优先于全局表）
```

### 10.3 模型微调（后续）

```
样本量 >= 500 且设备空闲（充电 + WiFi 可选）：
  导出 (merchant, category) 为 fastText 格式
  本地训练 5~10 epoch
  导出新 model.onnx（≤5MB）
  替换 assets/models/merchant_classifier.onnx
  规则表仍优先；模型仅处理未命中项
```

### 10.4 隐私约束

- 样本库**不上传**、**不联网**。  
- 用户可在设置中「清除识图学习数据」。  
- 导出备份可选是否包含反馈样本。  

---

## 11. 测试用例要求

每改规则须补充/运行单元测试：

| 类型 | 测试文件 | 示例 |
|------|----------|------|
| 支付截图 | `receipt_text_parser_test.dart` | 支付宝 -1688、银行 +5417 |
| 购物小票 | `receipt_bill_extractor_test.dart` | 实付 38.00、退款 128.50 |
| 场景分类 | `receipt_scene_classifier_test.dart` | 微信/支付宝/银行 |
| 备注排版 | `recognition_draft_formatter_test.dart` | 识图核对块 |

运行：

```bash
flutter test test/core/services/
```

---

## 12. 性能预算（移动端参考）

| 阶段 | 目标耗时 |
|------|----------|
| 预处理 | < 100ms |
| OCR（1080p） | 500~1500ms |
| 规则提取 | < 50ms |
| 分类（关键词） | < 5ms |
| 分类（fastText） | < 10ms |
| **合计** | **< 2s（中端机）** |

---

## 13. 版本演进

| 版本 | 内容 |
|------|------|
| v1.0（当前） | 双路解析、关键词分类、预处理、容错、AI 仅支出/收入 |
| v1.1 | 透视校正、EXIF 日期、去重 UI 接入 |
| v1.2 | fastText 分类兜底、反馈样本自动写规则 |
| v2.0 | 手机端拍照框 + 持续学习闭环 |

---

## 附录 A：支付截图 vs 购物小票对照

| 维度 | 支付截图 | 购物小票/发票 |
|------|----------|---------------|
| 典型场景 | 微信、支付宝、银行 App | 超市、餐饮、加油站 |
| 解析器 | `ReceiptTextParser` | `ReceiptBillExtractor` |
| 金额来源 | 带符号金额、付款标签 | 合计/实付关键词 |
| 商户 | 付款给/收款方 | 顶部店名 |
| 日期 | 创建时间/付款时间 | 开票日期/打印时间 |
| 账户 | 微信/支付宝/卡号 | 通常无 |

---

## 附录 B：相关文档

- 项目总览：`docs/项目说明文档.md`  
- 规则维护入口：`lib/core/rules/README.md`  
- 目录结构：`docs/目录结构.md`  

---

*本文档随代码演进更新；规则以 `lib/core/rules/ai_recognition/` 源码为准。*
