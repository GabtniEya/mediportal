import 'package:flutter/material.dart';
import 'package:mediportal/pages/avc_registration_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme_controller.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/patient_model.dart';
import '../models/medical_file_model.dart';
import '../models/vital_signs_model.dart';

final supabase = Supabase.instance.client;

class MedicalFilesPage extends StatefulWidget {
  final String patientId;
  MedicalFilesPage({super.key, required this.patientId});

  @override
  State<MedicalFilesPage> createState() => _MedicalFilesPageState();
}

class _MedicalFilesPageState extends State<MedicalFilesPage> {
  Patient? _patient;
  List<MedicalFile> _files = [];
  List<VitalSigns> _vitalSigns = [];
  bool _isLoading = true;
  bool _showFileForm = false;
  bool _showVitalsForm = false;

  final _observationCtrl = TextEditingController();
  final _interventionTypeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  final _temperatureCtrl = TextEditingController();
  final _heartRateCtrl = TextEditingController();
  final _bpSystolicCtrl = TextEditingController();
  final _bpDiastolicCtrl = TextEditingController();
  final _respiratoryRateCtrl = TextEditingController();
  final _oxygenSatCtrl = TextEditingController();
  final _vitalsNotesCtrl = TextEditingController();

  Color get bg        => AppThemeController.color(Color(0xFF0D2B22), Color(0xFFF0F4FF));
  Color get surface   => AppThemeController.color(Color(0xFF132E24), Color(0xFFFFFFFF));
  Color get card      => AppThemeController.color(Color(0xFF0F2620), Color(0xFFFFFFFF));
  Color get primary   => AppThemeController.color(Color(0xFF4CAF92), Color(0xFF0D47A1));
  Color get primaryDk => AppThemeController.color(Color(0xFF2E7D64), Color(0xFF1976D2));
  Color get textHi    => AppThemeController.color(Color(0xFFFFFFFF), Color(0xFF333333));
  Color get textMid   => AppThemeController.color(Color(0x99FFFFFF), Color(0xAA333333));
  Color get glassBdr  => AppThemeController.color(Color(0x1AFFFFFF), Color(0x220D47A1));

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final patientData = await supabase
          .from('patients')
          .select()
          .eq('id', widget.patientId)
          .maybeSingle();

      final filesData = await supabase
          .from('medical_files')
          .select()
          .eq('patient_id', widget.patientId)
          .eq('doctor_id', userId)
          .order('created_at', ascending: false);

      final vitalsData = await supabase
          .from('vital_signs')
          .select()
          .eq('patient_id', widget.patientId)
          .eq('doctor_id', userId)
          .order('recorded_at', ascending: false);

      if (mounted) {
        setState(() {
          _patient = patientData != null ? Patient.fromJson(patientData) : null;
          _files = (filesData as List).map((e) => MedicalFile.fromJson(e)).toList();
          _vitalSigns = (vitalsData as List).map((e) => VitalSigns.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('medical_files').insert({
        'patient_id': widget.patientId,
        'doctor_id': userId,
        'observation': _observationCtrl.text.trim(),
        'intervention_type': _interventionTypeCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
      });

      _observationCtrl.clear();
      _interventionTypeCtrl.clear();
      _descriptionCtrl.clear();
      setState(() => _showFileForm = false);
      _loadData();
      _showSnackBar('Observation ajoutee');
    } catch (e) {
      _showSnackBar('Erreur lors de la sauvegarde', isError: true);
    }
  }

  Future<void> _saveVitals() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('vital_signs').insert({
        'patient_id': widget.patientId,
        'doctor_id': userId,
        'temperature': _temperatureCtrl.text.isNotEmpty ? double.tryParse(_temperatureCtrl.text) : null,
        'heart_rate': _heartRateCtrl.text.isNotEmpty ? int.tryParse(_heartRateCtrl.text) : null,
        'blood_pressure_systolic': _bpSystolicCtrl.text.isNotEmpty ? int.tryParse(_bpSystolicCtrl.text) : null,
        'blood_pressure_diastolic': _bpDiastolicCtrl.text.isNotEmpty ? int.tryParse(_bpDiastolicCtrl.text) : null,
        'respiratory_rate': _respiratoryRateCtrl.text.isNotEmpty ? int.tryParse(_respiratoryRateCtrl.text) : null,
        'oxygen_saturation': _oxygenSatCtrl.text.isNotEmpty ? double.tryParse(_oxygenSatCtrl.text) : null,
        'notes': _vitalsNotesCtrl.text.trim(),
        'recorded_at': DateTime.now().toIso8601String(),
      });

      _temperatureCtrl.clear();
      _heartRateCtrl.clear();
      _bpSystolicCtrl.clear();
      _bpDiastolicCtrl.clear();
      _respiratoryRateCtrl.clear();
      _oxygenSatCtrl.clear();
      _vitalsNotesCtrl.clear();
      setState(() => _showVitalsForm = false);
      _loadData();
      _showSnackBar('Signaux vitaux enregistres');
    } catch (e) {
      _showSnackBar('Erreur lors de la sauvegarde', isError: true);
    }
  }

  Future<void> _deleteFile(String id) async {
    try {
      await supabase.from('medical_files').delete().eq('id', id);
      _loadData();
      _showSnackBar('Observation supprimee');
    } catch (e) {
      _showSnackBar('Erreur lors de la suppression', isError: true);
    }
  }

  Future<void> _exportPDF() async {
    if (_patient == null) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Container(
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor(0.05, 0.28, 0.63),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DOSSIER MEDICAL',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  pw.SizedBox(height: 8),
                  pw.Text('MediPortal - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                      style:  pw.TextStyle(fontSize: 12, color: PdfColors.white)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Container(
              padding: pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor(0.8, 0.8, 0.8)),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('INFORMATIONS DU PATIENT',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text('Nom: ${_patient!.fullName}'),
                  if (_patient!.dateOfBirth != null)
                    pw.Text('Date de naissance: ${DateFormat('dd/MM/yyyy').format(_patient!.dateOfBirth!)}'),
                  if (_patient!.bloodType.isNotEmpty)
                    pw.Text('Groupe sanguin: ${_patient!.bloodType}'),
                  if (_patient!.allergies.isNotEmpty)
                    pw.Text('Allergies: ${_patient!.allergies.join(', ')}',
                        style: pw.TextStyle(color: PdfColors.red)),
                  if (_patient!.phone.isNotEmpty)
                    pw.Text('Telephone: ${_patient!.phone}'),
                  if (_patient!.emergencyContact.isNotEmpty)
                    pw.Text("Contact d'urgence: ${_patient!.emergencyContact}"),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Text('OBSERVATIONS MEDICALES',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ..._files.map((file) => pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 10),
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor(0.85, 0.85, 0.85)),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(file.interventionType,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(file.createdAt ?? DateTime.now())}',
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text('Observation: ${file.observation}'),
                      if (file.description.isNotEmpty)
                        pw.Text('Description: ${file.description}'),
                    ],
                  ),
                )),

            pw.SizedBox(height: 20),

            if (_vitalSigns.isNotEmpty) ...[
              pw.Text('SIGNAUX VITAUX',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColor(0.8, 0.8, 0.8)),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor(0.95, 0.95, 0.95)),
                    children: ['Date', 'T (C)', 'FC', 'TA', 'SpO2']
                        .map((h) => pw.Padding(
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))))
                        .toList(),
                  ),
                  ..._vitalSigns.take(10).map((v) => pw.TableRow(
                        children: [
                          pw.Padding(
                              padding: pw.EdgeInsets.all(6),
                              child: pw.Text(DateFormat('dd/MM').format(v.recordedAt ?? DateTime.now()), style: pw.TextStyle(fontSize: 10))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(6),
                              child: pw.Text('${v.temperature ?? "-"}', style: pw.TextStyle(fontSize: 10))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(6),
                              child: pw.Text('${v.heartRate ?? "-"}', style: pw.TextStyle(fontSize: 10))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(6),
                              child: pw.Text('${v.bloodPressureSystolic ?? "-"}/${v.bloodPressureDiastolic ?? "-"}',
                                  style: pw.TextStyle(fontSize: 10))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(6),
                              child: pw.Text('${v.oxygenSaturation ?? "-"}%', style: pw.TextStyle(fontSize: 10))),
                        ],
                      )),
                ],
              ),
            ],
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'dossier_${_patient!.firstName}_${_patient!.lastName}.pdf');
  }

  Future<void> _shareWhatsApp() async {
    if (_patient == null) return;

    String message = '*DOSSIER MEDICAL*\n';
    message += 'Patient: ${_patient!.fullName}\n';
    message += 'Groupe sanguin: ${_patient!.bloodType}\n';
    message += 'Allergies: ${_patient!.allergies.isNotEmpty ? _patient!.allergies.join(', ') : 'Aucune'}\n\n';

    if (_vitalSigns.isNotEmpty) {
      final latest = _vitalSigns.first;
      message += '*Derniers signaux vitaux:*\n';
      message += 'Temperature: ${latest.temperature}C\n';
      message += 'Frequence cardiaque: ${latest.heartRate} bpm\n';
      message += 'Tension: ${latest.bloodPressureSystolic}/${latest.bloodPressureDiastolic}\n';
      message += 'SpO2: ${latest.oxygenSaturation}%\n';
    }

    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showSnackBar('WhatsApp non disponible', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _observationCtrl.dispose();
    _interventionTypeCtrl.dispose();
    _descriptionCtrl.dispose();
    _temperatureCtrl.dispose();
    _heartRateCtrl.dispose();
    _bpSystolicCtrl.dispose();
    _bpDiastolicCtrl.dispose();
    _respiratoryRateCtrl.dispose();
    _oxygenSatCtrl.dispose();
    _vitalsNotesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    if (_patient == null) {
      return Scaffold(
        body: Center(child: Text('Patient non trouve')),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Dossier - ${_patient!.fullName}', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primary,
        foregroundColor: AppThemeController.isDark ? textHi : Colors.white,
        elevation: 0,
       actions: [
  IconButton(
    onPressed: _exportPDF,
    icon: Icon(Icons.picture_as_pdf),
    tooltip: 'Exporter PDF',
  ),
  IconButton(
    onPressed: _shareWhatsApp,
    icon: Icon(Icons.share),
    tooltip: 'Partager WhatsApp',
  ),
  // ← AJOUTER ICI
  IconButton(
    icon: Icon(Icons.assignment),
    tooltip: 'Fiche AVC',
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AvcRegistrationPage(patientId: widget.patientId),
      ),
    ),
  ),
],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primaryDk],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppThemeController.isDark ? textHi : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '${_patient!.firstName[0]}${_patient!.lastName[0]}',
                            style: TextStyle(color: AppThemeController.isDark ? textHi : Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_patient!.fullName,
                                style: TextStyle(color: AppThemeController.isDark ? textHi : Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            if (_patient!.bloodType.isNotEmpty)
                              Text('Groupe sanguin: ${_patient!.bloodType}',
                                  style: TextStyle(color: AppThemeController.isDark ? textHi : Colors.white.withOpacity(0.9), fontSize: 14)),
                            if (_patient!.dateOfBirth != null)
                              Text('Ne(e) le ${DateFormat('dd/MM/yyyy').format(_patient!.dateOfBirth!)}',
                                  style: TextStyle(color: AppThemeController.isDark ? textHi : Colors.white.withOpacity(0.9), fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_patient!.allergies.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 12),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: AppThemeController.isDark ? textHi : Colors.white, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('Allergies: ${_patient!.allergies.join(', ')}',
                                style: TextStyle(color: AppThemeController.isDark ? textHi : Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Vital Signs
            _buildSection(
              title: 'Signaux Vitaux',
              icon: Icons.monitor_heart,
              iconColor: Colors.red,
              onAdd: () => setState(() => _showVitalsForm = !_showVitalsForm),
            ),

            if (_showVitalsForm) _buildVitalsForm(),

            _vitalSigns.isEmpty
                ? _buildEmptyState('Aucun signaux vitaux enregistres')
                : Column(
                    children: _vitalSigns.map((vital) => _buildVitalSignsCard(vital)).toList(),
                  ),

            SizedBox(height: 20),

            // Medical Files
            _buildSection(
              title: 'Observations Medicales',
              icon: Icons.folder_open,
              iconColor: primary,
              onAdd: () => setState(() => _showFileForm = !_showFileForm),
            ),

            if (_showFileForm) _buildFileForm(),

            _files.isEmpty
                ? _buildEmptyState('Aucune observation enregistree')
                : Column(
                    children: _files.map((file) => _buildFileCard(file)).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onAdd,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            SizedBox(width: 10),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textHi)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: Icon(Icons.add, size: 18),
          label: Text('Ajouter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: AppThemeController.isDark ? textHi : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppThemeController.isDark ? textHi : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignsCard(VitalSigns vital) {
    final isCritical = vital.isCritical;

    return Container(
      margin: EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppThemeController.isDark ? textHi : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical ? Colors.red[300]! : Colors.grey[200]!,
          width: isCritical ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(vital.recordedAt ?? DateTime.now()),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (isCritical)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Text('CRITIQUE',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildVitalItem(
                    'T',
                    '${vital.temperature ?? "-"} C',
                    vital.temperature != null && vital.temperature! > 38.5 ? Colors.red : primary,
                  ),
                ),
                Expanded(
                  child: _buildVitalItem(
                    'FC',
                    '${vital.heartRate ?? "-"} bpm',
                    vital.heartRate != null && vital.heartRate! > 100 ? Colors.red : primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildVitalItem(
                    'TA',
                    '${vital.bloodPressureSystolic ?? "-"}/${vital.bloodPressureDiastolic ?? "-"}',
                    vital.bloodPressureSystolic != null && vital.bloodPressureSystolic! > 140 ? Colors.red : primary,
                  ),
                ),
                Expanded(
                  child: _buildVitalItem(
                    'SpO2',
                    '${vital.oxygenSaturation ?? "-"}%',
                    vital.oxygenSaturation != null && vital.oxygenSaturation! < 95 ? Colors.red : primary,
                  ),
                ),
              ],
            ),
            if (vital.notes.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Notes: ${vital.notes}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalItem(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFileCard(MedicalFile file) {
    return Container(
      margin: EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppThemeController.isDark ? textHi : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.description, color: primary, size: 22),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(file.interventionType,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textHi)),
                            Text(
                              DateFormat('dd/MM/yyyy').format(file.createdAt ?? DateTime.now()),
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteFile(file.id!),
                  icon: Icon(Icons.delete_outline, color: Colors.red, size: 22),
                ),
              ],
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Observation:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  SizedBox(height: 4),
                  Text(file.observation, style: TextStyle(fontSize: 14)),
                  if (file.description.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text('Description:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    SizedBox(height: 4),
                    Text(file.description, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsForm() {
    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemeController.isDark ? textHi : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nouveaux signaux vitaux',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textHi)),
              IconButton(
                onPressed: () => setState(() => _showVitalsForm = false),
                icon: Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _buildVitalInput('Temperature (C)', _temperatureCtrl, keyboardType: TextInputType.number)),
              SizedBox(width: 12),
              Expanded(child: _buildVitalInput('FC (bpm)', _heartRateCtrl, keyboardType: TextInputType.number)),
            ],
          ),
          SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _buildVitalInput('TA Systolique', _bpSystolicCtrl, keyboardType: TextInputType.number)),
              SizedBox(width: 12),
              Expanded(child: _buildVitalInput('TA Diastolique', _bpDiastolicCtrl, keyboardType: TextInputType.number)),
            ],
          ),
          SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _buildVitalInput('FR (/min)', _respiratoryRateCtrl, keyboardType: TextInputType.number)),
              SizedBox(width: 12),
              Expanded(child: _buildVitalInput('SpO2 (%)', _oxygenSatCtrl, keyboardType: TextInputType.number)),
            ],
          ),
          SizedBox(height: 12),

          _buildVitalInput('Notes', _vitalsNotesCtrl, maxLines: 2),
          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveVitals,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: AppThemeController.isDark ? textHi : Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showVitalsForm = false),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Annuler'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalInput(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFileForm() {
    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemeController.isDark ? textHi : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nouvelle observation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textHi)),
              IconButton(
                onPressed: () => setState(() => _showFileForm = false),
                icon: Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          SizedBox(height: 16),

          _buildVitalInput("Type d'intervention", _interventionTypeCtrl),
          SizedBox(height: 12),

          _buildVitalInput('Observation', _observationCtrl, maxLines: 3),
          SizedBox(height: 12),

          _buildVitalInput('Description', _descriptionCtrl, maxLines: 3),
          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: AppThemeController.isDark ? textHi : Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showFileForm = false),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Annuler'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


