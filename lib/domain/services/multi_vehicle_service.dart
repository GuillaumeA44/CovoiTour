import '../entities/advanced_trip.dart';
import '../entities/member.dart';

class MultiVehicleService {
  TripPlan plan({
    required List<Member> drivers,
    required List<String> passengerIds,
    required Map<String, int> scores,
    Map<String, double>? finalScores,
    Map<String, double>? projectedDrivingRatios,
    double maxDrivingRatioGap = 0.10,
  }) {
    final presentIds = passengerIds.toSet();
    final hasPresentDriver = drivers.any((member) =>
      member.isActive &&
      member.hasVehicle &&
      member.passengerCapacity > 0 &&
      presentIds.contains(member.id));
    final availableDrivers = drivers
      .where((member) => member.isActive &&
        member.hasVehicle &&
        member.passengerCapacity > 0 &&
        (!hasPresentDriver || presentIds.contains(member.id)))
        .toList()
      ..sort((left, right) =>
          (finalScores?[left.id] ?? (scores[left.id] ?? 0).toDouble()).compareTo(
              finalScores?[right.id] ?? (scores[right.id] ?? 0).toDouble()));
    final includesDrivers = availableDrivers.any((driver) => presentIds.contains(driver.id));
    final requiredPassengerCount = includesDrivers ? presentIds.length : passengerIds.length;
    List<Member>? bestFairDrivers;
    List<Member>? bestFallbackDrivers;

    bool isFair(List<Member> selected) {
      if (projectedDrivingRatios == null || selected.isEmpty) return true;
      final ratios = selected
          .map((driver) => projectedDrivingRatios[driver.id] ?? 0.0)
          .toList();
      final highest = ratios.reduce((left, right) => left > right ? left : right);
      final lowest = ratios.reduce((left, right) => left < right ? left : right);
      return highest - lowest <= maxDrivingRatioGap;
    }

    bool isBetter(List<Member> candidate, List<Member>? current) {
      if (current == null) return true;
      if (projectedDrivingRatios != null) {
        final candidateRatios = _sortedProjectedRatios(candidate, projectedDrivingRatios);
        final currentRatios = _sortedProjectedRatios(current, projectedDrivingRatios);
        for (var index = 0; index < candidateRatios.length && index < currentRatios.length; index++) {
          final ratioComparison = candidateRatios[index].compareTo(currentRatios[index]);
          if (ratioComparison != 0) return ratioComparison < 0;
        }
      }
      if (candidate.length != current.length) return candidate.length < current.length;
      return _driverTotal(candidate, finalScores, scores) <
          _driverTotal(current, finalScores, scores);
    }

    void search(int start, List<Member> selected, int capacity) {
      final passengersToCarry = includesDrivers
          ? requiredPassengerCount - selected.length
          : requiredPassengerCount;
      if (capacity >= passengersToCarry) {
        if (isFair(selected) && isBetter(selected, bestFairDrivers)) {
          bestFairDrivers = List<Member>.from(selected);
        }
        if (isBetter(selected, bestFallbackDrivers)) {
          bestFallbackDrivers = List<Member>.from(selected);
        }
      }
      for (var index = start; index < availableDrivers.length; index++) {
        selected.add(availableDrivers[index]);
        search(index + 1, selected, capacity + availableDrivers[index].passengerCapacity);
        selected.removeLast();
      }
    }

    search(0, [], 0);
    final selectedDrivers = bestFairDrivers ?? bestFallbackDrivers ?? <Member>[];
    final remaining = includesDrivers
      ? presentIds.where((id) => !selectedDrivers.any((driver) => driver.id == id)).toList()
      : [...passengerIds];
    final assignments = <VehicleAssignment>[];

    for (final driver in selectedDrivers) {
      if (remaining.isEmpty) break;
      final count = driver.passengerCapacity.clamp(0, remaining.length);
      final passengers = remaining.take(count).toList();
      remaining.removeRange(0, count);
      assignments.add(VehicleAssignment(driverId: driver.id, passengerIds: passengers));
    }
    return TripPlan(assignments: assignments, unassignedPassengerIds: remaining);
  }

  double _driverTotal(List<Member> drivers, Map<String, double>? finalScores, Map<String, int> scores) =>
      drivers.fold(0.0, (total, driver) => total +
          (finalScores?[driver.id] ?? (scores[driver.id] ?? 0).toDouble()));

  List<double> _sortedProjectedRatios(
    List<Member> drivers,
    Map<String, double> projectedDrivingRatios,
  ) => [
    for (final ratio in drivers.map((driver) => projectedDrivingRatios[driver.id] ?? 0.0)) ratio,
  ]..sort((left, right) => right.compareTo(left));
}
