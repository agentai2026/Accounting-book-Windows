import 'package:flutter_test/flutter_test.dart';

import 'package:ezbookkeeping_desktop/desktop/widgets/transaction/add_transaction_tag_field.dart';

void main() {
  test('mergeTagNamesForSubmit includes pending input without duplicates', () {
    final merged = mergeTagNamesForSubmit(
      selectedNames: ['餐饮', '工作'],
      pendingInput: '旅行,餐饮',
    );
    expect(merged, ['餐饮', '工作', '旅行']);
  });

  test('mergeTagNamesForSubmit ignores empty pending', () {
    expect(
      mergeTagNamesForSubmit(selectedNames: ['餐饮'], pendingInput: '  '),
      ['餐饮'],
    );
  });
}
