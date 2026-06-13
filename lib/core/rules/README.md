# 规则目录（`lib/core/rules/`）

> **完整规范**：见 [`docs/AI图片记账规则文档.md`](../../docs/AI图片记账规则文档.md)

本目录集中存放**可配置、可扩展**的业务规则，与具体解析/导入逻辑（`services/`）分离。

日常改规则优先改这里，改完运行 `flutter test test/core/` 验证。

---

## 目录说明

```
rules/                    ← 可配置规则常量
lib/core/ai/              ← OCR 后处理规则引擎（模块化实现）
├── models/               bill.dart, ocr_block.dart
├── normalize/            text_normalizer.dart
├── parser/               amount/merchant/date/type/bill_parser
├── classifier/           category_classifier.dart + category_rules
├── duplicate/            duplicate_checker.dart
├── confidence/           confidence_scorer.dart
└── index.dart            parseBillFromOCR() 主入口
```

| 子目录 | 用途 | 主要文件 |
|--------|------|----------|
| `ai_recognition/` | 截图 OCR 纠错、类型/时间/场景/商户分类 | 见下方 |
| `import/` | 支持的文件类型、列名别名、表头模板 | `file_types.dart`、`column_definitions.dart` |
| `bookkeeping/` | 收支统计口径、导入时跳过哪些行 | `metrics_rules.dart` |

---

## AI 识图：识别目标（输出字段）

| 字段 | 说明 | 必填 |
|------|------|------|
| 商户名 | `payer` / 收款方 | 强烈建议 |
| 交易日期 | `date`，YYYY-MM-DD | 是 |
| 交易金额 | `amountCents`，两位小数 | 是 |
| 货币 | `currency`，默认 CNY | 否 |
| 交易类型 | 支出 / 收入（AI 入口不含转账） | 是 |
| 一级/二级分类 | `primaryCategory` / `secondaryCategory` | 自动推断 |
| 备注 | `description` + 识图核对块 | 否 |
| 原始文本 | `rawText` | 否 |

**管线**：图片预处理 → PP-OCRv5 → 行排序 → 支付截图解析 / 小票规则提取 → 合并 → 表单预填

---

## AI 识图：规则文件索引

| 规范章节 | 文件 |
|----------|------|
| 二、图片预处理 | `image_preprocess_rules.dart` + `receipt_image_preprocessor.dart` |
| 三、OCR 参数 | `ocr_params_rules.dart` |
| 4.1 金额 | `amount_keyword_rules.dart` + `receipt_bill_extractor.dart` |
| 4.2 商户 | `merchant_extraction_rules.dart` |
| 4.3 日期 | `date_label_rules.dart`（支付截图）+ 小票内嵌正则 |
| 4.4 类型 | `type_detection_rules.dart` |
| 5.x 分类 | `receipt_category_keyword_rules.dart` + `merchant_category_rules.dart` |
| 6 去重 | `dedup_rules.dart` + `receipt_duplicate_checker.dart` |
| 7 OCR 容错 | `ocr_correction_rules.dart` + `confidence_rules.dart` |

**AI 识图入口**（`ReceiptRecognitionService`）使用 `parseForRecognition`，**只输出支出 / 收入**；购物小票走 `ReceiptBillExtractor`。

### 1. OCR 错字 / 格式修正

文件：`ai_recognition/ocr_correction_rules.dart`

- `kReceiptOcrLiteralReplacements` — 整词替换（如 `合汁` → `合计`）
- `kReceiptOcrRegexReplacements` — 正则替换（如日期时间粘连）
- `kReceiptIgnoredAmountKeywords` — 含这些词的行不参与取金额

### 2. 交易类型（支出 / 收入）

文件：`ai_recognition/type_detection_rules.dart`

- `kReceiptIncomeContextKeywords` — 含「退款 / 退货 / 收款」等 → 收入
- `kReceiptExpenseContextKeywords` — 判定支出

### 3. 交易时间

文件：`ai_recognition/date_label_rules.dart`

- `kReceiptDateLabelRules` — 带优先级的标签列表（如「付款时间」99 分）

### 4. 商户 → 默认分类

文件：`ai_recognition/merchant_category_rules.dart`、`receipt_category_keyword_rules.dart`

- 小票一级分类关键词表（餐饮 / 交通 / 购物…）→ App 默认分类名

### 5. 场景识别（微信 / 支付宝 / 银行月账单）

文件：`ai_recognition/scene_keyword_rules.dart`

- 各场景加分关键词，供 `ReceiptSceneClassifier` 使用

### 6. 持续优化（预留）

用户手动修正后的 `(OCR原文, 修正字段)` 样本可写入本地，用于后续更新 `receipt_category_keyword_rules.dart` 或轻量分类模型。

---

## 账单导入：如何加规则

### 1. 新增导入文件类型

文件：`import/file_types.dart` → `ImportFileTypes.all` 增加一项。

### 2. 列名识别（支付宝/微信/自定义 CSV）

文件：`import/column_definitions.dart` → 各 `*Aliases` 数组追加同义表头。

### 3. 哪些行不要导入

文件：`bookkeeping/metrics_rules.dart` → `excludedStatuses`、`shouldImportRow`。

---

## 兼容说明

旧路径 `lib/core/constants/*_rules.dart` 仍保留 **export 转发**，现有 import 不用改也能编译；新代码请直接引用 `core/rules/...`。
