class ParticipantLocation {
  const ParticipantLocation({required this.memberId, required this.latitude, required this.longitude, required this.updatedAt});

  final String memberId;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;
}

abstract interface class LocationService {
  Future<void> startSharing({required String tripId, required DateTime departure});
  Future<void> stopSharing(String tripId);
  Stream<ParticipantLocation> watchTrip(String tripId);
}

class UnconfiguredLocationService implements LocationService {
  @override
  Future<void> startSharing({required String tripId, required DateTime departure}) async {}

  @override
  Future<void> stopSharing(String tripId) async {}

  @override
  Stream<ParticipantLocation> watchTrip(String tripId) => const Stream.empty();
}
