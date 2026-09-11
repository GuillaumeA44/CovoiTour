import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/drive_client_helper.dart';
import '../../data/repositories/google_drive_document_repository.dart';
import '../../data/repositories/local_document_repository.dart';
import '../../data/serialization/carpool_json_codec.dart';
import '../../domain/entities/advanced_trip.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/member.dart';
import '../../domain/entities/trip.dart';
import '../../domain/services/auth_service.dart';
import '../../domain/services/equity_service.dart';
import '../../domain/services/multi_vehicle_service.dart';
import '../../domain/services/statistics_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class AppState extends ChangeNotifier {
  AppState() {
    _init();
    _authService.onCurrentUserChanged.listen((account) {
      _currentUser = account;
      notifyListeners();
    });
  }

  CarpoolGroup? _group;
  CarpoolGroup get group => _group ?? _initialGroup();

  String? _lastKnownRevision;
  
  final EquityService equityService = EquityService();
  final StatisticsService _statisticsService = StatisticsService();
  final MultiVehicleService _multiVehicleService = MultiVehicleService();
  final LocalDocumentRepository repository = LocalDocumentRepository();
  final AuthService _authService = AuthService();
  final CarpoolJsonCodec codec = CarpoolJsonCodec();

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Map<String, MemberStatistics> getStatistics() {
    final maxGroupSize = group.scoresByGroupSize.keys.fold(0, (max, val) => val > max ? val : max);
    final currentScores = group.scoresByGroupSize[maxGroupSize] ?? {};
    
    return _statisticsService.calculate(
      trips: group.trips.where((t) => t.confirmedDriverIds.isNotEmpty).toList(),
      scores: currentScores,
    );
  }

  Future<void> signIn() => _authService.signIn();
  Future<void> signOut() => _authService.signOut();

  Future<void> syncWithDrive() async {
    if (_currentUser == null) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final authHeaders = await _currentUser!.authHeaders;
      final client = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(client);
      final driveRepo = GoogleDriveDocumentRepository(driveApi);

      final remoteRevision = await driveRepo.getLatestRevisionId();

      if (remoteRevision != null && remoteRevision != _lastKnownRevision) {
        // Le fichier a été modifié par quelqu'un d'autre
        final driveJson = await driveRepo.readDocument('default');
        final decoded = codec.decode(driveJson);
        final remoteGroup = CarpoolGroup.fromJson(decoded['document'] as Map<String, dynamic>);
        
        // Stratégie de fusion simple ou "Le Drive gagne"
        _group = remoteGroup;
        _lastKnownRevision = remoteRevision;
        await _save();
      } else {
        // Pas de changement sur le Drive, on upload notre version locale
        await driveRepo.writeDocument(
          documentId: 'default',
          json: codec.encode(group),
          expectedRevision: _lastKnownRevision ?? '',
        );
        // Mettre à jour la révision après écriture
        _lastKnownRevision = await driveRepo.getLatestRevisionId();
      }
    } catch (e) {
      debugPrint('Erreur de synchronisation : $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void updateGroup({
    required String name,
    required String description,
    required String startPoint,
    required String endPoint,
    required String outboundTime,
    required String returnTime,
    List<int>? offDays,
  }) {
    group.name = name;
    group.description = description;
    group.startPoint = startPoint;
    group.endPoint = endPoint;
    group.outboundTime = outboundTime;
    group.returnTime = returnTime;
    if (offDays != null) {
      group.offDays = offDays;
    }
    _save();
    notifyListeners();
  }

  Future<void> _init() async {
    try {
      if (await repository.hasDocument('default')) {
        final json = await repository.readDocument('default');
        final decoded = codec.decode(json);
        _group = CarpoolGroup.fromJson(decoded['document'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Erreur de chargement : $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _save() async {
    if (_group == null) return;
    try {
      final json = codec.encode(_group!);
      await repository.writeDocument(
        documentId: 'default',
        json: json,
        expectedRevision: '', // Pas encore géré localement
      );
    } catch (e) {
      debugPrint('Erreur de sauvegarde : $e');
    }
  }

  List<Member> get activeMembers =>
      group.members.where((member) => member.isActive).toList(growable: false);

  Map<String, int> scoresFor(int participantCount) =>
      group.scoresByGroupSize.putIfAbsent(participantCount, () => <String, int>{});

  void addMember({
    required String firstName,
    required String lastName,
    required String email,
    required bool hasVehicle,
    required int passengerCapacity,
    String? avatarUrl,
  }) {
    final id = 'member-${DateTime.now().millisecondsSinceEpoch}';
    group.members.add(Member(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      avatarUrl: avatarUrl,
      hasVehicle: hasVehicle,
      passengerCapacity: passengerCapacity,
    ));
    _save();
    notifyListeners();
  }

  void updateMember(Member updatedMember) {
    final index = group.members.indexWhere((m) => m.id == updatedMember.id);
    if (index >= 0) {
      group.members[index] = updatedMember;
      _save();
      notifyListeners();
    }
  }

  void archiveMember(String memberId) {
    final index = group.members.indexWhere((m) => m.id == memberId);
    if (index >= 0) {
      group.members[index] = group.members[index].copyWith(isActive: false);
      _save();
      notifyListeners();
    }
  }

  void setAttendance(String memberId, AttendanceStatus status, {DateTime? date, String? comment}) {
    final targetDate = date ?? _nextTrip().date;
    final normalizedDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    var tripIndex = group.trips.indexWhere((t) => 
      t.date.year == normalizedDate.year && 
      t.date.month == normalizedDate.month && 
      t.date.day == normalizedDate.day
    );

    Trip trip;
    if (tripIndex < 0) {
      trip = Trip(
        id: 'trip-${normalizedDate.millisecondsSinceEpoch}',
        date: normalizedDate,
        participants: activeMembers
            .map((m) => TripParticipant(memberId: m.id, status: AttendanceStatus.notAnswered))
            .toList(),
      );
      group.trips.add(trip);
      tripIndex = group.trips.length - 1;
    } else {
      trip = group.trips[tripIndex];
    }

    final participants = List<TripParticipant>.from(trip.participants);
    final pIndex = participants.indexWhere((item) => item.memberId == memberId);
    
    final newParticipant = TripParticipant(
      memberId: memberId, 
      status: status, 
      comment: comment ?? (pIndex >= 0 ? participants[pIndex].comment : null)
    );

    if (pIndex < 0) {
      participants.add(newParticipant);
    } else {
      participants[pIndex] = newParticipant;
    }

    group.trips[tripIndex] = trip.copyWith(participants: participants);
    _save();
    notifyListeners();
  }

  void setComment(String memberId, DateTime date, String comment) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    var tripIndex = group.trips.indexWhere((t) => 
      t.date.year == normalizedDate.year && 
      t.date.month == normalizedDate.month && 
      t.date.day == normalizedDate.day
    );

    if (tripIndex < 0) {
      final trip = Trip(
        id: 'trip-${normalizedDate.millisecondsSinceEpoch}',
        date: normalizedDate,
        participants: activeMembers
            .map((m) => TripParticipant(memberId: m.id, status: AttendanceStatus.notAnswered))
            .toList(),
      );
      group.trips.add(trip);
      tripIndex = group.trips.length - 1;
    }

    final trip = group.trips[tripIndex];
    final participants = List<TripParticipant>.from(trip.participants);
    final pIndex = participants.indexWhere((item) => item.memberId == memberId);

    if (pIndex < 0) {
      participants.add(TripParticipant(memberId: memberId, status: AttendanceStatus.notAnswered, comment: comment));
    } else {
      participants[pIndex] = TripParticipant(
        memberId: memberId, 
        status: participants[pIndex].status, 
        comment: comment
      );
    }

    group.trips[tripIndex] = trip.copyWith(participants: participants);
    _save();
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

  TripPlan recommendPlan() {
    final trip = _nextTrip();
    final presentIds = trip.presentMemberIds;
    final scores = scoresFor(presentIds.length);
    
    return _multiVehicleService.plan(
      drivers: activeMembers,
      passengerIds: presentIds,
      scores: scores,
    );
  }

  void confirmDriver(String memberId) {
    final trip = _nextTrip();
    final presentCount = trip.presentMemberIds.length;
    if (presentCount < 2) return;
    final result = equityService.calculateTripPoints(trip: trip, driverId: memberId);
    final scores = scoresFor(presentCount);
    
    for (final id in trip.presentMemberIds) {
      scores.putIfAbsent(id, () => 0);
    }
    
    result.pointsByMemberId.forEach((id, points) {
      scores[id] = (scores[id] ?? 0) + points;
    });

    final tripIndex = group.trips.indexOf(trip);
    group.trips[tripIndex] = Trip(
      id: trip.id,
      date: trip.date,
      participants: List.from(trip.participants),
      suggestedDriverIds: trip.suggestedDriverIds,
      confirmedDriverIds: [memberId],
    );

    _createNewTripAfter(trip);
    _save();
    notifyListeners();
  }

  void confirmPlan(TripPlan plan) {
    final trip = _nextTrip();
    
    for (final assignment in plan.assignments) {
      final tripForEquity = trip.copyWith(participants: [
        ...assignment.passengerIds.map((pid) => TripParticipant(memberId: pid, status: AttendanceStatus.present)),
        TripParticipant(memberId: assignment.driverId, status: AttendanceStatus.present),
      ]);
      
      final result = equityService.calculateTripPoints(
        trip: tripForEquity,
        driverId: assignment.driverId,
      );
      
      final currentScores = scoresFor(assignment.passengerIds.length + 1);
      result.pointsByMemberId.forEach((id, points) {
        currentScores.putIfAbsent(id, () => 0);
        currentScores[id] = currentScores[id]! + points;
      });
    }

    final confirmedDrivers = plan.assignments.map((a) => a.driverId).toList();
    final tripIndex = group.trips.indexOf(trip);
    group.trips[tripIndex] = Trip(
      id: trip.id,
      date: trip.date,
      participants: List.from(trip.participants),
      suggestedDriverIds: trip.suggestedDriverIds,
      confirmedDriverIds: confirmedDrivers,
    );

    _createNewTripAfter(trip);
    _save();
    notifyListeners();
  }

  void adjustScore(int groupSize, String memberId, int newScore) {
    final scores = group.scoresByGroupSize[groupSize];
    if (scores != null && scores.containsKey(memberId)) {
      scores[memberId] = newScore;
      _save();
      notifyListeners();
    }
  }

  void _createNewTripAfter(Trip lastTrip) {
    DateTime nextDate = lastTrip.date.add(const Duration(days: 1));
    while (nextDate.weekday == DateTime.saturday || nextDate.weekday == DateTime.sunday) {
      nextDate = nextDate.add(const Duration(days: 1));
    }

    final newTrip = Trip(
      id: 'trip-${nextDate.millisecondsSinceEpoch}',
      date: nextDate,
      participants: activeMembers
          .map((m) => TripParticipant(memberId: m.id, status: AttendanceStatus.notAnswered))
          .toList(),
    );
    group.trips.add(newTrip);
  }

  Trip _nextTrip() => group.trips.firstWhere((t) => t.confirmedDriverIds.isEmpty, orElse: () => group.trips.last);

  DateTime _lastDriveDate(String memberId) {
    for (final trip in group.trips.reversed) {
      if (trip.confirmedDriverIds.contains(memberId)) return trip.date;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static CarpoolGroup _initialGroup() {
    final members = <Member>[
      const Member(
        id: 'member-1',
        firstName: 'Alice',
        lastName: 'Martin',
        email: 'alice@example.com',
        hasVehicle: true,
        passengerCapacity: 3,
      ),
      const Member(
        id: 'member-2',
        firstName: 'Benoit',
        lastName: 'Durand',
        email: 'benoit@example.com',
        hasVehicle: true,
        passengerCapacity: 4,
      ),
      const Member(
        id: 'member-3',
        firstName: 'Chloe',
        lastName: 'Bernard',
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
