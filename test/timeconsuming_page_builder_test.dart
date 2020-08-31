import 'package:flutter_test/flutter_test.dart';

import 'package:timeconsuming_page_builder/timeconsuming_page_builder.dart';

void main() {
  testWidgets('adds one to input values', (WidgetTester tester) async {
    await tester.pumpWidget(BuiltInEmptyWidget());
    expect(tester.takeException(), isAssertionError);
  });
}
