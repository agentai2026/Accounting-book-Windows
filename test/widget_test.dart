import 'package:ezbookkeeping_desktop/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('应用可以启动', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: EzBookkeepingApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('交易数据'), findsOneWidget);
  });
}
