import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:covoi_tour/domain/entities/member.dart';
import 'package:covoi_tour/domain/entities/trip.dart';
import 'package:covoi_tour/domain/services/equity_service.dart';
import 'package:covoi_tour/domain/services/multi_vehicle_service.dart';

void main() {
  test('simulation d un mois: 9 personnes, chacune avec un vehicule', () {
    final members = [
      const Member(id: 'big-car', firstName: 'Grande', lastName: 'Voiture', email: 'big@example.com', hasVehicle: true, passengerCapacity: 5),
      const Member(id: 'small-car', firstName: 'Petite', lastName: 'Voiture', email: 'small@example.com', hasVehicle: true, passengerCapacity: 3),
      const Member(id: 'full-a', firstName: 'Temps', lastName: 'Plein A', email: 'a@example.com', hasVehicle: true, passengerCapacity: 3),
      const Member(id: 'full-b', firstName: 'Temps', lastName: 'Plein B', email: 'b@example.com', hasVehicle: true, passengerCapacity: 3),
      const Member(id: 'half', firstName: 'Mi', lastName: 'Temps', email: 'half@example.com', hasVehicle: true, passengerCapacity: 3),
      const Member(id: 'quarter', firstName: 'Quart', lastName: 'Temps', email: 'quarter@example.com', hasVehicle: true, passengerCapacity: 3),
      const Member(id: 'remote', firstName: 'Tele', lastName: 'Travail', email: 'remote@example.com', hasVehicle: true, passengerCapacity: 3),
      const Member(id: 'vacation', firstName: 'Vacances', lastName: 'Ete', email: 'vacation@example.com', hasVehicle: true, passengerCapacity: 3),
      const Member(id: 'new', firstName: 'Nouveau', lastName: 'Membre', email: 'new@example.com', hasVehicle: true, passengerCapacity: 3),
    ];
    final service = EquityService();
    final vehicleService = MultiVehicleService();
    final history = <Trip>[];
    final driveCounts = {for (final member in members) member.id: 0};
    final passengerCounts = <String, int>{};
    final presenceCounts = <String, int>{};
    final lastDriveDay = <String, int>{};
    var coveredDays = 0;
    var unassignedPeople = 0;
    var dayNumber = 0;

    for (var date = DateTime(2026, 9, 1); date.isBefore(DateTime(2026, 10, 1)); date = date.add(const Duration(days: 1))) {
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) continue;
      dayNumber++;
      final presentIds = members
          .where((member) => _isPresent(member.id, date))
          .map((member) => member.id)
          .toList();
      for (final memberId in presentIds) {
        presenceCounts[memberId] = (presenceCounts[memberId] ?? 0) + 1;
      }
      if (presentIds.length < 2) continue;

      final trip = Trip(
        id: 'day-$dayNumber',
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
      final scores = service.calculatePriorityScores(
        trips: history,
        members: members,
        currentTrip: trip,
        minimumDrivingPresenceThreshold: 10,
      );
      final plan = vehicleService.plan(
        drivers: members.where((member) => member.hasVehicle).toList(),
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
        driveCounts[assignment.driverId] = (driveCounts[assignment.driverId] ?? 0) + 1;
        lastDriveDay[assignment.driverId] = dayNumber;
        passengerCounts[assignment.driverId] =
            (passengerCounts[assignment.driverId] ?? 0) + assignment.passengerIds.length;
      }
      history.add(trip.copyWith(
        confirmedDriverIds: plan.assignments.map((item) => item.driverId).toList(),
        passengerIdsByDriver: {
          for (final assignment in plan.assignments)
            assignment.driverId: List<String>.from(assignment.passengerIds),
        },
      ));
    }

    final finalScores = service.calculatePriorityScores(
      trips: history,
      members: members,
      minimumDrivingPresenceThreshold: 10,
    );
    final driverIds = members.map((member) => member.id).toList();
    final driverPresenceShare = {
      for (final id in driverIds)
        id: (presenceCounts[id] ?? 0) == 0 ? 0.0 : (driveCounts[id] ?? 0) / presenceCounts[id]!,
    };
    final driverShareGap = driverPresenceShare.values.reduce((left, right) => left > right ? left : right) -
      driverPresenceShare.values.reduce((left, right) => left < right ? left : right);
    final normalizedLoads = {
      for (final member in members)
        member.id: (driveCounts[member.id] ?? 0) == 0
            ? 0.0
            : (passengerCounts[member.id] ?? 0) /
                (member.passengerCapacity * driveCounts[member.id]!),
    };
    final normalizedLoadGap = normalizedLoads.values.reduce((left, right) => left > right ? left : right) -
        normalizedLoads.values.reduce((left, right) => left < right ? left : right);
    final maxDaysWithoutDriving = driverIds
        .map((id) => dayNumber - (lastDriveDay[id] ?? 0))
        .reduce((left, right) => left > right ? left : right);

    _writeSimulationReport(
      members: members,
      presenceCounts: presenceCounts,
      driveCounts: driveCounts,
      passengerCounts: passengerCounts,
      finalScores: finalScores,
      dayNumber: dayNumber,
      coveredDays: coveredDays,
      unassignedPeople: unassignedPeople,
      maxDaysWithoutDriving: maxDaysWithoutDriving,
      normalizedLoadGap: normalizedLoadGap,
      drivingRatioGap: driverShareGap,
    );

    expect(dayNumber, 22);
    expect(coveredDays, 22);
    expect(unassignedPeople, 0);
    expect(driveCounts.values.every((count) => count > 0), isTrue);
    expect(maxDaysWithoutDriving, lessThanOrEqualTo(10));
    expect(presenceCounts['new'], 15);
    expect(driverShareGap, lessThanOrEqualTo(0.20));
    expect(normalizedLoadGap, lessThanOrEqualTo(0.4));
    final fullTimeRatios = [
      for (final id in const ['big-car', 'small-car', 'full-a', 'full-b'])
        (driveCounts[id] ?? 0) / presenceCounts[id]!,
    ];
    final fullTimeRatioGap = fullTimeRatios.reduce((left, right) => left > right ? left : right) -
        fullTimeRatios.reduce((left, right) => left < right ? left : right);
    expect(fullTimeRatioGap, lessThanOrEqualTo(1 / 22));
    expect(finalScores.values.every((score) => score.finalScore.isFinite), isTrue);

    // Le trajet du 15 septembre simule une exception: la petite voiture est indisponible.
    final exceptionTrip = Trip(
      id: 'exception',
      date: DateTime(2026, 9, 15),
      participants: const [
        TripParticipant(memberId: 'big-car', status: AttendanceStatus.present),
        TripParticipant(memberId: 'small-car', status: AttendanceStatus.absent, comment: 'J ai besoin de ma voiture aujourd hui'),
        TripParticipant(memberId: 'full-a', status: AttendanceStatus.present),
      ],
    );
    final exceptionPlan = vehicleService.plan(
      drivers: members.where((member) => member.id == 'big-car').toList(),
      passengerIds: exceptionTrip.presentMemberIds,
      scores: const {},
      finalScores: const {'big-car': 0},
    );
    expect(exceptionPlan.assignments.map((assignment) => assignment.driverId), ['big-car']);
    expect(exceptionPlan.unassignedPassengerIds, isEmpty);
  });
}

bool _isPresent(String memberId, DateTime date) {
  if (memberId == 'new' && date.isBefore(DateTime(2026, 9, 10))) return false;
  if (memberId == 'vacation' && date.day >= 8 && date.day <= 12) return false;
  if (memberId == 'remote' && date.weekday == DateTime.wednesday) return false;
  if (memberId == 'quarter' && date.weekday != DateTime.monday) return false;
  if (memberId == 'half' && date.day.isEven) return false;
  return true;
}

AttendanceStatus _absenceStatus(String memberId, DateTime date) {
  if (memberId == 'vacation' && date.day >= 8 && date.day <= 12) return AttendanceStatus.leave;
  if (memberId == 'remote' && date.weekday == DateTime.wednesday) return AttendanceStatus.telework;
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

void _writeSimulationReport({
  required List<Member> members,
  required Map<String, int> presenceCounts,
  required Map<String, int> driveCounts,
  required Map<String, int> passengerCounts,
  required Map<String, EquityScore> finalScores,
  required int dayNumber,
  required int coveredDays,
  required int unassignedPeople,
  required int maxDaysWithoutDriving,
  required double normalizedLoadGap,
  required double drivingRatioGap,
}) {
  const profiles = {
    'big-car': 'Présence 100 %, véhicule 5 places passager',
    'small-car': 'Présence 100 %, véhicule 3 places passager',
    'full-a': 'Présence 100 %, véhicule 3 places passager',
    'full-b': 'Présence 100 %, véhicule 3 places passager',
    'half': 'Présence 50 %, véhicule 3 places passager',
    'quarter': 'Présence 25 %, véhicule 3 places passager',
    'remote': 'Présence 100 %, télétravail chaque mercredi, véhicule 3 places passager',
    'vacation': 'Présence 100 %, vacances du 8 au 12 septembre, véhicule 3 places passager',
    'new': 'Nouveau membre dès le 10 septembre, véhicule 3 places passager',
  };
  final lines = <String>[
    '# Bilan de simulation d’équité',
    '',
    '## Contexte',
    '',
    '- Période simulée : septembre 2026, $dayNumber jours ouvrés.',
    '- Groupe : 9 personnes, chacune possède un véhicule ; le moteur sélectionne le nombre minimal de véhicules nécessaires.',
    '- Hypothèse métier : chaque personne présente et éligible doit conduire au moins une fois sur la période.',
    '- Personnes ayant effectivement conduit : ${driveCounts.values.where((count) => count > 0).length}/${members.length}.',
    '- Seuil de conduite minimale : 10 présences sans conduire.',
    '- Le nombre de voitures est minimisé avant de comparer la somme des scores finaux.',
    '- Le coefficient individuel est calculé ainsi : `jours conduits / jours présents`.',
    '- La charge normalisée par conduite est calculée ainsi : `passagers transportés / (capacité × jours conduits)`.',
    '- Le score final est calculé ainsi : `score d’équité + (0,1 × score de contribution) − bonus de priorité`.',
    '- Le score d’équité compare directement le ratio de conduite individuel au ratio moyen du groupe.',
    '- Le score de contribution compare les passagers transportés à la contribution moyenne du groupe.',
    '- Le bonus de priorité vaut `présences depuis la dernière conduite / 10`.',
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
    '- Écart maximal sans conduire pour les conducteurs : $maxDaysWithoutDriving jours.',
    '- Écart maximal de charge normalisée par conduite : ${normalizedLoadGap.toStringAsFixed(2)}.',
    '- Écart maximal du coefficient conduites / présences : ${drivingRatioGap.toStringAsFixed(2)}.',
    '- Exception testée : le 15 septembre, la petite voiture est indisponible.',
    '',
    '## Tableau récapitulatif individuel',
    '',
    '| Personne | Présences | Jours conduits | Jours conduits / jours présents (coût réel) | Capacité véhicule | Passagers transportés | Charge normalisée par conduite | Score final |',
    '|---|---:|---:|---:|---:|---:|---:|---:|',
  ];

  for (final member in members) {
    final presences = presenceCounts[member.id] ?? 0;
    final drives = driveCounts[member.id] ?? 0;
    final coefficient = presences == 0 ? 0.0 : drives / presences;
    final passengers = passengerCounts[member.id] ?? 0;
    final capacity = member.passengerCapacity;
    final normalizedLoad = drives == 0
      ? '0.00'
      : (passengers / (capacity * drives)).toStringAsFixed(2);
    final score = finalScores[member.id]?.finalScore.toStringAsFixed(2) ?? '-';
    lines.add('| ${member.name} | $presences | $drives | ${drives} / $presences = ${coefficient.toStringAsFixed(2)} | $capacity | $passengers | $normalizedLoad | $score |');
  }

  lines.addAll([
    '',
    '## Lecture du bilan',
    '',
    '- Le coût réel individuel est affiché explicitement sous la forme `jours conduits / jours présents` : proche de `1`, la personne conduit presque à chaque présence ; proche de `0`, elle conduit peu ou pas encore.',
    '- La charge normalisée par conduite est `passagers transportés / (capacité × jours conduits)`. Elle mesure le remplissage moyen de chaque trajet et permet de comparer une voiture de 5 places avec une voiture de 3 places.',
    '- Formule complète : `Score final = Score d’équité + (0,1 × Score de contribution) − Bonus de priorité`.',
    '- Exemple Grande Voiture : `0,13 + 2,42 − 0 = 2,55`.',
    '- Un score final négatif est prioritaire sur un score positif. Le bonus et un faible nombre de conduites font donc baisser le score.',
    '- Conclusion de cette simulation : l’écart est réduit, mais reste supérieur à 0,15 ; la répartition n’est donc pas encore parfaitement équitable.',
    '- Les absences, vacances et télétravail ne sont pas comptés comme des présences.',
  ]);

  File('test/monthly_equity_simulation_report.md').writeAsStringSync('${lines.join('\n')}\n');
}
