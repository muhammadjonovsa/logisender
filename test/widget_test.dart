import 'package:flutter_test/flutter_test.dart';
import 'package:logisender/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LogiSenderApp());
    await tester.pump();
  });
}
