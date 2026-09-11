import 'package:flutter_test/flutter_test.dart';
import 'package:covoi_tour/domain/entities/group.dart';
import 'package:covoi_tour/domain/entities/member.dart';
import 'package:covoi_tour/domain/entities/trip.dart';
import 'package:covoi_tour/data/serialization/carpool_json_codec.dart';

void main() {
  test('Bidirectional JSON Serialization test', () {
    final group = CarpoolGroup(
      id: 'g1',
      name: 'Test Group',
      description: 'Desc',
      startPoint: 'A',
      endPoint: 'B',
      outboundTime: '08:00',
      returnTime: '17:00',
      adminId: 'm1',
      members: [
        const Member(id: 'm1', firstName: 'Alice', lastName: '', email: 'alice@test.com', hasVehicle: true, passengerCapacity: 4),
        const Member(id: 'm2', firstName: 'Bob', lastName: '', email: 'bob@test.com', hasVehicle: false),
      ],
      trips: [
        Trip(
          id: 't1',
          date: DateTime(2026, 9, 10),
          participants: [
            const TripParticipant(memberId: 'm1', status: AttendanceStatus.present),
            const TripParticipant(memberId: 'm2', status: AttendanceStatus.present),
          ],
          suggestedDriverIds: ['m1'],
          confirmedDriverIds: ['m1'],
        )
      ],
      scoresByGroupSize: {
        2: {'m1': 1, 'm2': -1}
      },
    );

    final codec = CarpoolJsonCodec();
    final encoded = codec.encode(group);
    final decodedJson = codec.decode(encoded);
    final parsedGroup = CarpoolGroup.fromJson(decodedJson['document'] as Map<String, dynamic>);

    expect(parsedGroup.id, group.id);
    expect(parsedGroup.name, group.name);
    expect(parsedGroup.members.length, group.members.length);
    expect(parsedGroup.members.first.name, group.members.first.name);
    expect(parsedGroup.trips.length, group.trips.length);
    expect(parsedGroup.trips.first.presentMemberIds, ['m1', 'm2']);
    expect(parsedGroup.scoresByGroupSize[2]?['m1'], 1);
  });
}
