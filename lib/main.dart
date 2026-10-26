import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MoneyHawkApp()));
}

/// Trading environment the app is connected to. Paper is the default; live
/// must never be enabled by a client build (see plan.md section 3.4).
enum TradingMode { paper, live }

final tradingModeProvider = Provider<TradingMode>((ref) => TradingMode.paper);

class MoneyHawkApp extends StatelessWidget {
  const MoneyHawkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoneyHawk',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(tradingModeProvider);
    final isPaper = mode == TradingMode.paper;
    return Scaffold(
      appBar: AppBar(title: const Text('MoneyHawk')),
      body: Column(
        children: [
          Container(
            key: const Key('mode-banner'),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: isPaper ? Colors.amber.shade200 : Colors.red.shade300,
            child: Text(
              isPaper ? 'PAPER MODE - simulated, no real orders' : 'LIVE MODE',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Expanded(child: Center(child: Text('Backend not connected'))),
        ],
      ),
    );
  }
}
