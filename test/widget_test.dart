import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart';
import 'package:my_app/LibraryForm.dart';

void main() {
  for (final mode in ['App1 - HTTP', 'App2 - Provider']) {
    testWidgets('$mode opens login and registration', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.text(mode));
      await tester.pumpAndSettle();
      expect(find.text('Welcome'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();
      expect(find.text('Enter Email'), findsOneWidget);
      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();
      expect(find.text('Username'), findsOneWidget);
    });
  }
  testWidgets('Book form requires title, author, price and category', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LibraryForm(
          resource: 'Books',
          books: [],
          categories: [],
          customers: [],
        ),
      ),
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Required'), findsNWidgets(3));
    expect(find.text('Choose Category'), findsOneWidget);
  });
}
