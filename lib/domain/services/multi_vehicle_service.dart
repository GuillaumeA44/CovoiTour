import '../entities/advanced_trip.dart';
import '../entities/member.dart';

class MultiVehicleService {
  TripPlan plan({
    required List<Member> drivers,
    required List<String> passengerIds,
    required Map<String, int> scores,
  }) {
    final availableDrivers = drivers
        .where((member) => member.isActive && member.hasVehicle && member.passengerCapacity > 0)
        .toList()
      ..sort((left, right) => (scores[left.id] ?? 0).compareTo(scores[right.id] ?? 0));
    final remaining = [...passengerIds];
    final assignments = <VehicleAssignment>[];

    for (final driver in availableDrivers) {
      if (remaining.isEmpty) break;
      final count = driver.passengerCapacity.clamp(0, remaining.length);
      final passengers = remaining.take(count).toList();
      remaining.removeRange(0, count);
      assignments.add(VehicleAssignment(driverId: driver.id, passengerIds: passengers));
    }
    return TripPlan(assignments: assignments, unassignedPassengerIds: remaining);
  }
}
