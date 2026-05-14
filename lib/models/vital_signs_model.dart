class VitalSigns {
  final String? id;
  final String patientId;
  final String doctorId;
  final double? temperature;
  final int? heartRate;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final int? respiratoryRate;
  final double? oxygenSaturation;
  final String notes;
  final DateTime? recordedAt;
  final DateTime? createdAt;

  VitalSigns({
    this.id,
    required this.patientId,
    required this.doctorId,
    this.temperature,
    this.heartRate,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.notes = '',
    this.recordedAt,
    this.createdAt,
  });

  factory VitalSigns.fromJson(Map<String, dynamic> json) {
    return VitalSigns(
      id: json['id'] as String?,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      temperature: (json['temperature'] as num?)?.toDouble(),
      heartRate: json['heart_rate'] as int?,
      bloodPressureSystolic: json['blood_pressure_systolic'] as int?,
      bloodPressureDiastolic: json['blood_pressure_diastolic'] as int?,
      respiratoryRate: json['respiratory_rate'] as int?,
      oxygenSaturation: (json['oxygen_saturation'] as num?)?.toDouble(),
      notes: json['notes'] as String? ?? '',
      recordedAt: json['recorded_at'] != null
          ? DateTime.parse(json['recorded_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'doctor_id': doctorId,
      'temperature': temperature,
      'heart_rate': heartRate,
      'blood_pressure_systolic': bloodPressureSystolic,
      'blood_pressure_diastolic': bloodPressureDiastolic,
      'respiratory_rate': respiratoryRate,
      'oxygen_saturation': oxygenSaturation,
      'notes': notes,
      'recorded_at': recordedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  bool get isCritical {
    if (temperature != null && (temperature! > 39.5 || temperature! < 35.0)) return true;
    if (heartRate != null && (heartRate! > 120 || heartRate! < 50)) return true;
    if (bloodPressureSystolic != null && bloodPressureSystolic! > 180) return true;
    if (oxygenSaturation != null && oxygenSaturation! < 90) return true;
    return false;
  }
}