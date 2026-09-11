enum AttendanceStatus { notAnswered, present, absent, telework, leave }

class TripParticipant {
  const TripParticipant({
    required this.memberId,
    required this.status,
    this.comment,
  });

  factory TripParticipant.fromJson(Map<String, dynamic> json) => TripParticipant(
        memberId: json['memberId'] as String,
        status: AttendanceStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => AttendanceStatus.notAnswered,
        ),
        comment: json['comment'] as String?,
      );

  final String memberId;
  final AttendanceStatus status;
  final String? comment;
}

class Trip {
  const Trip({
    required this.id,
    required this.date,
    required this.participants,
    this.suggestedDriverIds = const [],
    this.confirmedDriverIds = const [],
  });

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        participants: (json['participants'] as List)
            .map((e) => TripParticipant.fromJson(e as Map<String, dynamic>))
            .toList(),
        suggestedDriverIds: (json['suggestedDriverIds'] as List? ?? [])
            .map((e) => e as String)
            .toList(),
        confirmedDriverIds: (json['confirmedDriverIds'] as List? ?? [])
            .map((e) => e as String)
            .toList(),
      );

  final String id;
  final DateTime date;
  final List<TripParticipant> participants;
  final List<String> suggestedDriverIds;
  final List<String> confirmedDriverIds;

  Trip copyWith({
    DateTime? date,
    List<TripParticipant>? participants,
    List<String>? suggestedDriverIds,
    List<String>? confirmedDriverIds,
  }) =>
      Trip(
        id: id,
        date: date ?? this.date,
        participants: participants ?? this.participants,
        suggestedDriverIds: suggestedDriverIds ?? this.suggestedDriverIds,
        confirmedDriverIds: confirmedDriverIds ?? this.confirmedDriverIds,
      );

  List<String> get presentMemberIds => participants
      .where((participant) => participant.status == AttendanceStatus.present)
      .map((participant) => participant.memberId)
      .toList(growable: false);
}
