import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyhawk/main.dart';

void main() {
  testWidgets('defaults to an unmistakable paper mode banner', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoneyHawkApp()));
    expect(find.byKey(const Key('mode-banner')), findsOneWidget);
    expect(find.textContaining('PAPER MODE'), findsOneWidget);
    expect(find.text('LIVE MODE'), findsNothing);
  });

  testWidgets('live mode is shown distinctly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tradingModeProvider.overrideWithValue(TradingMode.live)],
        child: const MoneyHawkApp(),
      ),
    );
    expect(find.text('LIVE MODE'), findsOneWidget);
  });
}
