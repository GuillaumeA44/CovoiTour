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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'startPoint': startPoint,
        'endPoint': endPoint,
        'outboundTime': outboundTime,
        'returnTime': returnTime,
        'adminId': adminId,
        'members': members
            .map((member) => {
                  'id': member.id,
                  'name': member.name,
                  'email': member.email,
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
                          })
                      .toList(),
                  'suggestedDriverId': trip.suggestedDriverId,
                  'confirmedDriverId': trip.confirmedDriverId,
                })
            .toList(),
        'scoresByGroupSize': scoresByGroupSize.map(
          (size, scores) => MapEntry(size.toString(), scores),
        ),
      };
}
