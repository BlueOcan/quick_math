import 'package:flutter_test/flutter_test.dart';
import 'package:quick_math/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MathVibeApp());
  });
}
