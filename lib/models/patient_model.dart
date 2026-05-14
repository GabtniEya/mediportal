// lib/models/patient_model.dart
class Patient {
  final String? id;
  final String doctorId;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String address;
  final String phone;
  final String email;
  final List<String> allergies;
  final String bloodType;
  final String emergencyContact;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Patient({
    this.id,
    required this.doctorId,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.address = '',
    this.phone = '',
    this.email = '',
    this.allergies = const [],
    this.bloodType = 'O+',
    this.emergencyContact = '',
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_id': doctorId,
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'address': address,
      'phone': phone,
      'email': email,
      'allergies': allergies,
      'blood_type': bloodType,
      'emergency_contact': emergencyContact,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      doctorId: json['doctor_id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      allergies: json['allergies'] != null 
          ? List<String>.from(json['allergies']) 
          : [],
      bloodType: json['blood_type'] ?? 'O+',
      emergencyContact: json['emergency_contact'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Patient copyWith({
    String? id,
    String? doctorId,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? address,
    String? phone,
    String? email,
    List<String>? allergies,
    String? bloodType,
    String? emergencyContact,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Patient(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      allergies: allergies ?? this.allergies,
      bloodType: bloodType ?? this.bloodType,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}