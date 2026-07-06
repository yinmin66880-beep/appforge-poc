import 'package:flutter_test/flutter_test.dart';
import 'package:anti_stay_up_late/app.dart';

void main() {
  testWidgets('App can be instantiated', (WidgetTester tester) async {
    await tester.pumpWidget(const AppForgeApp(showPermissionGuide: false));
    expect(find.text('防熬夜助手'), findsOneWidget);
  });
}
