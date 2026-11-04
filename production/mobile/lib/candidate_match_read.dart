import 'api.dart';
import 'candidate_match_models.dart';

/// Read-only candidate transport boundary. Mutating actions must go through
/// a separately reviewed secure, durable action-id controller.
class RexCandidateMatchRead {
  const RexCandidateMatchRead(this.transport);

  final RexTransport transport;

  Future<RexCandidateMatchSnapshot> fetch({
    required String tableId,
    required String bearer,
  }) async {
    if (!RegExp(r'^[0-9a-f]{32}$').hasMatch(tableId) ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(bearer)) {
      throw const ApiFailure('invalid_candidate_credentials');
    }
    final response = await transport.request(
      'GET',
      '/v1/tables/$tableId/match',
      token: bearer,
    );
    return RexCandidateMatchSnapshot.fromServer(response);
  }
}
