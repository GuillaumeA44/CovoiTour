import '../entities/member.dart';
import '../entities/trip.dart';

class EquityResult {
  const EquityResult({required this.pointsByMemberId});

  final Map<String, int> pointsByMemberId;

  int get total => pointsByMemberId.values.fold(0, (sum, points) => sum + points);
}

class EquityService {
  EquityResult calculateTripPoints({
    required Trip trip,
    required String driverId,
  }) {
    final presentIds = trip.presentMemberIds;
    if (!presentIds.contains(driverId) || presentIds.length < 2) {
      throw ArgumentError('Un trajet doit avoir un conducteur et au moins un passager.');
    }

    final passengerCount = presentIds.length - 1;
    final points = <String, int>{
      for (final memberId in presentIds)
        memberId: memberId == driverId ? passengerCount : -1,
    };
    final result = EquityResult(pointsByMemberId: points);
    if (result.total != 0) {
      throw StateError('La somme des points doit rester egale a zero.');
    }
    return result;
  }

  String? recommendDriver({
    required Trip trip,
    required List<Member> members,
    required Map<String, int> scores,
    required DateTime Function(String memberId) lastDriveDate,
  }) {
    final presentIds = trip.presentMemberIds;
    final passengerCount = presentIds.length - 1;
    final candidates = members
        .where((member) =>
            presentIds.contains(member.id) &&
            member.canDrive(passengerCount: passengerCount))
        .toList();
    if (candidates.isEmpty) return null;

    candidates.sort((left, right) {
      final scoreComparison =
          (scores[left.id] ?? 0).compareTo(scores[right.id] ?? 0);
      if (scoreComparison != 0) return scoreComparison;
      return lastDriveDate(left.id).compareTo(lastDriveDate(right.id));
    });
    return candidates.first.id;
  }
}
