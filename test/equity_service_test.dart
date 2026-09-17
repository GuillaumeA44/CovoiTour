import 'package:flutter_test/flutter_test.dart';
import 'package:covoi_tour/domain/entities/member.dart';
import 'package:covoi_tour/domain/entities/trip.dart';
import 'package:covoi_tour/domain/services/equity_service.dart';

void main() {
  final service = EquityService();

  test('attribue +N au conducteur et -1 aux passagers', () {
    final trip = Trip(
      id: 'trip-1',
      date: DateTime(2026, 9, 10),
      participants: const [
        TripParticipant(memberId: 'driver', status: AttendanceStatus.present),
        TripParticipant(memberId: 'passenger-1', status: AttendanceStatus.present),
        TripParticipant(memberId: 'passenger-2', status: AttendanceStatus.present),
        TripParticipant(memberId: 'absent', status: AttendanceStatus.absent),
      ],
    );

    final result = service.calculateTripPoints(trip: trip, driverId: 'driver');

    expect(result.pointsByMemberId, {'driver': 2, 'passenger-1': -1, 'passenger-2': -1});
    expect(result.total, 0);
  });

  test('ne recommande pas un conducteur dont la capacite est insuffisante', () {
    final trip = Trip(
      id: 'trip-1',
      date: DateTime(2026, 9, 10),
      participants: const [
        TripParticipant(memberId: 'small', status: AttendanceStatus.present),
        TripParticipant(memberId: 'large', status: AttendanceStatus.present),
        TripParticipant(memberId: 'passenger', status: AttendanceStatus.present),
      ],
    );
    final members = [
      const Member(id: 'small', firstName: 'Small', lastName: '', email: 'small@example.com', hasVehicle: true, passengerCapacity: 1),
      const Member(id: 'large', firstName: 'Large', lastName: '', email: 'large@example.com', hasVehicle: true, passengerCapacity: 2),
      const Member(id: 'passenger', firstName: 'Passenger', lastName: '', email: 'passenger@example.com'),
    ];

    expect(
      service.recommendDriver(
        trip: trip,
        members: members,
        scores: const {'small': -3, 'large': 2},
        lastDriveDate: (_) => DateTime(2026, 1, 1),
      ),
      'large',
    );
  });

  test('calcule equite, contribution et bonus de priorite', () {
    final members = [
      const Member(id: 'a', firstName: 'A', lastName: '', email: 'a@example.com', hasVehicle: true, passengerCapacity: 2),
      const Member(id: 'f', firstName: 'F', lastName: '', email: 'f@example.com', hasVehicle: true, passengerCapacity: 2),
    ];
    final trips = [
      Trip(
        id: 'old-1',
        date: DateTime(2026, 9, 1),
        participants: const [
          TripParticipant(memberId: 'a', status: AttendanceStatus.present),
          TripParticipant(memberId: 'f', status: AttendanceStatus.present),
        ],
        confirmedDriverIds: const ['a'],
      ),
      Trip(
        id: 'old-2',
        date: DateTime(2026, 9, 2),
        participants: const [
          TripParticipant(memberId: 'a', status: AttendanceStatus.present),
          TripParticipant(memberId: 'f', status: AttendanceStatus.present),
        ],
      ),
    ];

    final scores = service.calculatePriorityScores(
      trips: trips,
      members: members,
      minimumDrivingPresenceThreshold: 10,
    );

    expect(scores['a']!.equity, closeTo(0.25, 0.001));
    expect(scores['a']!.contribution, closeTo(0.5, 0.001));
    expect(scores['f']!.presencesSinceLastDrive, 2);
    expect(scores['f']!.priority, closeTo(0.2, 0.001));
    expect(scores['f']!.finalScore, lessThan(scores['a']!.finalScore));
    expect(scores['a']!.drivingRatio, closeTo(0.5, 0.001));
  });
}
