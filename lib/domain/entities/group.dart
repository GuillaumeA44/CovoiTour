import 'member.dart';
import 'trip.dart';

class CarpoolGroup {
  CarpoolGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.startPoint,
    required this.endPoint,
    required this.outboundTime,
    required this.returnTime,
    required this.adminId,
    required this.members,
    required this.trips,
    required this.scoresByGroupSize,
    this.offDays = const [6, 7], // Samedi et Dimanche par défaut
  });

  final String id;
  String name;
  String description;
  String startPoint;
  String endPoint;
  String outboundTime;
  String returnTime;
  String adminId;
  final List<Member> members;
  final List<Trip> trips;
  final Map<int, Map<String, int>> scoresByGroupSize;
  List<int> offDays;

  factory CarpoolGroup.fromJson(Map<String, dynamic> json) {
    final scoresData = json['scoresByGroupSize'] as Map<String, dynamic>? ?? {};
    final scores = scoresData.map(
      (key, value) => MapEntry(
        int.parse(key),
        (value as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int)),
      ),
    );

    return CarpoolGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      startPoint: json['startPoint'] as String? ?? '',
      endPoint: json['endPoint'] as String? ?? '',
      outboundTime: json['outboundTime'] as String? ?? '',
      returnTime: json['returnTime'] as String? ?? '',
      adminId: json['adminId'] as String? ?? '',
      members: (json['members'] as List? ?? [])
          .map((e) => Member.fromJson(e as Map<String, dynamic>))
          .toList(),
      trips: (json['trips'] as List? ?? [])
          .map((e) => Trip.fromJson(e as Map<String, dynamic>))
          .toList(),
      scoresByGroupSize: scores,
      offDays: (json['offDays'] as List?)?.map((e) => e as int).toList() ?? const [6, 7],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'startPoint': startPoint,
        'endPoint': endPoint,
        'outboundTime': outboundTime,
        'returnTime': returnTime,
        'adminId': adminId,
        'offDays': offDays,
        'members': members
            .map((member) => {
                  'id': member.id,
                  'firstName': member.firstName,
                  'lastName': member.lastName,
                  'email': member.email,
                  'avatarUrl': member.avatarUrl,
                  'hasVehicle': member.hasVehicle,
                  'passengerCapacity': member.passengerCapacity,
                  'isActive': member.isActive,
                })
            .toList(),
        'trips': trips
            .map((trip) => {
                  'id': trip.id,
                  'date': trip.date.toIso8601String(),
                  'participants': trip.participants
                      .map((participant) => {
                            'memberId': participant.memberId,
                            'status': participant.status.name,
                            'comment': participant.comment,
                          })
                      .toList(),
                  'suggestedDriverIds': trip.suggestedDriverIds,
                  'confirmedDriverIds': trip.confirmedDriverIds,
                })
            .toList(),
        'scoresByGroupSize': scoresByGroupSize.map(
          (size, scores) => MapEntry(size.toString(), scores),
        ),
      };
}
