import 'package:financas_app/data/app_database.dart';
import 'package:financas_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppDatabase.configureFactory();

  testWidgets('FinancyApp renders splash screen', (tester) async {
    await tester.pumpWidget(const FinancyApp());

    expect(find.text('Financy App'), findsWidgets);
  });
}
