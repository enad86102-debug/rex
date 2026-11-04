/// Authenticated, private per-seat projection for candidate matches only.
/// This code parses real server data. It does not invent opponents, moves or wins.
class RexCard {
  const RexCard(this.suit, this.rank);

  factory RexCard.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('invalid card');
    }
    final suit = value['suit'];
    final rank = value['rank'];
    if (suit is! int || suit < 0 || suit > 3 ||
        rank is! int || rank < 2 || rank > 14) {
      throw const FormatException('invalid card rank or suit');
    }
    return RexCard(suit, rank);
  }

  final int suit;
  final int rank;

  static const suits = ['♣', '♦', '♥', '♠'];

  String get label {
    final face = switch (rank) {
      14 => 'A',
      13 => 'K',
      12 => 'Q',
      11 => 'J',
      _ => rank.toString(),
    };
    return '$face${suits[suit]}';
  }

  @override
  bool operator ==(Object other) =>
      other is RexCard && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => Object.hash(suit, rank);
}

class RexPlayedCard {
  const RexPlayedCard(this.seat, this.card);

  factory RexPlayedCard.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('invalid played card');
    }
    final seat = value['seat'];
    if (seat is! int || seat < 0 || seat > 3) {
      throw const FormatException('invalid play seat');
    }
    return RexPlayedCard(seat, RexCard.fromJson(value['card']));
  }

  final int seat;
  final RexCard card;
}

class RexCandidateMatchSnapshot {
  RexCandidateMatchSnapshot._({
    required this.matchId,
    required this.rulesVersion,
    required this.version,
    required this.seat,
    required this.owner,
    required this.turn,
    required this.kingdom,
    required this.phase,
    required this.contract,
    required this.completedDeals,
    required this.hand,
    required this.legalCards,
    required this.legalContracts,
    required this.canPass,
    required this.scores,
    required this.opponentCounts,
    required this.trick,
    required this.trixLow,
    required this.trixHigh,
  });

  static const phases = {
    'contract_selection',
    'complex_active',
    'trix_active',
    'deal_settlement',
    'match_complete',
  };
  static const hiddenKeys = {
    'checkpoint',
    'private_checkpoint',
    'initial_deck',
    'decks',
    'journal',
    'receipts',
    'opponent_hands',
    'members',
  };

  final String matchId;
  final String rulesVersion;
  final int version;
  final int seat;
  final int owner;
  final int turn;
  final int kingdom;
  final String phase;
  final String contract;
  final int completedDeals;
  final List<RexCard> hand;
  final List<RexCard> legalCards;
  final List<String> legalContracts;
  final bool canPass;
  final List<int> scores;
  final List<int> opponentCounts;
  final List<RexPlayedCard> trick;
  final List<int> trixLow;
  final List<int> trixHigh;

  bool get isMyTurn =>
      turn == seat && phase != 'deal_settlement' && phase != 'match_complete';

  bool isLegal(RexCard card) => isMyTurn && legalCards.contains(card);

  static int _integer(Map<String, dynamic> json, String field, int min, int max) {
    final value = json[field];
    if (value is! int || value < min || value > max) {
      throw FormatException('invalid $field');
    }
    return value;
  }

  static String _string(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is! String || value.isEmpty) {
      throw FormatException('invalid $field');
    }
    return value;
  }

  static List<int> _ints(Object? input, {int length = 4, int min = -1000000, int max = 1000000}) {
    if (input is! List || input.length != length) {
      throw const FormatException('invalid seat array');
    }
    final values = <int>[];
    for (final value in input) {
      if (value is! int || value < min || value > max) {
        throw const FormatException('invalid seat value');
      }
      values.add(value);
    }
    return List.unmodifiable(values);
  }

  static List<RexCard> _cards(Object? input) {
    if (input == null) return const [];
    if (input is! List || input.length > 13) {
      throw const FormatException('invalid card collection');
    }
    final cards = input.map(RexCard.fromJson).toList();
    if (cards.toSet().length != cards.length) {
      throw const FormatException('duplicate card');
    }
    return List.unmodifiable(cards);
  }

  factory RexCandidateMatchSnapshot.fromServer(Map<String, dynamic> response) {
    if (response.keys.any(hiddenKeys.contains)) {
      throw const FormatException('private material in response');
    }
    final rawView = response['view'];
    final rawLegal = response['legal_moves'];
    if (rawView is! Map<String, dynamic> ||
        rawLegal is! Map<String, dynamic> ||
        rawView.keys.any(hiddenKeys.contains)) {
      throw const FormatException('invalid private match view');
    }
    final matchId = _string(rawView, 'match_id');
    final rulesVersion = _string(rawView, 'rules_version');
    final version = _integer(rawView, 'version', 1, 1 << 62);
    final legalVersion = _integer(rawLegal, 'version', 1, 1 << 62);
    if (legalVersion != version) {
      throw const FormatException('stale legal moves');
    }
    final seat = _integer(rawView, 'seat', 0, 3);
    final owner = _integer(rawView, 'owner', 0, 3);
    final turn = _integer(rawView, 'turn', 0, 3);
    final kingdom = _integer(rawView, 'kingdom', 0, 3);
    final completed = _integer(rawView, 'completed_deals', 0, 8);
    final phase = _string(rawView, 'phase');
    if (!phases.contains(phase)) {
      throw const FormatException('unsupported match phase');
    }
    final contract = rawView['contract'];
    if (contract != null && contract != '' &&
        contract != 'complex' && contract != 'trix') {
      throw const FormatException('invalid contract');
    }
    final hand = _cards(rawView['hand']);
    final legal = _cards(rawLegal['cards']);
    if (legal.any((card) => !hand.contains(card))) {
      throw const FormatException('legal move is not in private hand');
    }
    final rawContracts = rawLegal['contracts'];
    if (rawContracts != null && rawContracts is! List) {
      throw const FormatException('invalid available contracts');
    }
    final contracts = <String>[];
    for (final value in (rawContracts as List?) ?? const []) {
      if (value != 'complex' && value != 'trix') {
        throw const FormatException('invalid selectable contract');
      }
      if (contracts.contains(value)) {
        throw const FormatException('duplicate selectable contract');
      }
      contracts.add(value as String);
    }
    final pass = rawLegal['can_pass'];
    if (pass is! bool || (pass && legal.isNotEmpty) ||
        (turn != seat && (pass || contracts.isNotEmpty || legal.isNotEmpty))) {
      throw const FormatException('invalid turn options');
    }
    final scores = _ints(rawView['scores']);
    final counts = _ints(rawView['opponent_counts'], min: 0, max: 13);
    final trickJson = rawView['trick'];
    if (trickJson is! Map<String, dynamic>) {
      throw const FormatException('invalid trick');
    }
    final rawPlays = trickJson['plays'];
    if (rawPlays != null && (rawPlays is! List || rawPlays.length > 4)) {
      throw const FormatException('invalid trick plays');
    }
    final plays = <RexPlayedCard>[];
    for (final play in (rawPlays as List?) ?? const []) {
      plays.add(RexPlayedCard.fromJson(play));
    }
    final layout = rawView['layout'];
    if (layout is! Map<String, dynamic>) {
      throw const FormatException('invalid trix layout');
    }
    return RexCandidateMatchSnapshot._(
      matchId: matchId,
      rulesVersion: rulesVersion,
      version: version,
      seat: seat,
      owner: owner,
      turn: turn,
      kingdom: kingdom,
      phase: phase,
      contract: contract is String ? contract : '',
      completedDeals: completed,
      hand: hand,
      legalCards: legal,
      legalContracts: List.unmodifiable(contracts),
      canPass: pass,
      scores: scores,
      opponentCounts: counts,
      trick: List.unmodifiable(plays),
      trixLow: _ints(layout['low'], min: 0, max: 14),
      trixHigh: _ints(layout['high'], min: 0, max: 14),
    );
  }
}
