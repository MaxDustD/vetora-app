import 'package:flutter_test/flutter_test.dart';

import 'package:vetora/app/vetora_app.dart';
import 'package:vetora/features/startup/presentation/splash_page.dart';

void main() {
  testWidgets('App abre na SplashPage', (WidgetTester tester) async {
    await tester.pumpWidget(const VetoraApp());

    expect(find.byType(SplashPage), findsOneWidget);
  });
}
