import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vtuber_radar/main.dart';

void main() {
  testWidgets('Search screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Vtuber 搜索工具'), findsOneWidget);

    expect(find.byType(TextField), findsOneWidget);

    expect(find.byType(FilterChip), findsNWidgets(6));

    expect(find.text('搜索'), findsOneWidget);
  });
}
