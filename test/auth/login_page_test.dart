import 'package:alessio_test_task/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester) {
    return tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );
  }

  final submit = find.widgetWithText(FilledButton, 'Sign in');

  testWidgets('empty form shows both validation errors', (tester) async {
    await pumpPage(tester);

    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Enter your username'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('only the missing field is flagged', (tester) async {
    await pumpPage(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'emilys',
    );
    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Enter your username'), findsNothing);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('password visibility can be toggled', (tester) async {
    await pumpPage(tester);

    EditableText field() => tester.widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Password'),
        matching: find.byType(EditableText),
      ),
    );

    expect(field().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(field().obscureText, isFalse);
  });
}
