import 'package:flutter_test/flutter_test.dart';
import 'package:covoi_tour/data/serialization/carpool_json_codec.dart';
import 'package:covoi_tour/domain/entities/group.dart';
import 'package:covoi_tour/domain/entities/member.dart';
import 'package:covoi_tour/domain/services/multi_vehicle_service.dart';

void main() {
  test('repartit les passagers dans plusieurs vehicules', () {
    final plan = MultiVehicleService().plan(
      drivers: const [
        Member(id: 'a', firstName: 'A', lastName: '', email: 'a@x.fr', hasVehicle: true, passengerCapacity: 4),
        Member(id: 'b', firstName: 'B', lastName: '', email: 'b@x.fr', hasVehicle: true, passengerCapacity: 4),
        Member(id: 'c', firstName: 'C', lastName: '', email: 'c@x.fr', hasVehicle: true, passengerCapacity: 2),
      ],
      passengerIds: const ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8', 'p9'],
      scores: const {'a': 2, 'b': 0, 'c': -1},
    );

    expect(plan.assignments.map((assignment) => assignment.driverId), ['c', 'b', 'a']);
    expect(plan.unassignedPassengerIds, isEmpty);
  });

  test('exporte un document JSON versionne', () {
    final group = CarpoolGroup(
      id: 'g1',
      name: 'Test',
      description: '',
      startPoint: 'A',
      endPoint: 'B',
      outboundTime: '08:00',
      returnTime: '18:00',
      adminId: 'm1',
      members: const [],
      trips: const [],
      scoresByGroupSize: const {},
    );

    final json = CarpoolJsonCodec().encode(group);
    final decoded = CarpoolJsonCodec().decode(json);
    expect(decoded['schemaVersion'], 1);
    expect((decoded['document'] as Map<String, dynamic>)['name'], 'Test');
  });
}
