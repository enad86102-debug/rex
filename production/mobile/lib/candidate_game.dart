import 'dart:async';

import 'package:flutter/material.dart';

import 'api.dart';
import 'controller.dart';

// Real server data only. No offline opponents or locally computed score.
class CandidateGameScreen extends StatefulWidget {
  const CandidateGameScreen({
    super.key,
    required this.controller,
    required this.roomId,
    required this.owner,
  });

  final RexController controller;
  final String roomId;
  final bool owner;

  @override
  State<CandidateGameScreen> createState() => _CandidateGameScreenState();
}

class _CandidateGameScreenState extends State<CandidateGameScreen> {
  Timer? _refreshTimer;
  Map<String, dynamic>? _state;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_refresh()),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading || !mounted || widget.controller.hasPendingAction) return;
    _loading = true;
    try {
      final latest = await widget.controller.candidateView(widget.roomId);
      if (mounted) {
        setState(() {
          _state = latest;
          _error = null;
        });
      }
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.code);
    } catch (_) {
      if (mounted) setState(() => _error = 'connection_failed');
    } finally {
      _loading = false;
    }
  }

  Future<void> _start() async {
    await widget.controller.candidateStart(widget.roomId);
    if (widget.controller.error != null) {
      if (mounted) setState(() => _error = widget.controller.error);
    } else {
      await _refresh();
    }
  }

  Future<void> _play(String type, Map<String, dynamic>? payload) async {
    final view = _state?['view'];
    if (view is! Map<String, dynamic>) return;
    final version = view['version'];
    if (version is! int || widget.controller.hasPendingAction) return;
    final action = <String, dynamic>{
      'expected_version': version,
      'type': type,
      ...?payload,
    };
    await widget.controller.candidateAction(widget.roomId, action);
    if (widget.controller.error != null) {
      if (mounted) setState(() => _error = widget.controller.error);
    }
    await _refresh();
  }

  Future<void> _retryPending() async {
    await widget.controller.retry();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تريكس كومبلكس — اختبار داخلي')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'قواعد مرشحة غير معتمدة — غير متاحة للإصدار العام',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(
                  'تعذّر جلب المباراة: $_error',
                  textAlign: TextAlign.center,
                ),
              if (widget.controller.hasPendingAction)
                FilledButton.tonal(
                  onPressed: widget.controller.busy ? null : _retryPending,
                  child: const Text('إعادة إرسال الحركة المعلّقة بأمان'),
                ),
              if (_state != null)
                CandidateGamePanel(
                  response: _state!,
                  busy: widget.controller.busy ||
                      widget.controller.hasPendingAction,
                  onAction: _play,
                )
              else ...[
                const Text(
                  'لا توجد مباراة متصلة حاليًا. يجب تجهيز أربعة لاعبين '
                  'والتحقق من اتصال الخادم الاختباري.',
                ),
                const SizedBox(height: 12),
                if (widget.owner)
                  FilledButton(
                    onPressed: widget.controller.busy ? null : _start,
                    child: const Text('بدء المباراة الداخلية الفعلية'),
                  ),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث حالة الخادم'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CandidateGamePanel extends StatelessWidget {
  const CandidateGamePanel({
    super.key,
    required this.response,
    required this.busy,
    required this.onAction,
  });

  final Map<String, dynamic> response;
  final bool busy;
  final Future<void> Function(String, Map<String, dynamic>?) onAction;

  static const suits = ['♣', '♦', '♥', '♠'];
  static const ranks = {
    11: 'J',
    12: 'Q',
    13: 'K',
    14: 'A',
  };

  String cardName(Map<dynamic, dynamic> card) {
    final suit = card['suit'];
    final rank = card['rank'];
    if (suit is! int || suit < 0 || suit > 3 || rank is! int) {
      return '؟';
    }
    return '${ranks[rank] ?? rank}${suits[suit]}';
  }

  @override
  Widget build(BuildContext context) {
    final view = response['view'];
    final legal = response['legal_moves'];
    if (view is! Map<String, dynamic> ||
        legal is! Map<String, dynamic>) {
      return const Text('بيانات المباراة غير مكتملة.');
    }
    final seat = view['seat'];
    final turn = view['turn'];
    final phase = view['phase'] as String? ?? '';
    final hand = (view['hand'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .toList();
    final cards = (legal['cards'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .toList();
    final legalSet = cards
        .map((card) => '${card['suit']}:${card['rank']}')
        .toSet();
    final choices = legal['contracts'] as List<dynamic>? ?? [];
    final scores = view['scores'] as List<dynamic>? ?? [];
    final active = seat == turn && !busy;
    final trick = view['trick'] as Map<dynamic, dynamic>? ?? {};
    final plays = (trick['plays'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .toList();
    final layout = view['layout'] as Map<dynamic, dynamic>? ?? {};
    final low = layout['low'] as List<dynamic>? ?? [];
    final high = layout['high'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'المملكة ${(view['kingdom'] as int? ?? 0) + 1} • '
          'التوزيعات المنتهية: ${view['completed_deals'] ?? 0}/8',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text('العقد: ${phase == 'contract_selection' ? 'اختيار العقد' : (view['contract'] ?? phase)}'),
        Text('دور المقعد: ${turn is int ? turn + 1 : '?'}'),
        const SizedBox(height: 12),
        Text(
          'النقاط المؤكدة من الخادم',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Wrap(
          spacing: 12,
          children: [
            for (var i = 0; i < scores.length; i++)
              Chip(label: Text('مقعد ${i + 1}: ${scores[i]}')),
          ],
        ),
        if (plays.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('الأوراق الموضوعة في اللمّة'),
          Wrap(
            spacing: 8,
            children: [
              for (final play in plays)
                Chip(
                  label: Text(
                    'مقعد ${(play['seat'] as int? ?? 0) + 1}: '
                    '${cardName(play['card'] as Map)}',
                  ),
                ),
            ],
          ),
        ],
        if (phase == 'trix_active' && low.length == 4 && high.length == 4) ...[
          const SizedBox(height: 12),
          const Text('تسلسلات تركس العلنية'),
          for (var i = 0; i < 4; i++)
            Text('${suits[i]}: ${low[i]} — ${high[i]}'),
        ],
        if (choices.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final choice in choices)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: FilledButton(
                onPressed: !active
                    ? null
                    : () => onAction('choose_contract', {
                          'contract': choice as String,
                        }),
                child: Text('اختيار عقد ${choice == 'complex' ? 'كومبلكس' : 'تركس'}'),
              ),
            ),
        ],
        const SizedBox(height: 16),
        Text(
          'أوراقك الحقيقية (${hand.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final card in hand)
              OutlinedButton(
                onPressed: active &&
                        legalSet.contains('${card['suit']}:${card['rank']}')
                    ? () => onAction('play_card', {
                          'card': {
                            'suit': card['suit'],
                            'rank': card['rank'],
                          },
                        })
                    : null,
                child: Text(cardName(card)),
              ),
          ],
        ),
        if (legal['can_pass'] == true) ...[
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: active ? () => onAction('pass', null) : null,
            child: const Text('تمرير — لا توجد ورقة قانونية'),
          ),
        ],
        if (phase == 'match_complete')
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'اكتملت المباراة؛ النتيجة المعروضة صادرة عن الخادم.',
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
