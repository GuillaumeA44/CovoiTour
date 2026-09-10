abstract interface class NotificationService {
  Future<void> schedulePresenceReminder({required String tripId, required DateTime deadline});
  Future<void> scheduleTripReminder({required String tripId, required DateTime departure});
  Future<void> cancelReminder(String tripId);
}

class UnconfiguredNotificationService implements NotificationService {
  @override
  Future<void> schedulePresenceReminder({required String tripId, required DateTime deadline}) async {}

  @override
  Future<void> scheduleTripReminder({required String tripId, required DateTime departure}) async {}

  @override
  Future<void> cancelReminder(String tripId) async {}
}
