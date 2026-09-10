class GroupRules {
  const GroupRules({
    this.maxWaitingMinutes = 5,
    this.allowedLateArrivals = 3,
    this.latePenalty = 0,
  });

  final int maxWaitingMinutes;
  final int allowedLateArrivals;
  final int latePenalty;
}

class VehicleAssignment {
  const VehicleAssignment({required this.driverId, required this.passengerIds});

  final String driverId;
  final List<String> passengerIds;
}

class TripPlan {
  const TripPlan({required this.assignments, required this.unassignedPassengerIds});

  final List<VehicleAssignment> assignments;
  final List<String> unassignedPassengerIds;
}

class MemberStatistics {
  const MemberStatistics({required this.driverCount, required this.passengerCount, required this.score});

  final int driverCount;
  final int passengerCount;
  final int score;
}
