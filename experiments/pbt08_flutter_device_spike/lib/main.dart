import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'pbt08/pbt08_screen.dart';

void main() => runApp(const RexSpikeApp());

class RexSpikeApp extends StatefulWidget {
  const RexSpikeApp({super.key});

  @override
  State<RexSpikeApp> createState() => _RexSpikeAppState();
}

class _RexSpikeAppState extends State<RexSpikeApp> {
  bool _showPerformanceOverlay = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REX · PBT08',
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: kDebugMode && _showPerformanceOverlay,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE4B976),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101C20),
        useMaterial3: true,
      ),
      home: Pbt08Screen(
        showPerformanceOverlay: _showPerformanceOverlay,
        onTogglePerformanceOverlay: kDebugMode
            ? () => setState(
                () => _showPerformanceOverlay = !_showPerformanceOverlay,
              )
            : null,
      ),
    );
  }
}
