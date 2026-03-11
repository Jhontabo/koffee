import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:koffee/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders basic fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Koffee'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(
      find.widgetWithText(ElevatedButton, 'Iniciar Sesión'),
      findsOneWidget,
    );
  });
}
