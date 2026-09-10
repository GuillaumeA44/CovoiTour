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
      const Member(id: 'small', name: 'Small', email: 'small@example.com', hasVehicle: true, passengerCapacity: 1),
      const Member(id: 'large', name: 'Large', email: 'large@example.com', hasVehicle: true, passengerCapacity: 2),
      const Member(id: 'passenger', name: 'Passenger', email: 'passenger@example.com'),
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
}
