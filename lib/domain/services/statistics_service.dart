import '../entities/advanced_trip.dart';
import '../entities/trip.dart';

class StatisticsService {
  Map<String, MemberStatistics> calculate({
    required List<Trip> trips,
    required Map<String, int> scores,
  }) {
    final result = <String, MemberStatistics>{};
    for (final trip in trips) {
      final driverId = trip.confirmedDriverId;
      for (final participant in trip.presentMemberIds) {
        final previous = result[participant] ?? const MemberStatistics(driverCount: 0, passengerCount: 0, score: 0);
        final isDriver = participant == driverId;
        result[participant] = MemberStatistics(
          driverCount: previous.driverCount + (isDriver ? 1 : 0),
          passengerCount: previous.passengerCount + (isDriver ? 0 : 1),
          score: scores[participant] ?? previous.score,
        );
      }
    }
    return result;
  }
}
