import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:secureshare/app.dart';
import 'package:secureshare/features/auth/providers/auth_provider.dart';
import 'package:secureshare/features/files/providers/file_provider.dart';
import 'package:secureshare/features/share/providers/share_provider.dart';

void main() {
  testWidgets('SecureShare boots to login when signed out', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()..bootstrap()),
          ChangeNotifierProvider(create: (_) => FileProvider()),
          ChangeNotifierProvider(create: (_) => ShareProvider()),
        ],
        child: const SecureShareApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Masuk ke SecureShare'), findsOneWidget);
  });
}
