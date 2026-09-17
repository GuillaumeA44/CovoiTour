import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:covoi_tour/domain/entities/member.dart';
import 'package:covoi_tour/domain/entities/trip.dart';
import 'package:covoi_tour/domain/services/equity_service.dart';
import 'package:covoi_tour/domain/services/multi_vehicle_service.dart';

void main() {
  test('simulation 4: 13 personnes et dimensionnement des voitures sur trois mois', () {
    final members = [
      ..._members('full-a', 'Temps Plein A', 4),
      ..._members('full-b', 'Temps Plein B', 4),
      ..._members('full-c', 'Temps Plein C', 4),
      ..._members('full-d', 'Temps Plein D', 4),
      ..._members('holiday', 'Vacances Novembre', 4),
      ..._members('four-days-a', 'Quatre Jours A', 4),
      ..._members('four-days-b', 'Quatre Jours B', 4),
      ..._members('half-a', 'Mi Temps A', 4),
      ..._members('half-b', 'Mi Temps B', 4),
      ..._members('remote-a', 'Teletravail A', 4),
      ..._members('remote-b', 'Teletravail B', 4),
      ..._members('new-member', 'Nouveau Membre', 4),
      ..._members('late-member', 'Arrivee Decembre', 4),
    ];
    final equityService = EquityService();
    final vehicleService = MultiVehicleService();
    final history = <Trip>[];
    final driveCounts = {for (final member in members) member.id: 0};
    final presenceCounts = {for (final member in members) member.id: 0};
    final passengerCounts = {for (final member in members) member.id: 0};
    var coveredDays = 0;
    var singleParticipantDays = 0;
    var unassignedPeople = 0;
    var maximumVehiclesUsed = 0;
    var dayNumber = 0;

    for (var date = DateTime(2026, 10, 1); date.isBefore(DateTime(2027, 1, 1)); date = date.add(const Duration(days: 1))) {
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) continue;
      dayNumber++;
      final presentIds = members
          .where((member) => _isPresent(member.id, date))
          .map((member) => member.id)
          .toList();
      for (final memberId in presentIds) {
        presenceCounts[memberId] = presenceCounts[memberId]! + 1;
      }
      if (presentIds.length < 2) {
        singleParticipantDays++;
        continue;
      }

      final trip = Trip(
        id: 'simulation4-day-$dayNumber',
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

      maximumVehiclesUsed = plan.assignments.length > maximumVehiclesUsed
          ? plan.assignments.length
          : maximumVehiclesUsed;
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
        member.id: presenceCounts[member.id] == 0
            ? 0.0
            : driveCounts[member.id]! / presenceCounts[member.id]!,
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
      singleParticipantDays: singleParticipantDays,
      unassignedPeople: unassignedPeople,
      maximumVehiclesUsed: maximumVehiclesUsed,
      ratioGap: ratioGap,
    );

    expect(dayNumber, 66);
    expect(coveredDays, 66);
    expect(singleParticipantDays, 0);
    expect(unassignedPeople, 0);
    expect(driveCounts.values.every((count) => count > 0), isTrue);
    expect(ratioGap, lessThanOrEqualTo(0.20));
    expect(finalScores.values.every((score) => score.finalScore.isFinite), isTrue);
  });
}

List<Member> _members(String id, String name, int capacity) => [
  Member(
    id: id,
    firstName: name,
    lastName: '',
    email: '$id@example.com',
    hasVehicle: true,
    passengerCapacity: capacity,
  ),
];

bool _isPresent(String memberId, DateTime date) {
  if (memberId == 'holiday' && date.month == 11) return false;
  if ((memberId == 'four-days-a' || memberId == 'four-days-b') &&
      date.weekday == DateTime.friday) return false;
  if ((memberId == 'half-a' || memberId == 'half-b') &&
      date.weekday != DateTime.monday &&
      date.weekday != DateTime.wednesday &&
      date.weekday != DateTime.friday) {
    return false;
  }
  if ((memberId == 'remote-a' || memberId == 'remote-b') &&
      date.weekday == DateTime.wednesday) return false;
  if (memberId == 'new-member' && date.isBefore(DateTime(2026, 11, 16))) return false;
  if (memberId == 'late-member' && date.isBefore(DateTime(2026, 12, 1))) return false;
  return true;
}

AttendanceStatus _absenceStatus(String memberId, DateTime date) {
  if (memberId == 'holiday' && date.month == 11) return AttendanceStatus.leave;
  if (memberId == 'remote-a' || memberId == 'remote-b') return AttendanceStatus.telework;
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
  required int singleParticipantDays,
  required int unassignedPeople,
  required int maximumVehiclesUsed,
  required double ratioGap,
}) {
  const profiles = {
    'full-a': 'Temps plein, véhicule 4 places passager',
    'full-b': 'Temps plein, véhicule 4 places passager',
    'full-c': 'Temps plein, véhicule 4 places passager',
    'full-d': 'Temps plein, véhicule 4 places passager',
    'holiday': 'Vacances pendant tout le mois de novembre, véhicule 4 places passager',
    'four-days-a': 'Présence 4 jours sur 5, véhicule 4 places passager',
    'four-days-b': 'Présence 4 jours sur 5, véhicule 4 places passager',
    'half-a': 'Présence lundi, mercredi et vendredi, véhicule 4 places passager',
    'half-b': 'Présence lundi, mercredi et vendredi, véhicule 4 places passager',
    'remote-a': 'Télétravail chaque mercredi, véhicule 4 places passager',
    'remote-b': 'Télétravail chaque mercredi, véhicule 4 places passager',
    'new-member': 'Arrivée le 16 novembre, véhicule 4 places passager',
    'late-member': 'Arrivée le 1er décembre, véhicule 4 places passager',
  };
  final lines = <String>[
    '# Bilan de simulation d’équité',
    '',
    '## Contexte',
    '',
    '- Période simulée : octobre à décembre 2026, $dayNumber jours ouvrés.',
    '- Groupe : 13 personnes, chacune possède un véhicule de 4 places passager.',
    '- Le nombre de voitures est déterminé par le nombre de personnes présentes et la capacité des véhicules.',
    '- Hypothèse métier : chaque personne présente et éligible doit conduire au moins une fois sur la période.',
    '- Personnes ayant effectivement conduit : ${driveCounts.values.where((count) => count > 0).length}/${members.length}.',
    '- Le coefficient individuel est calculé ainsi : `jours conduits / jours présents`.',
    '- La charge normalisée par conduite est calculée ainsi : `passagers transportés / (capacité × jours conduits)`.',
    '- Le score final est calculé ainsi : `score d’équité + (0,1 × score de contribution) − bonus de priorité`.',
    '- Le score d’équité compare directement le ratio de conduite individuel au ratio moyen du groupe.',
    '',
    '### Profils et contraintes',
    '',
    '| Personne | Profil |',
    '|---|---|',
    for (final member in members) '| ${member.name} | ${profiles[member.id]} |',
    '',
    '## Résultats globaux',
    '',
    '- Jours avec au moins deux participants et entièrement couverts : $coveredDays/$dayNumber.',
    '- Jours avec une seule personne présente : $singleParticipantDays.',
    '- Personnes non affectées : $unassignedPeople.',
    '- Nombre maximal de voitures utilisées simultanément dans ce scénario : $maximumVehiclesUsed.',
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
    lines.add('| ${member.name} | ${presenceCounts[member.id]} | $drives | $drives / ${presenceCounts[member.id]} = ${ratios[member.id]!.toStringAsFixed(2)} | ${member.passengerCapacity} | $passengers | $normalizedLoad | ${finalScores[member.id]!.finalScore.toStringAsFixed(2)} |');
  }
  lines.addAll([
    '',
    '## Lecture du bilan',
    '',
    '- Le coût réel individuel est affiché sous la forme `jours conduits / jours présents`.',
    '- La charge normalisée par conduite est `passagers transportés / (capacité × jours conduits)`.',
    '- Formule complète : `Score final = Score d’équité + (0,1 × Score de contribution) − Bonus de priorité`.',
    '- Les vacances, absences, télétravail et jours sans présence ne sont pas comptés dans le dénominateur.',
  ]);
  File('test/simulation4/thirteen_people_three_months_simulation_report.md').writeAsStringSync('${lines.join('\n')}\n');
}
