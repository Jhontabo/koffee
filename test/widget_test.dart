import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:koffee/models/coffee_record.dart';
import 'package:koffee/models/farm.dart';
import 'package:koffee/screens/login_screen.dart';
import 'package:koffee/screens/register_screen.dart';
import 'package:koffee/theme/app_theme.dart';

void main() {
  group('UI Screen Tests', () {
    testWidgets('Login screen renders basic fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const LoginScreen(),
        ),
      );

      expect(find.text('Koffee'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(
        find.widgetWithText(ElevatedButton, 'Iniciar Sesión'),
        findsOneWidget,
      );
    });

    testWidgets('Register screen renders basic fields and buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const RegisterScreen(),
        ),
      );

      expect(find.text('Crear Cuenta'), findsNWidgets(2));
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(
        find.widgetWithText(ElevatedButton, 'Crear Cuenta'),
        findsOneWidget,
      );
    });
  });

  group('Domain Model Tests', () {
    test('CoffeeRecord calculations and map conversions', () {
      final now = DateTime(2026, 8, 25);
      final record = CoffeeRecord(
        date: now,
        farmName: 'La Esperanza',
        dryCoffeeKg: 150.0,
        pricePerKg: 14000.0,
        total: 2100000.0,
        userId: 'user123',
        firebaseId: 'doc123',
        isSynced: true,
      );

      expect(record.farmName, 'La Esperanza');
      expect(record.dryCoffeeKg, 150.0);
      expect(record.pricePerKg, 14000.0);
      expect(record.total, 2100000.0);

      final map = record.toMap();
      expect(map['farmName'], 'La Esperanza');
      expect(map['dryCoffeeKg'], 150.0);
      expect(map['total'], 2100000.0);

      final fromMap = CoffeeRecord.fromMap(map);
      expect(fromMap.farmName, 'La Esperanza');
      expect(fromMap.dryCoffeeKg, 150.0);
      expect(fromMap.firebaseId, 'doc123');
      expect(fromMap.isSynced, isTrue);
    });

    test('Farm model map conversions', () {
      final farm = Farm(
        name: 'El Paraiso',
        location: 'Huila',
        hectares: 5.5,
        userId: 'user123',
        firebaseId: 'farm123',
        isSynced: true,
      );

      expect(farm.name, 'El Paraiso');
      expect(farm.location, 'Huila');
      expect(farm.hectares, 5.5);

      final map = farm.toMap();
      expect(map['name'], 'El Paraiso');
      expect(map['location'], 'Huila');
      expect(map['hectares'], 5.5);

      final fromMap = Farm.fromMap(map);
      expect(fromMap.name, 'El Paraiso');
      expect(fromMap.location, 'Huila');
      expect(fromMap.hectares, 5.5);
      expect(fromMap.firebaseId, 'farm123');
      expect(fromMap.isSynced, isTrue);
    });
  });

  group('Design System Tokens', () {
    test('AppPalette colors are properly configured', () {
      expect(AppPalette.espresso, const Color(0xFF2E1C14));
      expect(AppPalette.cocoa, const Color(0xFF4E342E));
      expect(AppPalette.caramel, const Color(0xFFD49757));
      expect(AppPalette.leaf, const Color(0xFF2E7D47));
      expect(AppPalette.crema, const Color(0xFFFAF7F2));
    });
  });
}
