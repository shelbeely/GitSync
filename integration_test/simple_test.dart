import 'package:flutter_test/flutter_test.dart';
import 'package:GitSync/main.dart';
import 'package:GitSync/src/rust/api/git_manager.dart' as RustLib;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());
  // This test requires a connected device and the compiled Rust bridge.
  // Run with: flutter test integration_test/ on a real device or emulator.
  testWidgets('Can call rust function', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.textContaining('Result: `Hello, Tom!`'), findsOneWidget);
  }, skip: 'Requires a device and compiled Rust bridge – run via flutter test integration_test/');
}
