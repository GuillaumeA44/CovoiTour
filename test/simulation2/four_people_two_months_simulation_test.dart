import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:covoi_tour/domain/entities/member.dart';
import 'package:covoi_tour/domain/entities/trip.dart';
import 'package:covoi_tour/domain/services/equity_service.dart';
import 'package:covoi_tour/domain/services/multi_vehicle_service.dart';

void main() {
  test('simulation 4 personnes sur deux mois', () {
    final members = [
      const Member(id: 'alpha', firstName: 'Alpha', lastName: 'Temps Plein', email: 'alpha@example.com', hasVehicle: true, passengerCapacity: 3),
      const Member(id: 'beta', firstName: 'Beta', lastName: 'Temps Plein', email: 'beta@example.com', hasVehicle: true, passengerCapacity: 3),
      const Member(id: 'gamma', firstName: 'Gamma', lastName: 'Mardi Absent', email: 'gamma@example.com', hasVehicle: true, passengerCapacity: 3),
      const Member(id: 'delta', firstName: 'Delta', lastName: 'Jeudi Absent', email: 'delta@example.com', hasVehicle: true, passengerCapacity: 3),
    ];
    final equityService = EquityService();
    final vehicleService = MultiVehicleService();
    final history = <Trip>[];
    final driveCounts = {for (final member in members) member.id: 0};
    final presenceCounts = {for (final member in members) member.id: 0};
    final passengerCounts = {for (final member in members) member.id: 0};
    var coveredDays = 0;
    var unassignedPeople = 0;
    var dayNumber = 0;

    for (var date = DateTime(2026, 10, 1); date.isBefore(DateTime(2026, 12, 1)); date = date.add(const Duration(days: 1))) {
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) continue;
      dayNumber++;
      final presentIds = members
          .where((member) => _isPresent(member.id, date))
          .map((member) => member.id)
          .toList();
      for (final memberId in presentIds) {
        presenceCounts[memberId] = presenceCounts[memberId]! + 1;
      }
      if (presentIds.length < 2) continue;

      final trip = Trip(
        id: 'two-month-day-$dayNumber',
        date: date,
        participants: [
          for (final member in members)
            TripParticipant(
              memberId: member.id,
              status: presentIds.contains(member.id)
                  ? AttendanceStatus.present
                  : _absenceStatus(member.id, date),
            ),
        ],
      );
      final scores = equityService.calculatePriorityScores(
        trips: history,
        members: members,
        currentTrip: trip,
        minimumDrivingPresenceThreshold: 10,
      );
      final plan = vehicleService.plan(
        drivers: members,
        passengerIds: presentIds,
        scores: const {},
        finalScores: {
          for (final entry in scores.entries) entry.key: entry.value.finalScore,
        },
        projectedDrivingRatios: _projectedDrivingRatios(
          members: members,
          history: history,
          presentIds: presentIds,
        ),
        maxDrivingRatioGap: 0.10,
      );

      if (plan.assignments.isNotEmpty && plan.unassignedPassengerIds.isEmpty) coveredDays++;
      unassignedPeople += plan.unassignedPassengerIds.length;
      for (final assignment in plan.assignments) {
        driveCounts[assignment.driverId] = driveCounts[assignment.driverId]! + 1;
        passengerCounts[assignment.driverId] =
            passengerCounts[assignment.driverId]! + assignment.passengerIds.length;
      }
      history.add(trip.copyWith(
        confirmedDriverIds: plan.assignments.map((item) => item.driverId).toList(),
        passengerIdsByDriver: {
          for (final assignment in plan.assignments)
            assignment.driverId: List<String>.from(assignment.passengerIds),
        },
      ));
    }

    final finalScores = equityService.calculatePriorityScores(
      trips: history,
      members: members,
      minimumDrivingPresenceThreshold: 10,
    );
    final ratios = {
      for (final member in members)
        member.id: driveCounts[member.id]! / presenceCounts[member.id]!,
    };
    final ratioGap = ratios.values.reduce((left, right) => left > right ? left : right) -
        ratios.values.reduce((left, right) => left < right ? left : right);

    _writeReport(
      members: members,
      presenceCounts: presenceCounts,
      driveCounts: driveCounts,
      passengerCounts: passengerCounts,
      finalScores: finalScores,
      ratios: ratios,
      dayNumber: dayNumber,
      coveredDays: coveredDays,
      unassignedPeople: unassignedPeople,
      ratioGap: ratioGap,
    );

    expect(dayNumber, 43);
    expect(coveredDays, 43);
    expect(unassignedPeople, 0);
    expect(driveCounts.values.every((count) => count > 0), isTrue);
    expect(ratioGap, lessThanOrEqualTo(0.15));
    expect(finalScores.values.every((score) => score.finalScore.isFinite), isTrue);
  });

  test('le ratio utilise bien les jours de presence', () {
    const members = [
      Member(id: 'often', firstName: 'Souvent', lastName: 'Present', email: 'often@example.com', hasVehicle: true, passengerCapacity: 3),
      Member(id: 'rarely', firstName: 'Rarement', lastName: 'Present', email: 'rarely@example.com', hasVehicle: true, passengerCapacity: 3),
    ];
    final trips = [
      Trip(
        id: 'first',
        date: DateTime(2026, 10, 1),
        participants: const [
          TripParticipant(memberId: 'often', status: AttendanceStatus.present),
          TripParticipant(memberId: 'rarely', status: AttendanceStatus.present),
        ],
        confirmedDriverIds: const ['often'],
      ),
      for (var index = 0; index < 3; index++)
        Trip(
          id: 'often-$index',
          date: DateTime(2026, 10, 2 + index),
          participants: const [
            TripParticipant(memberId: 'often', status: AttendanceStatus.present),
          ],
        ),
    ];
    final scores = EquityService().calculatePriorityScores(
      trips: trips,
      members: members,
    );

    expect(scores['often']!.drivingRatio, 0.25);
    expect(scores['rarely']!.drivingRatio, 0.0);
  });
}

bool _isPresent(String memberId, DateTime date) {
  if (memberId == 'gamma' && date.weekday == DateTime.tuesday) return false;
  if (memberId == 'delta' && date.weekday == DateTime.thursday) return false;
  if (memberId == 'delta' && date.month == 11 && date.day <= 5) return false;
  return true;
}

AttendanceStatus _absenceStatus(String memberId, DateTime date) {
  if (memberId == 'gamma' && date.weekday == DateTime.tuesday) {
    return AttendanceStatus.telework;
  }
  if (memberId == 'delta') return AttendanceStatus.leave;
  return AttendanceStatus.absent;
}

Map<String, double> _projectedDrivingRatios({
  required List<Member> members,
  required List<Trip> history,
  required List<String> presentIds,
}) {
  return {
    for (final member in members)
      if (presentIds.contains(member.id))
        member.id: ((history.where((trip) => trip.confirmedDriverIds.contains(member.id)).length) + 1) /
            (history.where((trip) => trip.presentMemberIds.contains(member.id)).length + 1),
  };
}

void _writeReport({
  required List<Member> members,
  required Map<String, int> presenceCounts,
  required Map<String, int> driveCounts,
  required Map<String, int> passengerCounts,
  required Map<String, EquityScore> finalScores,
  required Map<String, double> ratios,
  required int dayNumber,
  required int coveredDays,
  required int unassignedPeople,
  required double ratioGap,
}) {
  const profiles = {
    'alpha': 'Présence 100 %, véhicule 3 places passager',
    'beta': 'Présence 100 %, véhicule 3 places passager',
    'gamma': 'Absent chaque mardi, véhicule 3 places passager',
    'delta': 'Absent chaque jeudi et début novembre, véhicule 3 places passager',
  };
  final lines = <String>[
    '# Bilan de simulation d’équité',
    '',
    '## Contexte',
    '',
    '- Période simulée : octobre et novembre 2026, $dayNumber jours ouvrés.',
    '- Groupe : 4 personnes, chacune possède un véhicule de 3 places passager.',
    '- Hypothèse métier : chaque personne présente et éligible doit conduire au moins une fois sur la période.',
    '- Personnes ayant effectivement conduit : ${driveCounts.values.where((count) => count > 0).length}/${members.length}.',
    '- Seuil de conduite minimale : 10 présences sans conduire.',
    '- Le coefficient individuel est calculé ainsi : `jours conduits / jours présents`.',
    '- La charge normalisée par conduite est calculée ainsi : `passagers transportés / (capacité × jours conduits)`.',
    '- Le score final est calculé ainsi : `score d’équité + (0,1 × score de contribution) − bonus de priorité`.',
    '- Le score d’équité compare directement le ratio de conduite individuel au ratio moyen du groupe.',
    '',
    '### Profils et contraintes',
    '',
    '| Personne | Profil |',
    '|---|---|',
    for (final member in members) '| ${member.name} | ${profiles[member.id] ?? 'Profil standard'} |',
    '',
    '## Résultats globaux',
    '',
    '- Jours entièrement couverts : $coveredDays/$dayNumber.',
    '- Personnes non affectées : $unassignedPeople.',
    '- Écart maximal du coefficient conduites / présences : ${ratioGap.toStringAsFixed(2)}.',
    '',
    '## Tableau récapitulatif individuel',
    '',
    '| Personne | Présences | Jours conduits | Jours conduits / jours présents (coût réel) | Capacité véhicule | Passagers transportés | Charge normalisée par conduite | Score final |',
    '|---|---:|---:|---:|---:|---:|---:|---:|',
  ];
  for (final member in members) {
    final drives = driveCounts[member.id]!;
    final passengers = passengerCounts[member.id]!;
    final normalizedLoad = drives == 0
        ? '0.00'
        : (passengers / (member.passengerCapacity * drives)).toStringAsFixed(2);
    final score = finalScores[member.id]!.finalScore.toStringAsFixed(2);
    lines.add('| ${member.name} | ${presenceCounts[member.id]} | $drives | $drives / ${presenceCounts[member.id]} = ${ratios[member.id]!.toStringAsFixed(2)} | ${member.passengerCapacity} | $passengers | $normalizedLoad | $score |');
  }
  lines.addAll([
    '',
    '## Lecture du bilan',
    '',
    '- Le coût réel individuel est affiché sous la forme `jours conduits / jours présents`.',
    '- La charge normalisée par conduite est `passagers transportés / (capacité × jours conduits)`.',
    '- Formule complète : `Score final = Score d’équité + (0,1 × Score de contribution) − Bonus de priorité`.',
    '- Les absences et les jours sans présence ne sont pas comptés dans le dénominateur.',
  ]);
  File('test/simulation2/four_people_two_months_simulation_report.md').writeAsStringSync('${lines.join('\n')}\n');
}
