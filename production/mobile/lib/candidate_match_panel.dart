import 'package:flutter/material.dart';

import 'candidate_match_models.dart';

/// Internal candidate-game component driven exclusively by server snapshots.
/// Not linked from the public waiting room until approved match APIs exist.
class RexCandidateMatchPanel extends StatelessWidget {
  const RexCandidateMatchPanel({
    super.key,
    required this.snapshot,
    this.busy = false,
    this.onPlayCard,
    this.onChooseContract,
    this.onPass,
    this.onRefresh,
  });

  final RexCandidateMatchSnapshot snapshot;
  final bool busy;
  final ValueChanged<RexCard>? onPlayCard;
  final ValueChanged<String>? onChooseContract;
  final VoidCallback? onPass;
  final VoidCallback? onRefresh;

  static const seatNames = ['شمال', 'شرق', 'جنوب', 'غرب'];

  String _phaseName(String phase) => switch (phase) {
    'contract_selection' => 'اختيار العقد',
    'complex_active' => 'كومبلكس',
    'trix_active' => 'تركس',
    'deal_settlement' => 'نهاية التوزيعة',
    'match_complete' => 'انتهت المباراة',
    _ => 'حالة غير معروفة',
  };

  @override
  Widget build(BuildContext context) {
    final match = snapshot;
    final scheme = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'مباراة تريكس داخلية غير معتمدة للنشر',
            child: const Text(
              'اختبار داخلي — قواعد غير معتمدة',
              style: TextStyle(color: Color(0xffe2c47d)),
            ),
          ),
          const SizedBox(height: 12),
          Text(_phaseName(match.phase),
              style: Theme.of(context).textTheme.headlineSmall),
          Text('المملكة ${match.kingdom + 1} من 4 — التوزيعات المكتملة ${match.completedDeals} من 8'),
          Text(match.isMyTurn
              ? 'دورك الآن'
              : 'الدور الحالي: ${seatNames[match.turn]}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var seat = 0; seat < 4; seat++)
                Chip(
                  key: Key('score-$seat'),
                  label: Text(
                    '${seatNames[seat]}: ${match.scores[seat]}'
                    '${seat == match.seat ? ' (أنت)' : ''}',
                  ),
                ),
            ],
          ),
          if (match.phase == 'complex_active') ...[
            const SizedBox(height: 12),
            Text('اللمّة الحالية',
                style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 8,
              children: [
                for (final play in match.trick)
                  Chip(label: Text('${seatNames[play.seat]}: ${play.card.label}')),
              ],
            ),
          ],
          if (match.phase == 'trix_active') ...[
            const SizedBox(height: 12),
            Text('تسلسلات تركس',
                style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var suit = 0; suit < 4; suit++)
                  Chip(
                    label: Text(
                      '${RexCard.suits[suit]}: '
                      '${match.trixLow[suit] == 0 ? 'لم يبدأ' : '${match.trixLow[suit]}–${match.trixHigh[suit]}'}',
                    ),
                  ),
              ],
            ),
          ],
          if (match.phase == 'contract_selection' &&
              match.isMyTurn &&
              match.legalContracts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('اختر العقد', style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 8,
              children: [
                for (final contract in match.legalContracts)
                  FilledButton(
                    key: Key('contract-$contract'),
                    onPressed: busy || onChooseContract == null
                        ? null
                        : () => onChooseContract!(contract),
                    child: Text(contract == 'complex' ? 'كومبلكس' : 'تركس'),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text('أوراقك — ${match.hand.length}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final card in match.hand)
                OutlinedButton(
                  key: Key('rex-card-${card.suit}-${card.rank}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        card.suit == 1 || card.suit == 2 ? scheme.error : null,
                    minimumSize: const Size(56, 52),
                  ),
                  onPressed: busy || !match.isLegal(card) || onPlayCard == null
                      ? null
                      : () => onPlayCard!(card),
                  child: Text(card.label,
                      textDirection: TextDirection.ltr),
                ),
            ],
          ),
          if (match.canPass && match.isMyTurn) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('rex-pass'),
              onPressed: busy ? null : onPass,
              child: const Text('تمرير الدور'),
            ),
          ],
          if (match.phase == 'match_complete') ...[
            const SizedBox(height: 12),
            const Text('النتائج النهائية من الخادم. لم تُعتمد قاعدة كسر التعادل بعد.'),
          ],
          if (onRefresh != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              key: const Key('rex-refresh-match'),
              onPressed: busy ? null : onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث من الخادم'),
            ),
          ],
        ],
      ),
    );
  }
}
