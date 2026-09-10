enum AttendanceStatus { notAnswered, present, absent }

class TripParticipant {
  const TripParticipant({required this.memberId, required this.status});

  final String memberId;
  final AttendanceStatus status;
}

class Trip {
  const Trip({
    required this.id,
    required this.date,
    required this.participants,
    this.suggestedDriverId,
    this.confirmedDriverId,
  });

  final String id;
  final DateTime date;
  final List<TripParticipant> participants;
  final String? suggestedDriverId;
  final String? confirmedDriverId;

  List<String> get presentMemberIds => participants
      .where((participant) => participant.status == AttendanceStatus.present)
      .map((participant) => participant.memberId)
      .toList(growable: false);
}
