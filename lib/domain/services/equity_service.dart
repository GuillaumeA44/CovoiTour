import '../entities/member.dart';
import '../entities/trip.dart';

class EquityScore {
  const EquityScore({
    required this.equity,
    required this.contribution,
    required this.presencesSinceLastDrive,
    required this.priority,
    required this.drivingRatio,
  });

  final double equity;
  final double contribution;
  final int presencesSinceLastDrive;
  final double priority;
  final double drivingRatio;

  double get finalScore => equity + (0.1 * contribution) - priority;
}

class EquityResult {
  const EquityResult({required this.pointsByMemberId});

  final Map<String, int> pointsByMemberId;

  int get total => pointsByMemberId.values.fold(0, (sum, points) => sum + points);
}

class EquityService {
  Map<String, EquityScore> calculatePriorityScores({
    required List<Trip> trips,
    required List<Member> members,
    Trip? currentTrip,
    int minimumDrivingPresenceThreshold = 10,
  }) {
    final allTrips = [...trips];
    if (currentTrip != null && !allTrips.any((trip) => trip.id == currentTrip.id)) {
      allTrips.add(currentTrip);
    }
    allTrips.sort((left, right) => left.date.compareTo(right.date));

    final presenceCounts = <String, int>{};
    final driveCounts = <String, int>{};
    final contributions = <String, int>{};
    final presencesSinceDrive = <String, int>{};
    for (final member in members) {
      presenceCounts[member.id] = 0;
      driveCounts[member.id] = 0;
      contributions[member.id] = 0;
      presencesSinceDrive[member.id] = 0;
    }

    for (final trip in allTrips) {
      final presentIds = trip.presentMemberIds.toSet();
      for (final memberId in presentIds) {
        if (presenceCounts.containsKey(memberId)) {
          presenceCounts[memberId] = presenceCounts[memberId]! + 1;
          presencesSinceDrive[memberId] = presencesSinceDrive[memberId]! + 1;
        }
      }
      for (final driverId in trip.confirmedDriverIds) {
        if (driveCounts.containsKey(driverId)) {
          driveCounts[driverId] = driveCounts[driverId]! + 1;
          presencesSinceDrive[driverId] = 0;
        }
        final transportedPassengers = trip.passengerIdsByDriver[driverId]?.length ??
          (presentIds.length - trip.confirmedDriverIds.length).clamp(0, presentIds.length);
        contributions[driverId] = (contributions[driverId] ?? 0) + transportedPassengers;
      }
    }

    final totalPresences = presenceCounts.values.fold(0, (sum, count) => sum + count);
    final totalDrives = driveCounts.values.fold(0, (sum, count) => sum + count);
    final groupDrivingRatio = totalPresences == 0 ? 0.0 : totalDrives / totalPresences;
    final averageContribution = members.isEmpty
        ? 0.0
        : contributions.values.fold(0, (sum, value) => sum + value) / members.length;
    return {
      for (final member in members)
        member.id: EquityScore(
          equity: (presenceCounts[member.id] == 0
              ? 0.0
              : driveCounts[member.id]! / presenceCounts[member.id]!) -
            groupDrivingRatio,
          contribution: contributions[member.id]! - averageContribution,
          presencesSinceLastDrive: presencesSinceDrive[member.id]!,
          priority: minimumDrivingPresenceThreshold <= 0
              ? 0
              : presencesSinceDrive[member.id]! / minimumDrivingPresenceThreshold,
            drivingRatio: presenceCounts[member.id] == 0
              ? 0.0
              : driveCounts[member.id]! / presenceCounts[member.id]!,
        ),
    };
  }

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
    List<Trip> history = const [],
    int minimumDrivingPresenceThreshold = 10,
  }) {
    final presentIds = trip.presentMemberIds;
    final passengerCount = presentIds.length - 1;
    final candidates = members
        .where((member) =>
            presentIds.contains(member.id) &&
            member.canDrive(passengerCount: passengerCount))
        .toList();
    if (candidates.isEmpty) return null;

    final priorityScores = calculatePriorityScores(
      trips: history,
      members: members,
      currentTrip: trip,
      minimumDrivingPresenceThreshold: minimumDrivingPresenceThreshold,
    );
    candidates.sort((left, right) {
      final leftScore = priorityScores[left.id]?.finalScore ?? (scores[left.id] ?? 0).toDouble();
      final rightScore = priorityScores[right.id]?.finalScore ?? (scores[right.id] ?? 0).toDouble();
      final scoreComparison = leftScore.compareTo(rightScore);
      if (scoreComparison != 0) return scoreComparison;
      return lastDriveDate(left.id).compareTo(lastDriveDate(right.id));
    });
    return candidates.first.id;
  }
}
