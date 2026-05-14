class MedicalFile {
  final String? id;
  final String patientId;
  final String doctorId;
  final String observation;
  final String interventionType;
  final String description;
  final String? fileUrl;
  final String? fileName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MedicalFile({
    this.id,
    required this.patientId,
    required this.doctorId,
    this.observation = '',
    this.interventionType = '',
    this.description = '',
    this.fileUrl,
    this.fileName,
    this.createdAt,
    this.updatedAt,
  });

  factory MedicalFile.fromJson(Map<String, dynamic> json) {
    return MedicalFile(
      id: json['id'] as String?,
      patientId: json['patient_id'] as String,
      doctorId: json['doctor_id'] as String,
      observation: json['observation'] as String? ?? '',
      interventionType: json['intervention_type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'observation': observation,
      'intervention_type': interventionType,
      'description': description,
      'file_url': fileUrl,
      'file_name': fileName,
    };
  }
}