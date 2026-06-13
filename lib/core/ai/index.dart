/// AI 图片记账规则引擎
library;

export 'bill_recognition_mapper.dart';
export 'classifier/category_classifier.dart';
export 'classifier/category_rules.dart';
export 'confidence/confidence_scorer.dart';
export 'duplicate/duplicate_checker.dart';
export 'models/bill.dart';
export 'models/bill_platform.dart';
export 'models/ocr_block.dart';
export 'models/ocr_line.dart';
export 'normalize/ocr_correction_map.dart';
export 'normalize/text_normalizer.dart';
export 'parser/amount_parser.dart';
export 'parser/bill_parser.dart';
export 'parser/date_parser.dart';
export 'parser/merchant_parser.dart';
export 'parser/ocr_block_sorter.dart';
export 'parser/scene_detector.dart';
export 'parser/type_parser.dart';

import 'package:ezbookkeeping_desktop/core/ai/models/ocr_block.dart';
import 'package:ezbookkeeping_desktop/core/ai/models/bill.dart';
import 'package:ezbookkeeping_desktop/core/ai/parser/bill_parser.dart';

/// 主入口：OCR 块 → 账单
Bill? parseBillFromOCR(
  List<OcrBlock> blocks, {
  BillParserOptions options = const BillParserOptions(),
}) {
  return BillParser().parseBillFromOCR(blocks, options: options);
}
