// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:bitsxlamarato_frontend_2025/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Initial page shows the landing actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Començem!'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
    expect(find.text('REGISTRAR-SE'), findsOneWidget);
  });

  testWidgets('Theme toggle updates the icon', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final darkModeToggle = find.byIcon(Icons.nightlight_round);
    expect(darkModeToggle, findsOneWidget);

    await tester.tap(darkModeToggle);
    await tester.pump();

    expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
  });
}
