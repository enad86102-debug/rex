import 'package:flutter/material.dart';

import 'widgets/rex_hand.dart';
import 'widgets/rex_table.dart';

class Pbt08Screen extends StatefulWidget {
  const Pbt08Screen({
    super.key,
    this.showPerformanceOverlay = false,
    this.onTogglePerformanceOverlay,
  });

  final bool showPerformanceOverlay;
  final VoidCallback? onTogglePerformanceOverlay;

  @override
  State<Pbt08Screen> createState() => _Pbt08ScreenState();
}

class _Pbt08ScreenState extends State<Pbt08Screen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _deal;
  int _completedDeals = 0;

  @override
  void initState() {
    super.initState();
    _deal = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener(_onDealStatus);
  }

  void _onDealStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) setState(() => _completedDeals++);
  }

  void _startDeal() {
    if (_deal.isAnimating) return;
    setState(() {
      _deal.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _deal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tableHeight = (constraints.maxHeight - 310).clamp(
              220.0,
              440.0,
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'REX',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 6,
                              color: Color(0xFFE4B976),
                            ),
                          ),
                          const Spacer(),
                          if (widget.onTogglePerformanceOverlay != null)
                            IconButton(
                              key: const ValueKey('performance-overlay-toggle'),
                              tooltip: 'Flutter performance overlay (debug)',
                              onPressed: widget.onTogglePerformanceOverlay,
                              isSelected: widget.showPerformanceOverlay,
                              icon: const Icon(Icons.speed_outlined),
                              selectedIcon: const Icon(Icons.speed),
                            ),
                        ],
                      ),
                      const Text(
                        'PBT08 • Flutter Device Spike',
                        style: TextStyle(color: Color(0xFFBBCBC9)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'مشهد تجريبي • محاكاة بصرية فقط',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8EA6A5),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: tableHeight,
                        child: RexTable(animation: _deal),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'يد اللاعب المحلي • 13 بطاقة تجريبية',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFBBCBC9),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const RexHand(key: ValueKey('local-hand')),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        key: const ValueKey('deal-test-button'),
                        onPressed: _deal.isAnimating ? null : _startDeal,
                        icon: const Icon(Icons.style_outlined),
                        label: const Text(
                          'اختبار التوزيع',
                          textDirection: TextDirection.rtl,
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _deal.isAnimating
                            ? 'جارٍ عرض حركة البطاقات…'
                            : _completedDeals == 0
                            ? 'جاهز لاختبار الرسم'
                            : 'اكتملت تجربة التوزيع $_completedDeals',
                        key: const ValueKey('deal-status'),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8EA6A5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
