import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:covoi_tour/domain/entities/member.dart';
import 'package:covoi_tour/domain/entities/trip.dart';
import 'package:covoi_tour/domain/services/equity_service.dart';
import 'package:covoi_tour/domain/services/multi_vehicle_service.dart';

void main() {
  test('simulation 3: profils de presence differents sur deux mois', () {
    final members = [
      const Member(id: 'full-a', firstName: 'Temps Plein A', lastName: '', email: 'full-a@example.com', hasVehicle: true, passengerCapacity: 4),
      const Member(id: 'full-b', firstName: 'Temps Plein B', lastName: '', email: 'full-b@example.com', hasVehicle: true, passengerCapacity: 4),
      const Member(id: 'three-days', firstName: 'Trois Jours Sur Cinq', lastName: '', email: 'three@example.com', hasVehicle: true, passengerCapacity: 4),
      const Member(id: 'mid-period', firstName: 'Arrivee Milieu', lastName: '', email: 'mid@example.com', hasVehicle: true, passengerCapacity: 4),
    ];
    final equityService = EquityService();
    final vehicleService = MultiVehicleService();
    final history = <Trip>[];
    final driveCounts = {for (final member in members) member.id: 0};
    final presenceCounts = {for (final member in members) member.id: 0};
    final passengerCounts = {for (final member in members) member.id: 0};
    var coveredDays = 0;
    var unassignedPeople = 0;
    var singleParticipantDays = 0;
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
      if (presentIds.length < 2) {
        singleParticipantDays++;
        continue;
      }

      final trip = Trip(
        id: 'simulation3-day-$dayNumber',
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
      unassignedPeople: unassignedPeople,
      singleParticipantDays: singleParticipantDays,
      ratioGap: ratioGap,
    );

    expect(dayNumber, 43);
    expect(coveredDays, 35);
    expect(singleParticipantDays, 8);
    expect(unassignedPeople, 0);
    expect(presenceCounts['full-a'], 22);
    expect(presenceCounts['full-b'], 43);
    expect(presenceCounts['three-days'], 26);
    expect(presenceCounts['mid-period'], 10);
    expect(driveCounts.values.every((count) => count > 0), isTrue);
    expect(ratioGap, lessThanOrEqualTo(0.20));
    expect(finalScores.values.every((score) => score.finalScore.isFinite), isTrue);
  });
}

bool _isPresent(String memberId, DateTime date) {
  if (memberId == 'full-a' && date.month == 11) return false;
  if (memberId == 'three-days' &&
      date.weekday != DateTime.monday &&
      date.weekday != DateTime.wednesday &&
      date.weekday != DateTime.friday) {
    return false;
  }
  if (memberId == 'mid-period' &&
      !(date.month == 10 && date.day >= 12 && date.day <= 23)) {
    return false;
  }
  return true;
}

AttendanceStatus _absenceStatus(String memberId, DateTime date) {
  if (memberId == 'full-a' && date.month == 11) return AttendanceStatus.leave;
  if (memberId == 'mid-period') return AttendanceStatus.absent;
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
  required int singleParticipantDays,
  required double ratioGap,
}) {
  const profiles = {
    'full-a': 'Temps plein, vacances pendant tout le mois de novembre, véhicule 4 places passager',
    'full-b': 'Temps plein sur toute la période, véhicule 4 places passager',
    'three-days': 'Présence lundi, mercredi et vendredi, véhicule 4 places passager',
    'mid-period': 'Présence uniquement du 12 au 23 octobre, soit 2 semaines, véhicule 4 places passager',
  };
  final lines = <String>[
    '# Bilan de simulation d’équité',
    '',
    '## Contexte',
    '',
    '- Période simulée : octobre et novembre 2026, $dayNumber jours ouvrés.',
    '- Groupe : 4 personnes, chacune possède un véhicule de 4 places passager.',
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
    for (final member in members) '| ${member.name} | ${profiles[member.id]} |',
    '',
    '## Résultats globaux',
    '',
    '- Jours avec au moins deux participants et entièrement couverts : $coveredDays/$dayNumber.',
    '- Jours avec une seule personne présente, donc sans covoiturage possible : $singleParticipantDays.',
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
    lines.add('| ${member.name} | ${presenceCounts[member.id]} | $drives | $drives / ${presenceCounts[member.id]} = ${ratios[member.id]!.toStringAsFixed(2)} | ${member.passengerCapacity} | $passengers | $normalizedLoad | ${finalScores[member.id]!.finalScore.toStringAsFixed(2)} |');
  }
  lines.addAll([
    '',
    '## Lecture du bilan',
    '',
    '- Le coût réel individuel est affiché sous la forme `jours conduits / jours présents`.',
    '- La charge normalisée par conduite est `passagers transportés / (capacité × jours conduits)`.',
    '- Formule complète : `Score final = Score d’équité + (0,1 × Score de contribution) − Bonus de priorité`.',
    '- Les vacances, absences et jours sans présence ne sont pas comptés dans le dénominateur.',
  ]);
  File('test/simulation3/four_people_profile_simulation_report.md').writeAsStringSync('${lines.join('\n')}\n');
}
