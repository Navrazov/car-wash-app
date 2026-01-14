import 'package:flutter_test/flutter_test.dart';
import 'package:car_wash_app/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CarWashApp());

    // Verify that the app loads
    expect(find.byType(CarWashApp), findsOneWidget);
  });
}
