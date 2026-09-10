class Member {
  const Member({
    required this.id,
    required this.name,
    required this.email,
    this.hasVehicle = false,
    this.passengerCapacity = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String email;
  final bool hasVehicle;
  final int passengerCapacity;
  final bool isActive;

  bool canDrive({required int passengerCount}) =>
      isActive && hasVehicle && passengerCapacity >= passengerCount;
}
