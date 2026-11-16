// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:previsao_cptec/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Tela inicial exibe campo de busca e mensagem inicial', (WidgetTester tester) async {
    await tester.pumpWidget(const PrevisaoApp());
    await tester.pumpAndSettle();

    expect(find.text('Previsão do Tempo'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Pesquise uma cidade para ver a previsão do tempo.'), findsOneWidget);
    expect(find.text('Fonte dos dados: CPTEC/INPE'), findsOneWidget);
  });
  testWidgets('Exibe erro de validação ao buscar menos de 2 caracteres', (WidgetTester tester) async {
    await tester.pumpWidget(const PrevisaoApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'a');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();

    expect(find.text('Digite pelo menos 2 caracteres para pesquisar.'), findsOneWidget);
  });
}