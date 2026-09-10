import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/group.dart';
import '../../domain/entities/member.dart';
import '../../domain/entities/trip.dart';
import '../../domain/services/equity_service.dart';

class AppState extends ChangeNotifier {
  AppState() : group = _initialGroup();

  final CarpoolGroup group;
  final EquityService equityService = EquityService();

  List<Member> get activeMembers =>
      group.members.where((member) => member.isActive).toList(growable: false);

  Map<String, int> scoresFor(int participantCount) =>
      group.scoresByGroupSize.putIfAbsent(participantCount, () => <String, int>{});

  void addMember({
    required String name,
    required String email,
    required bool hasVehicle,
    required int passengerCapacity,
  }) {
    final id = 'member-${group.members.length + 1}';
    group.members.add(Member(
      id: id,
      name: name,
      email: email,
      hasVehicle: hasVehicle,
      passengerCapacity: passengerCapacity,
    ));
    notifyListeners();
  }

  void setAttendance(String memberId, AttendanceStatus status) {
    final trip = _nextTrip();
    final index = trip.participants.indexWhere((item) => item.memberId == memberId);
    if (index < 0) return;
    trip.participants[index] = TripParticipant(memberId: memberId, status: status);
    notifyListeners();
  }

  String? recommendDriver() {
    final trip = _nextTrip();
    final scores = scoresFor(trip.presentMemberIds.length);
    return equityService.recommendDriver(
      trip: trip,
      members: activeMembers,
      scores: scores,
      lastDriveDate: (memberId) => _lastDriveDate(memberId),
    );
  }

  void confirmDriver(String memberId) {
    final trip = _nextTrip();
    final presentCount = trip.presentMemberIds.length;
    if (presentCount < 2) return;
    final result = equityService.calculateTripPoints(trip: trip, driverId: memberId);
    final scores = scoresFor(presentCount);
    result.pointsByMemberId.forEach((id, points) {
      scores[id] = (scores[id] ?? 0) + points;
    });
    group.trips[group.trips.indexOf(trip)] = Trip(
      id: trip.id,
      date: trip.date,
      participants: trip.participants,
      suggestedDriverId: trip.suggestedDriverId,
      confirmedDriverId: memberId,
    );
    notifyListeners();
  }

  Trip _nextTrip() => group.trips.first;

  DateTime _lastDriveDate(String memberId) {
    for (final trip in group.trips.reversed) {
      if (trip.confirmedDriverId == memberId) return trip.date;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static CarpoolGroup _initialGroup() {
    final members = <Member>[
      const Member(
        id: 'member-1',
        name: 'Alice Martin',
        email: 'alice@example.com',
        hasVehicle: true,
        passengerCapacity: 3,
      ),
      const Member(
        id: 'member-2',
        name: 'Benoit Durand',
        email: 'benoit@example.com',
        hasVehicle: true,
        passengerCapacity: 4,
      ),
      const Member(
        id: 'member-3',
        name: 'Chloe Bernard',
        email: 'chloe@example.com',
      ),
    ];
    return CarpoolGroup(
      id: 'group-1',
      name: 'Trajet bureau',
      description: 'Covoiturage quotidien vers le bureau.',
      startPoint: 'Maison',
      endPoint: 'Bureau',
      outboundTime: '08:00',
      returnTime: '18:00',
      adminId: 'member-1',
      members: members,
      trips: [
        Trip(
          id: 'trip-next',
          date: DateTime(2026, 9, 14),
          participants: [
            const TripParticipant(memberId: 'member-1', status: AttendanceStatus.present),
            const TripParticipant(memberId: 'member-2', status: AttendanceStatus.present),
            const TripParticipant(memberId: 'member-3', status: AttendanceStatus.notAnswered),
          ],
        ),
      ],
      scoresByGroupSize: {
        2: {'member-1': 0, 'member-2': 0},
        3: {'member-1': 0, 'member-2': 0, 'member-3': 0},
      },
    );
  }
}

final appStateProvider = ChangeNotifierProvider<AppState>((ref) => AppState());
