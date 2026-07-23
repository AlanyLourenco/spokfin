import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spokfin/shared/app_card.dart';

void main() {
  testWidgets('AppCard renderiza o child recebido', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppCard(child: Text('conteúdo do card'))),
    );

    expect(find.text('conteúdo do card'), findsOneWidget);
  });

  testWidgets('AppCard usa padding customizado quando informado', (
    WidgetTester tester,
  ) async {
    const padding = EdgeInsets.all(4);
    await tester.pumpWidget(
      const MaterialApp(
        home: AppCard(padding: padding, child: Text('x')),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    expect(container.padding, padding);
  });
}
