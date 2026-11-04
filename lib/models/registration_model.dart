class RegistrationModel {
  final String id;
  final String tokenNumber; // e.g. "#001"
  final String name;
  final String phoneNumber;
  final DateTime registrationTime;

  RegistrationModel({
    required this.id,
    required this.tokenNumber,
    required this.name,
    required this.phoneNumber,
    required this.registrationTime,
  });

  // Convert JSON from Backend API to Model
  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    return RegistrationModel(
      id: json['_id'] ?? json['id'] ?? '',
      tokenNumber: json['tokenNumber'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      registrationTime: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['registrationTime'] != null
              ? DateTime.parse(json['registrationTime'])
              : DateTime.now()),
    );
  }

  // Convert Model to JSON for Backend API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tokenNumber': tokenNumber,
      'name': name,
      'phoneNumber': phoneNumber,
      'registrationTime': registrationTime.toIso8601String(),
    };
  }
}
