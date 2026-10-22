import 'package:flutter_test/flutter_test.dart';
import 'package:nguyen_trong_khanh/main.dart';

void main() {
  testWidgets('App loads LoginScreen properly test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.textContaining('An toàn Trẻ em'), findsOneWidget);
    expect(find.textContaining('Child Safety Platform'), findsOneWidget);
  });
}
