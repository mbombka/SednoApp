import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simplifier_app/app/app.dart';

void main() {
  testWidgets('opens the home screen with the application name', (
    tester,
  ) async {
    await tester.pumpWidget(const SimplifierApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text(SimplifierApp.name), findsOneWidget);
    expect(find.text('Welcome to SimplifierApp'), findsOneWidget);
  });
}
