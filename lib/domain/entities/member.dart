class Member {
  const Member({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
    this.hasVehicle = false,
    this.passengerCapacity = 0,
    this.isActive = true,
  });

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'] as String,
        firstName: json['firstName'] as String? ?? (json['name'] as String? ?? '').split(' ').first,
        lastName: json['lastName'] as String? ?? (json['name'] as String? ?? '').split(' ').skip(1).join(' '),
        email: json['email'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        hasVehicle: json['hasVehicle'] as bool? ?? false,
        passengerCapacity: json['passengerCapacity'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
      );

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;
  final bool hasVehicle;
  final int passengerCapacity;
  final bool isActive;

  String get name => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  Member copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? avatarUrl,
    bool? hasVehicle,
    int? passengerCapacity,
    bool? isActive,
  }) =>
      Member(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        hasVehicle: hasVehicle ?? this.hasVehicle,
        passengerCapacity: passengerCapacity ?? this.passengerCapacity,
        isActive: isActive ?? this.isActive,
      );

  bool canDrive({required int passengerCount}) =>
      isActive && hasVehicle && passengerCapacity >= passengerCount;
}
