import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme_controller.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

final supabase = Supabase.instance.client;


class _P { //classe pour palette 
  static Color get bg       => AppThemeController.color(Color(0xFF0D2B22), Color(0xFFF4F8F6));
  static Color get surface  => AppThemeController.color(Color(0xFF132E24), Color(0xFFFFFFFF));
  static Color get primary  => AppThemeController.color(Color(0xFF4CAF92), Color(0xFF1D7D63));
  static Color get primDk   => AppThemeController.color(Color(0xFF2E7D64), Color(0xFF14634E));
  static Color get textHi   => AppThemeController.color(Color(0xFFFFFFFF), Color(0xFF10241D));
  static Color get textMid  => AppThemeController.color(Color(0x99FFFFFF), Color(0xAA10241D));
  static Color get textLow  => AppThemeController.color(Color(0x44FFFFFF), Color(0x6610241D));
  static Color get glass    => AppThemeController.color(Color(0x0FFFFFFF), Color(0xDFFFFFFF));
  static Color get glassBdr => AppThemeController.color(Color(0x1AFFFFFF), Color(0x263E6B5A));
  static Color get accentBdr=> AppThemeController.color(Color(0x3A4CAF92), Color(0x553D9B7B));
  static Color danger   = Color(0xFFB71C1C);
  static Color warn     = Color(0xFFFF8F00);
}

// ─────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────
class AvcRecord { //Modèle de données pour un enregistrement AVC, avec méthode toJson() pour la base de données. 
  String? patientNom;
  String? patientPrenom;
  int?    patientAge;
  String? patientSexe;
  String? origine;
  String? statutSocial;
  int?    scoreMrs;
  bool   hypertension      = false;
  bool   diabete           = false;
  bool   avcAnterieur      = false;
  bool   fibrillationAuric = false;
  bool   dyslipidemie      = false;
  List<String> traitements = [];
  DateTime?  dateAvc;
  TimeOfDay? heureAvc;
  String?    transport;
  int?       delaiMinutes;
  String? typeAvc;
  double? glycemie;
  int?    paSystolique;
  int?    paDiastolique;
  int?    scoreNihss;
  int?    scoreGlasgow;
  String? typeImagerie;
  bool    occlusion    = false;
  int?    scoreAspects;
  String? territoire;
  bool       thrombolyse     = false;
  String?    medicament;
  bool       thrombectomie   = false;
  TimeOfDay? heureIntervention;
  bool       anticoagulation = false;
  bool       antiagregation  = false;
  int?    nihssFin;
  int?    nihss24h;
  int?    nihssSortie;
  int?    dureeHospitalisation;
  String? destination;
  bool    deces      = false;
  String? causeDeces;
  String? notes;

  Map<String, dynamic> toJson(String patientId, String doctorId) => {
    'patient_id':             patientId,
    'doctor_id':              doctorId,
    'patient_nom':            patientNom,
    'patient_prenom':         patientPrenom,
    'patient_age':            patientAge,
    'patient_sexe':           patientSexe,
    'origine':                origine,
    'statut_social':          statutSocial,
    'score_mrs':              scoreMrs,
    'hypertension':           hypertension,
    'diabete':                diabete,
    'avc_anterieur':          avcAnterieur,
    'fibrillation_auric':     fibrillationAuric,
    'dyslipidemie':           dyslipidemie,
    'traitements':            traitements,
    'type_avc':               typeAvc,
    'date_avc':               dateAvc?.toIso8601String(),
    'heure_avc':              heureAvc != null
        ? '${heureAvc!.hour.toString().padLeft(2,'0')}:${heureAvc!.minute.toString().padLeft(2,'0')}'
        : null,
    'transport':              transport,
    'delai_minutes':          delaiMinutes,
    'glycemie':               glycemie,
    'pa_systolique':          paSystolique,
    'pa_diastolique':         paDiastolique,
    'score_nihss':            scoreNihss,
    'score_glasgow':          scoreGlasgow,
    'type_imagerie':          typeImagerie,
    'occlusion':              occlusion,
    'score_aspects':          scoreAspects,
    'territoire':             territoire,
    'thrombolyse':            thrombolyse,
    'medicament':             medicament,
    'thrombectomie':          thrombectomie,
    'heure_intervention':     heureIntervention != null
        ? '${heureIntervention!.hour.toString().padLeft(2,'0')}:${heureIntervention!.minute.toString().padLeft(2,'0')}'
        : null,
    'anticoagulation':        anticoagulation,
    'antiagregation':         antiagregation,
    'nihss_fin':              nihssFin,
    'nihss_24h':              nihss24h,
    'nihss_sortie':           nihssSortie,
    'duree_hospitalisation':  dureeHospitalisation,
    'destination':            destination,
    'deces':                  deces,
    'cause_deces':            causeDeces,
    'notes':                  notes,
    'created_at':             DateTime.now().toIso8601String(),
  };
}

// ─────────────────────────────────────────────────────────────────
// PDF GENERATOR
// ─────────────────────────────────────────────────────────────────
class AvcPdfGenerator {
  static Future<Uint8List> generate(AvcRecord r, String patientId) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.notoSansRegular(),
        bold: await PdfGoogleFonts.notoSansBold(),
      ),
    );
    final primaryColor = PdfColor.fromHex('#0D47A1');
    final lightBlue    = PdfColor.fromHex('#E8EEF9');
    final grayText     = PdfColor.fromHex('#555555');
    final borderColor  = PdfColor.fromHex('#CFD8DC');

    pw.Widget header() => pw.Container(
      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#0D47A1')),
      padding: pw.EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('FICHE AVC', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            pw.SizedBox(height: 4),
            pw.Text('Accident Vasculaire Cérébral – Dossier Patient',
                style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#BBDEFB'))),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('N° Patient : $patientId', style: pw.TextStyle(fontSize: 9, color: PdfColors.white)),
            pw.SizedBox(height: 4),
            pw.Text('Créé le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#BBDEFB'))),
          ]),
        ],
      ),
    );

    pw.Widget sectionTitle(String title, {PdfColor? color}) => pw.Container(
      margin: pw.EdgeInsets.only(top: 14, bottom: 6),
      padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: color ?? lightBlue,
        border: pw.Border(left: pw.BorderSide(color: primaryColor, width: 3)),
      ),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor)),
    );

    pw.Widget rowItem(String label, String? value, {bool highlight = false}) => pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: highlight ? PdfColor.fromHex('#FFF8E1') : PdfColors.white,
        border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: grayText)),
          pw.Text(value ?? '—', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold,
              color: value != null ? PdfColors.black : PdfColor.fromHex('#AAAAAA'))),
        ],
      ),
    );

    pw.Widget boolRow(String label, bool value) => rowItem(label, value ? 'Oui ✓' : 'Non', highlight: value);
    pw.Widget grid2(List<pw.Widget> children) => pw.Row(
      children: children.map((c) => pw.Expanded(child: pw.Padding(padding: pw.EdgeInsets.only(right: 6), child: c))).toList(),
    );

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(0),
      header: (_) => header(),
      footer: (ctx) => pw.Container(
        padding: pw.EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: borderColor))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Document confidentiel – Usage médical uniquement', style: pw.TextStyle(fontSize: 8, color: grayText)),
            pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}', style: pw.TextStyle(fontSize: 8, color: grayText)),
          ],
        ),
      ),
      build: (ctx) => [
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            if (r.patientNom != null || r.patientPrenom != null) ...[
              sectionTitle('IDENTITÉ DU PATIENT'),
              grid2([rowItem('Nom', r.patientNom), rowItem('Prénom', r.patientPrenom)]),
              grid2([rowItem('Âge', r.patientAge != null ? '${r.patientAge} ans' : null), rowItem('Sexe', r.patientSexe)]),
            ],
            sectionTitle('1. DONNÉES ÉPIDÉMIOLOGIQUES'),
            grid2([rowItem('Origine', r.origine), rowItem('Statut social', r.statutSocial)]),
            grid2([rowItem('Type AVC', r.typeAvc), rowItem('Score mRS (initial)', r.scoreMrs?.toString())]),
            sectionTitle('2. ANTÉCÉDENTS MÉDICAUX'),
            grid2([boolRow('Hypertension artérielle', r.hypertension), boolRow('Diabète', r.diabete)]),
            grid2([boolRow('AVC antérieur', r.avcAnterieur), boolRow('Fibrillation auriculaire', r.fibrillationAuric)]),
            boolRow('Dyslipidémie', r.dyslipidemie),
            if (r.traitements.isNotEmpty) rowItem('Traitements', r.traitements.join(', ')),
            sectionTitle('3. PHASE PRÉ-HOSPITALIÈRE'),
            grid2([
              rowItem('Date AVC', r.dateAvc != null ? DateFormat('dd/MM/yyyy').format(r.dateAvc!) : null),
              rowItem('Heure AVC', r.heureAvc != null ? '${r.heureAvc!.hour.toString().padLeft(2,'0')}:${r.heureAvc!.minute.toString().padLeft(2,'0')}' : null),
            ]),
            grid2([rowItem('Moyen de transport', r.transport), rowItem('Délai arrivée', r.delaiMinutes != null ? '${r.delaiMinutes} min' : null, highlight: (r.delaiMinutes ?? 999) > 270)]),
            sectionTitle('4. PARAMÈTRES CLINIQUES'),
            grid2([rowItem('Glycémie', r.glycemie != null ? '${r.glycemie} mg/dL' : null), rowItem('PA', r.paSystolique != null ? '${r.paSystolique}/${r.paDiastolique} mmHg' : null)]),
            grid2([rowItem('NIHSS (initial)', r.scoreNihss?.toString(), highlight: (r.scoreNihss ?? 0) > 15), rowItem('Glasgow', r.scoreGlasgow?.toString(), highlight: (r.scoreGlasgow ?? 15) < 9)]),
            sectionTitle('5. IMAGERIE'),
            grid2([rowItem('Type imagerie', r.typeImagerie), boolRow('Occlusion', r.occlusion)]),
            grid2([rowItem('Score ASPECTS', r.scoreAspects?.toString()), rowItem('Territoire', r.territoire)]),
            sectionTitle('6. TRAITEMENT'),
            boolRow('Thrombolyse', r.thrombolyse),
            if (r.thrombolyse) rowItem('Médicament', r.medicament),
            boolRow('Thrombectomie mécanique', r.thrombectomie),
            if (r.thrombectomie && r.heureIntervention != null)
              rowItem('Heure intervention', '${r.heureIntervention!.hour.toString().padLeft(2,'0')}:${r.heureIntervention!.minute.toString().padLeft(2,'0')}'),
            grid2([boolRow('Anticoagulation', r.anticoagulation), boolRow('Antiagrégation', r.antiagregation)]),
            sectionTitle('7. ÉVOLUTION', color: r.deces ? PdfColor.fromHex('#FFEBEE') : null),
            pw.Row(children: [
              pw.Expanded(child: rowItem('NIHSS fin intervention', r.nihssFin?.toString())),
              pw.Expanded(child: rowItem('NIHSS à 24h', r.nihss24h?.toString())),
              pw.Expanded(child: rowItem('NIHSS sortie', r.nihssSortie?.toString())),
            ]),
            grid2([rowItem('Durée hospitalisation', r.dureeHospitalisation != null ? '${r.dureeHospitalisation} jours' : null), rowItem('Destination sortie', r.destination)]),
            boolRow('Décès', r.deces),
            if (r.deces && r.causeDeces != null) rowItem('Cause du décès', r.causeDeces, highlight: true),
            if (r.notes != null && r.notes!.isNotEmpty) ...[
              sectionTitle('NOTES CLINIQUES'),
              pw.Container(
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FAFAFA'), borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)), border: pw.Border.all(color: borderColor)),
                child: pw.Text(r.notes!, style: pw.TextStyle(fontSize: 10, color: grayText)),
              ),
            ],
            pw.SizedBox(height: 20),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              pw.Container(
                width: 200, padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor), borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
                child: pw.Column(children: [
                  pw.Text('Signature du médecin', style: pw.TextStyle(fontSize: 9, color: grayText)),
                  pw.SizedBox(height: 40),
                  pw.Container(height: 1, color: borderColor),
                  pw.SizedBox(height: 4),
                  pw.Text('Date : _______________', style: pw.TextStyle(fontSize: 9, color: grayText)),
                ]),
              ),
            ]),
          ]),
        ),
      ],
    ));
    return pdf.save();
  }
}

// ─────────────────────────────────────────────────────────────────
// SHARE SERVICE
// ─────────────────────────────────────────────────────────────────
class AvcShareService {
  static const MethodChannel _shareChannel = MethodChannel('mediportal/share');

  static String _fileName(String patientId) {
    final cleanPatientId =
        patientId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return 'fiche_avc_${cleanPatientId}_$stamp';
  }

  static Future<String> _savePdfTemp(Uint8List bytes, String patientId) async {
    final dir  = await getTemporaryDirectory();
    final cleanPatientId =
        patientId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${dir.path}/fiche_avc_$cleanPatientId.pdf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static Future<String?> downloadPdf(Uint8List bytes, String patientId) async {
    final name = _fileName(patientId);
    try {
      final Object? savedPath = await FileSaver.instance.saveFile(
        name: name,
        bytes: bytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      final path = savedPath?.toString();
      if (path != null && path.isNotEmpty) return path;
    } catch (_) {
      // Fallback below keeps the PDF export usable if the platform save dialog fails.
    }

    Directory? dir;
    try {
      dir = await getDownloadsDirectory();
    } catch (_) {
      dir = null;
    }
    dir ??= await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Future<void> shareFile(Uint8List bytes, String patientId) async {
    final path = await _savePdfTemp(bytes, patientId);
    await Share.shareXFiles([XFile(path, mimeType: 'application/pdf')],
        subject: 'Fiche AVC – Patient $patientId',
        text: 'Veuillez trouver ci-joint la fiche AVC du patient $patientId.');
  }

  static String _summaryMessage(String patientId, AvcRecord r) {
    return 'Fiche AVC - Résumé\n\n'
        'Patient : $patientId\n'
        'Date AVC : ${r.dateAvc != null ? DateFormat('dd/MM/yyyy').format(r.dateAvc!) : '-'}\n'
        'Type : ${r.typeAvc ?? '-'}\n'
        'NIHSS initial : ${r.scoreNihss?.toString() ?? '-'}\n'
        'Thrombolyse : ${r.thrombolyse ? 'Oui' : 'Non'}\n'
        'Thrombectomie : ${r.thrombectomie ? 'Oui' : 'Non'}\n\n'
        'Le PDF complet du patient est joint à ce message.';
  }

  static Future<void> sharePdfWithMessage(
    Uint8List bytes,
    String patientId,
    AvcRecord r, {
    required String subject,
  }) async {
    final path = await _savePdfTemp(bytes, patientId);
    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/pdf', name: 'fiche_avc_$patientId.pdf')],
      subject: subject,
      text: _summaryMessage(patientId, r),
    );
  }

  static Future<void> sendWhatsAppPdf(
    Uint8List bytes,
    String patientId,
    AvcRecord r,
  ) async {
    final text = _summaryMessage(patientId, r);

    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'fiche_avc_$patientId.pdf',
      );
      final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final path = await _savePdfTemp(bytes, patientId);

    if (Platform.isAndroid) {
      await _shareChannel.invokeMethod('sendWhatsAppPdf', {
        'path': path,
        'text': text,
      });
      return;
    }

    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/pdf', name: 'fiche_avc_$patientId.pdf')],
      subject: 'Fiche AVC - Patient $patientId',
      text: text,
    );
  }

  static Future<void> openWhatsApp(String patientId, AvcRecord r) async {
    final message = Uri.encodeComponent(
      '🏥 *Fiche AVC – Résumé*\n\n'
      '👤 Patient : $patientId\n'
      '📅 Date AVC : ${r.dateAvc != null ? DateFormat('dd/MM/yyyy').format(r.dateAvc!) : '—'}\n'
      '🧠 Type : ${r.typeAvc ?? '—'}\n'
      '📊 NIHSS initial : ${r.scoreNihss?.toString() ?? '—'}\n'
      '💊 Thrombolyse : ${r.thrombolyse ? 'Oui' : 'Non'}\n'
      '🔧 Thrombectomie : ${r.thrombectomie ? 'Oui' : 'Non'}\n\n'
      '_Document PDF complet disponible._',
    );
    final url = Uri.parse('https://wa.me/?text=$message');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  static Future<void> sendEmail(Uint8List bytes, String patientId, AvcRecord r) async {
    final subject = 'Fiche AVC - Patient $patientId';
    final text = _summaryMessage(patientId, r);

    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'fiche_avc_$patientId.pdf',
      );
      final url = Uri(
        scheme: 'mailto',
        queryParameters: {
          'subject': subject,
          'body': text,
        },
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final path = await _savePdfTemp(bytes, patientId);

    if (Platform.isAndroid) {
      await _shareChannel.invokeMethod('sendEmailPdf', {
        'path': path,
        'subject': subject,
        'text': text,
      });
      return;
    }

    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/pdf', name: 'fiche_avc_$patientId.pdf')],
      subject: subject,
      text: text,
    );
  }

  static Future<void> printPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}

// ─────────────────────────────────────────────────────────────────
// VALIDATION
// ─────────────────────────────────────────────────────────────────
class _Validator {
  static List<String> validate(AvcRecord r) {
    final errors = <String>[];
    if (r.typeAvc      == null) errors.add('Type d\'AVC non renseigné');
    if (r.dateAvc      == null) errors.add('Date de l\'AVC manquante');
    if (r.heureAvc     == null) errors.add('Heure de l\'AVC manquante');
    if (r.scoreNihss   == null) errors.add('Score NIHSS initial manquant');
    if (r.typeImagerie == null) errors.add('Type d\'imagerie non renseigné');
    return errors;
  }
}

// ─────────────────────────────────────────────────────────────────
// PAGE PRINCIPALE
// ─────────────────────────────────────────────────────────────────
class AvcRegistrationPage extends StatefulWidget {
  final String patientId;
  AvcRegistrationPage({super.key, required this.patientId});

  @override
  State<AvcRegistrationPage> createState() => _AvcRegistrationPageState();
}

class _AvcRegistrationPageState extends State<AvcRegistrationPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int  _currentStep = 0;
  bool _isSaving    = false;
  bool _isDirty     = false;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;

  final AvcRecord _record = AvcRecord();

  final _nomCtrl            = TextEditingController();
  final _prenomCtrl         = TextEditingController();
  final _ageCtrl            = TextEditingController();
  final _delaiCtrl          = TextEditingController();
  final _glycemieCtrl       = TextEditingController();
  final _paSystCtrl         = TextEditingController();
  final _paDialCtrl         = TextEditingController();
  final _nihssCtrl          = TextEditingController();
  final _glasgowCtrl        = TextEditingController();
  final _aspectsCtrl        = TextEditingController();
  final _medicamentCtrl     = TextEditingController();
  final _nihssFinCtrl       = TextEditingController();
  final _nihss24hCtrl       = TextEditingController();
  final _nihssSortieCtrl    = TextEditingController();
  final _dureeHospiCtrl     = TextEditingController();
  final _causeDecesCtrl     = TextEditingController();
  final _notesCtrl          = TextEditingController();

  final List<String> _allTraitements = [
    'Antihypertenseurs', 'Antidiabétiques', 'Anticoagulants',
    'Antiplaquettaires', 'Statines', 'Autre',
  ];

  final List<Map<String, dynamic>> _steps = [ //navigation 7 étapes
    {'title': 'Identité & Épidémio',    'icon': Icons.people_alt_outlined},
    {'title': 'Antécédents médicaux',   'icon': Icons.medical_services_outlined},
    {'title': 'Phase pré-hospitalière', 'icon': Icons.local_hospital_outlined},
    {'title': 'Paramètres cliniques',   'icon': Icons.monitor_heart_outlined},
    {'title': 'Imagerie',               'icon': Icons.image_search},
    {'title': 'Traitement',             'icon': Icons.medication_outlined},
    {'title': 'Évolution & Notes',      'icon': Icons.trending_up},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    for (final c in _allControllers) {
      c.addListener(() => setState(() => _isDirty = true));
    }
  }

  List<TextEditingController> get _allControllers => [
    _nomCtrl, _prenomCtrl, _ageCtrl, _delaiCtrl, _glycemieCtrl,
    _paSystCtrl, _paDialCtrl, _nihssCtrl, _glasgowCtrl, _aspectsCtrl,
    _medicamentCtrl, _nihssFinCtrl, _nihss24hCtrl, _nihssSortieCtrl,
    _dureeHospiCtrl, _causeDecesCtrl, _notesCtrl,
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _animController.dispose();
    for (final c in _allControllers) c.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _currentStep = step);
    _pageCtrl.animateToPage(step,
        duration: Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  void _syncTextFields() { //les synchronise avant toute sauvegarde ou export 
    _record.patientNom           = _nomCtrl.text.trim().isEmpty          ? null : _nomCtrl.text.trim();
    _record.patientPrenom        = _prenomCtrl.text.trim().isEmpty        ? null : _prenomCtrl.text.trim();
    _record.patientAge           = int.tryParse(_ageCtrl.text);
    _record.delaiMinutes         = int.tryParse(_delaiCtrl.text);
    _record.glycemie             = double.tryParse(_glycemieCtrl.text);
    _record.paSystolique         = int.tryParse(_paSystCtrl.text);
    _record.paDiastolique        = int.tryParse(_paDialCtrl.text);
    _record.scoreNihss           = int.tryParse(_nihssCtrl.text);
    _record.scoreGlasgow         = int.tryParse(_glasgowCtrl.text);
    _record.scoreAspects         = int.tryParse(_aspectsCtrl.text);
    _record.medicament           = _medicamentCtrl.text.trim().isEmpty    ? null : _medicamentCtrl.text.trim();
    _record.nihssFin             = int.tryParse(_nihssFinCtrl.text);
    _record.nihss24h             = int.tryParse(_nihss24hCtrl.text);
    _record.nihssSortie          = int.tryParse(_nihssSortieCtrl.text);
    _record.dureeHospitalisation = int.tryParse(_dureeHospiCtrl.text);
    _record.causeDeces           = _causeDecesCtrl.text.trim().isEmpty    ? null : _causeDecesCtrl.text.trim();
    _record.notes                = _notesCtrl.text.trim().isEmpty         ? null : _notesCtrl.text.trim();
  }

  Future<Uint8List> _buildPdf() async {
    _syncTextFields();
    return AvcPdfGenerator.generate(_record, widget.patientId);
  }

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExportBottomSheet(
        onPdf: () async {
          Navigator.pop(context);
          try {
            final b = await _buildPdf();
            final path = await AvcShareService.downloadPdf(b, widget.patientId);
            if (!mounted) return;
            _showSnack(
              path == null || path.isEmpty
                  ? 'PDF téléchargé avec succès'
                  : 'PDF téléchargé avec succès : $path',
            );
          } catch (e) {
            if (mounted) {
              _showSnack('Échec du téléchargement PDF : $e', isError: true);
            }
          }
        },
        onPrint: () async {
          Navigator.pop(context);
          final b = await _buildPdf();
          await AvcShareService.printPdf(b);
        },
        onEmail: () async {
          Navigator.pop(context);
          try {
            final b = await _buildPdf();
            await AvcShareService.sendEmail(b, widget.patientId, _record);
          } catch (e) {
            if (mounted) _showSnack('Envoi e-mail impossible : $e', isError: true);
          }
        },
        onWhatsApp: () async {
          Navigator.pop(context);
          try {
            final b = await _buildPdf();
            await AvcShareService.sendWhatsAppPdf(b, widget.patientId, _record);
          } catch (e) {
            if (mounted) _showSnack('Envoi WhatsApp impossible : $e', isError: true);
          }
        },
      ),
    );
  }

  Future<void> _submit() async {
    _syncTextFields();
    final errors = _Validator.validate(_record);
    if (errors.isNotEmpty) { _showValidationDialog(errors); return; }
    await _submitCore();
  }

  Future<void> _submitCore() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _isSaving = true);
    try {
      await supabase.from('avc_records').insert(_record.toJson(widget.patientId, userId));
      if (mounted) { setState(() => _isDirty = false); _showSnack('Dossier AVC enregistré ✓'); _showPostSaveDialog(); }
    } catch (e) {
      if (mounted) _showSnack('Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showValidationDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _P.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: _P.warn.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.warning_amber_rounded, color: _P.warn, size: 20),
              ),
              SizedBox(width: 12),
              Text('Champs manquants', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _P.textHi)),
            ]),
            SizedBox(height: 16),
            ...errors.map((e) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Container(width: 5, height: 5, decoration: BoxDecoration(color: _P.warn, shape: BoxShape.circle)),
                SizedBox(width: 10),
                Expanded(child: Text(e, style: TextStyle(fontSize: 13, color: _P.textMid))),
              ]),
            )),
            SizedBox(height: 20),
            Row(children: [
              Expanded(child: _darkOutlineBtn('Corriger', () => Navigator.pop(context))),
              SizedBox(width: 10),
              Expanded(child: _darkPrimaryBtn('Forcer', () { Navigator.pop(context); _submitCore(); })),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showPostSaveDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _P.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(color: _P.primary.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, color: _P.primary, size: 28),
            ),
            SizedBox(height: 14),
            Text('Dossier enregistré !', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _P.textHi)),
            SizedBox(height: 6),
            Text('Souhaitez-vous exporter la fiche PDF ?', style: TextStyle(fontSize: 13, color: _P.textMid), textAlign: TextAlign.center),
            SizedBox(height: 20),
            Row(children: [
              Expanded(child: _darkOutlineBtn('Fermer', () { Navigator.pop(context); Navigator.pop(context); })),
              SizedBox(width: 10),
              Expanded(child: _darkPrimaryBtn('Exporter', () { Navigator.pop(context); _showExportSheet(); })),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: isError ? _P.danger : _P.primDk,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true; // protection contre la perte de données
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _P.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Modifications non sauvegardées', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _P.textHi)),
            SizedBox(height: 8),
            Text('Voulez-vous quitter sans enregistrer ?', style: TextStyle(fontSize: 13, color: _P.textMid), textAlign: TextAlign.center),
            SizedBox(height: 20),
            Row(children: [
              Expanded(child: _darkOutlineBtn('Rester', () => Navigator.pop(context, false))),
              SizedBox(width: 10),
              Expanded(child: _darkDangerBtn('Quitter', () => Navigator.pop(context, true))),
            ]),
          ]),
        ),
      ),
    );
    return result ?? false;
  }

  int get _completionPercent {
    int filled = 0, total = 0;
    void check(dynamic v) { total++; if (v != null && v != false && v != '' && v != 0) filled++; }
    check(_record.typeAvc); check(_record.dateAvc); check(_record.heureAvc);
    check(_record.scoreNihss); check(_record.typeImagerie); check(_record.transport);
    check(_record.origine); check(_record.paSystolique); check(_record.scoreGlasgow);
    check(_record.nihss24h);
    return ((filled / total) * 100).round();
  }

  // ─── DESIGN HELPERS ──────────────────────────────────────────

  /// Glass card container — same as login form card
  Widget _glassCard({required Widget child, EdgeInsets? padding}) => Container(
    margin: EdgeInsets.only(bottom: 14),
    padding: padding ?? EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _P.glass,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _P.glassBdr, width: 1),
    ),
    child: child,
  );

  /// Section label inside card
  Widget _sectionLabel(String text) => Padding(
    padding: EdgeInsets.only(bottom: 14),
    child: Row(children: [
      Container(width: 3, height: 14, decoration: BoxDecoration(color: _P.primary, borderRadius: BorderRadius.circular(2))),
      SizedBox(width: 8),
      Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _P.primary, letterSpacing: 2)),
    ]),
  );

  /// Field label
  Widget _label(String text) => Padding(
    padding: EdgeInsets.only(bottom: 5),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _P.primary, letterSpacing: 1.5)),
  );

  /// Dark-themed text input
  Widget _inputField(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text, String? suffix, int maxLines = 1, String? hint}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        Container(
          height: maxLines > 1 ? null : 46,
          decoration: BoxDecoration(
            color: AppThemeController.color(Colors.white.withOpacity(0.04), Colors.black.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _P.glassBdr, width: 1),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            maxLines: maxLines,
            style: TextStyle(color: _P.textHi, fontSize: 14),
            cursorColor: _P.primary,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _P.textLow, fontSize: 13),
              suffixText: suffix,
              suffixStyle: TextStyle(color: _P.textMid, fontSize: 12),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ]);

  /// Chip group selector
  Widget _chipGroup(String label, List<String> options, String? selected, ValueChanged<String?> onSelect) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: options.map((o) {
            final isSelected = selected == o;
            return GestureDetector(
              onTap: () { setState(() => onSelect(isSelected ? null : o)); _isDirty = true; },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? _P.primary.withOpacity(0.18) : AppThemeController.color(Colors.white.withOpacity(0.04), Colors.black.withOpacity(0.04)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? _P.primary.withOpacity(0.6) : _P.glassBdr, width: isSelected ? 1.5 : 1),
                ),
                child: Text(o,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? _P.primary : _P.textMid,
                      letterSpacing: 0.3,
                    )),
              ),
            );
          }).toList(),
        ),
      ]);

  /// Toggle / Bool row
  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChange, {String? subtitle}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _P.textHi)),
          if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 11, color: _P.textMid)),
        ])),
        Transform.scale(
          scale: 0.85,
          child: Switch(
            value: value,
            onChanged: (v) { onChange(v); setState(() => _isDirty = true); },
            activeColor: _P.primary,
            activeTrackColor: _P.primary.withOpacity(0.3),
            inactiveThumbColor: _P.textLow,
            inactiveTrackColor: AppThemeController.color(Colors.white.withOpacity(0.08), Colors.black.withOpacity(0.08)),
          ),
        ),
      ]);

  /// Slider field
  Widget _sliderField(String label, int? value, int min, int max, ValueChanged<int> onChange, {String? hint}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: _label(label)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _P.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: _P.accentBdr)),
            child: Text('${value ?? min}', style: TextStyle(fontWeight: FontWeight.w800, color: _P.primary, fontSize: 14)),
          ),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _P.primary,
            inactiveTrackColor: AppThemeController.color(Colors.white.withOpacity(0.08), Colors.black.withOpacity(0.08)),
            thumbColor: _P.primary,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayColor: _P.primary.withOpacity(0.15),
            trackHeight: 3,
          ),
          child: Slider(
            value: (value ?? min).toDouble(),
            min: min.toDouble(), max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) { setState(() { onChange(v.round()); _isDirty = true; }); },
          ),
        ),
        if (hint != null) Padding(
          padding: EdgeInsets.only(top: 2, bottom: 4),
          child: Text(hint, style: TextStyle(fontSize: 10, color: _P.textLow, letterSpacing: 0.3)),
        ),
      ]);

  /// Date picker widget
  Widget _datePicker(String label, DateTime? value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: AppThemeController.color(Colors.white.withOpacity(0.04), Colors.black.withOpacity(0.04)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: value != null ? _P.accentBdr : _P.glassBdr, width: 1),
            ),
            child: Row(children: [
              SizedBox(width: 12),
              Icon(Icons.calendar_today_outlined, color: value != null ? _P.primary : _P.textLow, size: 16),
              SizedBox(width: 10),
              Text(
                value != null ? DateFormat('dd/MM/yyyy').format(value) : 'Sélectionner',
                style: TextStyle(color: value != null ? _P.textHi : _P.textLow, fontSize: 14),
              ),
            ]),
          ),
        ),
      ]);

  /// Time picker widget
  Widget _timePicker(String label, TimeOfDay? value, bool isIntervention) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        GestureDetector(
          onTap: () => _pickTime(isIntervention),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: AppThemeController.color(Colors.white.withOpacity(0.04), Colors.black.withOpacity(0.04)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: value != null ? _P.accentBdr : _P.glassBdr, width: 1),
            ),
            child: Row(children: [
              SizedBox(width: 12),
              Icon(Icons.access_time_outlined, color: value != null ? _P.primary : _P.textLow, size: 16),
              SizedBox(width: 10),
              Expanded(child: Text(
                value?.format(context) ?? 'Sélectionner',
                style: TextStyle(color: value != null ? _P.textHi : _P.textLow, fontSize: 14),
              )),
              if (value != null)
                GestureDetector(
                  onTap: () => setState(() {
                    if (isIntervention) _record.heureIntervention = null;
                    else _record.heureAvc = null;
                  }),
                  child: Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(Icons.close_rounded, color: _P.textLow, size: 16),
                  ),
                ),
            ]),
          ),
        ),
      ]);

  /// Alert banner (warning / danger)
  Widget _alertBanner(String text, {bool isDanger = false}) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: (isDanger ? _P.danger : _P.warn).withOpacity(0.10),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: (isDanger ? _P.danger : _P.warn).withOpacity(0.3), width: 1),
    ),
    child: Row(children: [
      Icon(isDanger ? Icons.error_outline : Icons.warning_amber_rounded,
          color: isDanger ? _P.danger : _P.warn, size: 15),
      SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(fontSize: 11, color: isDanger ? _P.danger : _P.warn, fontWeight: FontWeight.w500))),
    ]),
  );

  /// Primary dark button
  Widget _darkPrimaryBtn(String label, VoidCallback onTap, {bool isLoading = false}) =>
      GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(colors: [_P.primDk, Color(0xFF1B4D3E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border.all(color: _P.accentBdr, width: 1),
          ),
          child: Center(child: isLoading
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.5))),
        ),
      );

  /// Outline button
  Widget _darkOutlineBtn(String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _P.glassBdr, width: 1),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _P.textMid, letterSpacing: 1))),
        ),
      );

  /// Danger button
  Widget _darkDangerBtn(String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _P.danger.withOpacity(0.15),
            border: Border.all(color: _P.danger.withOpacity(0.4), width: 1),
          ),
          child: Center(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _P.danger.withOpacity(0.9), letterSpacing: 1))),
        ),
      );

  /// Divider for toggle rows
  Widget _darkDivider() => Divider(height: 20, color: _P.glassBdr);

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _record.dateAvc ?? DateTime.now(),
      firstDate: DateTime(2000), lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: AppThemeController.isDark
              ? ColorScheme.dark(primary: _P.primary, surface: _P.surface, onSurface: _P.textHi)
              : ColorScheme.light(primary: _P.primary, surface: _P.surface, onSurface: _P.textHi),
          dialogBackgroundColor: _P.surface,
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() { _record.dateAvc = d; _isDirty = true; });
  }

  Future<void> _pickTime(bool isIntervention) async {
    final t = await showTimePicker(
      context: context, initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: AppThemeController.isDark
              ? ColorScheme.dark(primary: _P.primary, surface: _P.surface, onSurface: _P.textHi)
              : ColorScheme.light(primary: _P.primary, surface: _P.surface, onSurface: _P.textHi),
          dialogBackgroundColor: _P.surface,
        ),
        child: child!,
      ),
    );
    if (t != null) {
      setState(() {
        if (isIntervention) _record.heureIntervention = t;
        else _record.heureAvc = t;
        _isDirty = true;
      });
    }
  }

  // ─── STEPS ────────────────────────────────────────────────────

  Widget _step1() => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
    child: Column(children: [
      _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('IDENTITÉ DU PATIENT'),
        Row(children: [
          Expanded(child: _inputField('NOM', _nomCtrl, hint: 'Facultatif')),
          SizedBox(width: 12),
          Expanded(child: _inputField('PRÉNOM', _prenomCtrl, hint: 'Facultatif')),
        ]),
        SizedBox(height: 14),
        Row(children: [
          Expanded(child: _inputField('ÂGE', _ageCtrl, type: TextInputType.number, suffix: 'ans')),
          SizedBox(width: 12),
          Expanded(child: _chipGroup('SEXE', ['Homme', 'Femme'], _record.patientSexe, (v) => setState(() => _record.patientSexe = v))),
        ]),
      ])),
      _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('DONNÉES ÉPIDÉMIOLOGIQUES'),
        _chipGroup('TYPE D\'AVC *', ['Ischémique', 'Hémorragique', 'AIT'], _record.typeAvc, (v) => setState(() => _record.typeAvc = v)),
        SizedBox(height: 16),
        _chipGroup('ORIGINE', ['Urbaine', 'Rurale'], _record.origine, (v) => setState(() => _record.origine = v)),
        SizedBox(height: 16),
        _chipGroup('STATUT SOCIAL', ['Actif', 'Retraité', 'Sans emploi'], _record.statutSocial, (v) => setState(() => _record.statutSocial = v)),
        SizedBox(height: 16),
        _sliderField('SCORE mRS INITIAL', _record.scoreMrs, 0, 5, (v) => setState(() => _record.scoreMrs = v), hint: '0 = normal  ·  5 = handicap sévère'),
      ])),
    ]),
  );

  Widget _step2() => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
    child: Column(children: [
      _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('ANTÉCÉDENTS MÉDICAUX'),
        _toggleRow('Hypertension artérielle', _record.hypertension, (v) => setState(() => _record.hypertension = v)),
        _darkDivider(),
        _toggleRow('Diabète', _record.diabete, (v) => setState(() => _record.diabete = v)),
        _darkDivider(),
        _toggleRow('AVC / AIT antérieur', _record.avcAnterieur, (v) => setState(() => _record.avcAnterieur = v)),
        _darkDivider(),
        _toggleRow('Fibrillation auriculaire', _record.fibrillationAuric, (v) => setState(() => _record.fibrillationAuric = v)),
        _darkDivider(),
        _toggleRow('Dyslipidémie', _record.dyslipidemie, (v) => setState(() => _record.dyslipidemie = v)),
      ])),
      _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('TRAITEMENTS EN COURS'),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _allTraitements.map((t) {
            final isSelected = _record.traitements.contains(t);
            return GestureDetector(
              onTap: () => setState(() {
                isSelected ? _record.traitements.remove(t) : _record.traitements.add(t);
                _isDirty = true;
              }),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? _P.primary.withOpacity(0.18) : AppThemeController.color(Colors.white.withOpacity(0.04), Colors.black.withOpacity(0.04)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? _P.primary.withOpacity(0.6) : _P.glassBdr, width: isSelected ? 1.5 : 1),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (isSelected) Icon(Icons.check_rounded, color: _P.primary, size: 12),
                  if (isSelected) SizedBox(width: 5),
                  Text(t, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? _P.primary : _P.textMid)),
                ]),
              ),
            );
          }).toList(),
        ),
      ])),
    ]),
  );

  Widget _step3() => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
    child: Column(children: [
      _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('PHASE PRÉ-HOSPITALIÈRE'),
        Row(children: [
          Expanded(child: _datePicker('DATE AVC *', _record.dateAvc)),
          SizedBox(width: 12),
          Expanded(child: _timePicker('HEURE AVC *', _record.heureAvc, false)),
        ]),
        SizedBox(height: 16),
        _chipGroup('MOYEN DE TRANSPORT', ['Ambulance', 'SMUR', 'Privé', 'Pompiers'], _record.transport, (v) => setState(() => _record.transport = v)),
        SizedBox(height: 16),
        _inputField('DÉLAI PATIENT–HÔPITAL', _delaiCtrl, type: TextInputType.number, suffix: 'min'),
        if (_delaiCtrl.text.isNotEmpty && (int.tryParse(_delaiCtrl.text) ?? 0) > 270) ...[
          SizedBox(height: 10),
          _alertBanner('Délai > 4h30 : fenêtre thrombolyse potentiellement dépassée'),
        ],
      ])),
    ]),
  );

  Widget _step4() => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
    child: Column(children: [
      _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('PARAMÈTRES CLINIQUES'),
        _inputField('GLYCÉMIE', _glycemieCtrl, type: TextInputType.numberWithOptions(decimal: true), suffix: 'mg/dL'),
        SizedBox(height: 14),
        Row(children: [
          Expanded(child: _inputField('PA SYSTOLIQUE', _paSystCtrl, type: TextInputType.number, suffix: 'mmHg')),
          SizedBox(width: 12),
          Expanded(child: _inputField('PA DIASTOLIQUE', _paDialCtrl, type: TextInputType.number, suffix: 'mmHg')),
        ]),
        SizedBox(height: 16),
        _sliderField('SCORE NIHSS * (gravité)', _record.scoreNihss, 0, 42, (v) => setState(() => _record.scoreNihss = v), hint: '0 = normal  ·  42 = déficit maximal'),
        SizedBox(height: 16),
        _sliderField('SCORE GLASGOW (conscience)', _record.scoreGlasgow, 3, 15, (v) => setState(() => _record.scoreGlasgow = v), hint: '3 = inconscient  ·  15 = normal'),
      ])),
      if ((_record.scoreNihss ?? 0) >= 16)
        _glassCard(child: _alertBanner('NIHSS ≥ 16 : AVC sévère — envisager thrombectomie urgente', isDanger: true)),
    ]),
  );

  Widget _step5() => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
    child: Column(children: [
      _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('IMAGERIE'),
        _chipGroup('TYPE D\'IMAGERIE *', ['TDM', 'IRM'], _record.typeImagerie, (v) => setState(() => _record.typeImagerie = v)),
        SizedBox(height: 16),
        _chipGroup('TERRITOIRE VASCULAIRE', ['ACM', 'ACA', 'ACP', 'Tronc basilaire'], _record.territoire, (v) => setState(() => _record.territoire = v)),
        SizedBox(height: 16),
        _toggleRow('Occlusion vasculaire détectée', _record.occlusion, (v) => setState(() => _record.occlusion = v)),
        SizedBox(height: 16),
        _sliderField('SCORE ASPECTS', _record.scoreAspects, 0, 10, (v) => setState(() => _record.scoreAspects = v), hint: '0 = ischémie étendue  ·  10 = normal'),
        if (((_record.scoreAspects ?? 10) < 6)) ...[
          SizedBox(height: 10),
          _alertBanner('ASPECTS < 6 : lésion étendue, risque hémorragique accru', isDanger: true),
        ],
      ])),
    ]),
  );

  Widget _step6() => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
    child: Column(children: [
      _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('TRAITEMENT AIGU'),
        _toggleRow('Thrombolyse IV', _record.thrombolyse, (v) => setState(() => _record.thrombolyse = v), subtitle: 'rt-PA / Alteplase'),
        if (_record.thrombolyse) ...[
          SizedBox(height: 14),
          _inputField('MÉDICAMENT', _medicamentCtrl, hint: 'Ex: Alteplase 0.9 mg/kg'),
        ],
        _darkDivider(),
        _toggleRow('Thrombectomie mécanique', _record.thrombectomie, (v) => setState(() => _record.thrombectomie = v), subtitle: 'Traitement endovasculaire'),
        if (_record.thrombectomie) ...[
          SizedBox(height: 14),
          _timePicker('HEURE D\'INTERVENTION', _record.heureIntervention, true),
        ],
      ])),
      _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('TRAITEMENT MÉDICAL'),
        _toggleRow('Anticoagulation', _record.anticoagulation, (v) => setState(() => _record.anticoagulation = v)),
        _darkDivider(),
        _toggleRow('Antiagrégation plaquettaire', _record.antiagregation, (v) => setState(() => _record.antiagregation = v)),
      ])),
    ]),
  );

  Widget _step7() => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
    child: Column(children: [
      _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('SCORES D\'ÉVOLUTION'),
        Row(children: [
          Expanded(child: _inputField('NIHSS FIN', _nihssFinCtrl, type: TextInputType.number, hint: '0-42')),
          SizedBox(width: 8),
          Expanded(child: _inputField('NIHSS 24H', _nihss24hCtrl, type: TextInputType.number, hint: '0-42')),
          SizedBox(width: 8),
          Expanded(child: _inputField('NIHSS SORTIE', _nihssSortieCtrl, type: TextInputType.number, hint: '0-42')),
        ]),
        SizedBox(height: 14),
        _inputField('DURÉE HOSPITALISATION', _dureeHospiCtrl, type: TextInputType.number, suffix: 'jours'),
      ])),
      _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('DESTINATION À LA SORTIE'),
        _chipGroup('DESTINATION', ['Domicile', 'Rééducation', 'EHPAD', 'Transfert'], _record.destination, (v) => setState(() => _record.destination = v)),
      ])),
      _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('ISSUE'),
        _toggleRow('Décès', _record.deces, (v) => setState(() => _record.deces = v)),
        if (_record.deces) ...[
          SizedBox(height: 14),
          _inputField('CAUSE DU DÉCÈS', _causeDecesCtrl, hint: 'Ex: engagement cérébral'),
          SizedBox(height: 10),
          _alertBanner('Décès enregistré dans ce dossier', isDanger: true),
        ],
      ])),
      _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('NOTES CLINIQUES'),
        _inputField('OBSERVATIONS', _notesCtrl, maxLines: 4, hint: 'Informations complémentaires...'),
      ])),

      // Complétude
      _glassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('COMPLÉTUDE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _P.primary, letterSpacing: 2)),
          Text('$_completionPercent%', style: TextStyle(fontWeight: FontWeight.w800, color: _P.primary, fontSize: 16)),
        ]),
        SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _completionPercent / 100,
            backgroundColor: AppThemeController.color(Colors.white.withOpacity(0.08), Colors.black.withOpacity(0.08)),
            valueColor: AlwaysStoppedAnimation(_completionPercent >= 70 ? _P.primary : _P.warn),
            minHeight: 6,
          ),
        ),
      ])),

      // Boutons finaux
      _darkPrimaryBtn(
        _isSaving ? 'ENREGISTREMENT...' : 'ENREGISTRER LE DOSSIER AVC',
        _isSaving ? () {} : _submit,
        isLoading: _isSaving,
      ),
      SizedBox(height: 10),
      _darkOutlineBtn('PRÉVISUALISER / EXPORTER PDF', _showExportSheet),
      SizedBox(height: 8),
    ]),
  );

  List<Widget> get _stepWidgets => [_step1(), _step2(), _step3(), _step4(), _step5(), _step6(), _step7()];

  // ─── STEPPER HEADER ──────────────────────────────────────────

  Widget _buildStepperHeader() => Container(
    height: 60,
    color: _P.bg,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: _steps.length,
      separatorBuilder: (_, __) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.chevron_right, color: _P.textLow, size: 14),
      ),
      itemBuilder: (_, i) {
        final isActive   = i == _currentStep;
        final isComplete = i < _currentStep;
        return GestureDetector(
          onTap: () => _goTo(i),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? _P.primary.withOpacity(0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isActive ? _P.accentBdr : isComplete ? _P.primary.withOpacity(0.3) : _P.glassBdr,
                width: 1,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                isComplete ? Icons.check_circle_outline_rounded : _steps[i]['icon'] as IconData,
                color: isActive ? _P.primary : isComplete ? _P.primary.withOpacity(0.7) : _P.textLow,
                size: 16,
              ),
              if (isActive) ...[
                SizedBox(width: 6),
                Text('${i + 1}', style: TextStyle(color: _P.primary, fontWeight: FontWeight.w800, fontSize: 11)),
              ],
            ]),
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: _P.bg,
        body: Stack(children: [
          // Glow décoratif
          Positioned(top: -100, right: -100, child: _glowCircle(280, _P.primary.withOpacity(0.07))),
          Positioned(bottom: 80, left: -80, child: _glowCircle(220, _P.primDk.withOpacity(0.08))),

          FadeTransition(
            opacity: _fadeAnim,
            child: Column(children: [
              // AppBar custom
              SafeArea(
                bottom: false,
                child: Container(
                  padding: EdgeInsets.fromLTRB(4, 8, 8, 0),
                  child: Row(children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: _P.textMid, size: 18),
                      onPressed: () async { if (await _onWillPop()) Navigator.pop(context); },
                    ),
                    // Logo + titre
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _P.primary.withOpacity(0.10),
                        border: Border.all(color: _P.accentBdr, width: 1),
                      ),
                      child: Icon(Icons.medical_services_outlined, color: _P.primary, size: 17),
                    ),
                    SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('FICHE AVC', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _P.textHi, letterSpacing: 2)),
                      Text('Patient : ${widget.patientId}', style: TextStyle(fontSize: 10, color: _P.textMid)),
                    ])),
                    IconButton(
                      icon: Icon(Icons.ios_share_rounded, color: _P.primary, size: 20),
                      tooltip: 'Exporter',
                      onPressed: _showExportSheet,
                    ),
                  ]),
                ),
              ),

              // Stepper
              _buildStepperHeader(),

              // Step indicator bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_P.primDk, Color(0xFF1B4D3E)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text('${_currentStep + 1}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
                  ),
                  SizedBox(width: 10),
                  Expanded(child: Text(_steps[_currentStep]['title'] as String,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _P.textHi))),
                  Text('${_currentStep + 1} / ${_steps.length}', style: TextStyle(fontSize: 11, color: _P.textMid)),
                ]),
              ),
              // Progress bar
              Container(
                height: 2,
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _steps.length,
                    backgroundColor: AppThemeController.color(Colors.white.withOpacity(0.08), Colors.black.withOpacity(0.08)),
                    valueColor: AlwaysStoppedAnimation(_P.primary),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: NeverScrollableScrollPhysics(),
                  children: _stepWidgets,
                ),
              ),

              // Navigation buttons
              Container(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 24),
                decoration: BoxDecoration(
                  color: _P.bg,
                  border: Border(top: BorderSide(color: _P.glassBdr, width: 1)),
                ),
                child: Row(children: [
                  if (_currentStep > 0) ...[
                    Expanded(child: _darkOutlineBtn('← PRÉCÉDENT', () => _goTo(_currentStep - 1))),
                    SizedBox(width: 12),
                  ],
                  if (_currentStep < _steps.length - 1)
                    Expanded(child: _darkPrimaryBtn('SUIVANT →', () => _goTo(_currentStep + 1))),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _glowCircle(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])),
  );
}

// ─────────────────────────────────────────────────────────────────
// EXPORT BOTTOM SHEET — Dark Medical Premium
// ─────────────────────────────────────────────────────────────────
class _ExportBottomSheet extends StatelessWidget {
  final VoidCallback onPdf;
  final VoidCallback onPrint;
  final VoidCallback onEmail;
  final VoidCallback onWhatsApp;

  _ExportBottomSheet({
    required this.onPdf,
    required this.onPrint,
    required this.onEmail,
    required this.onWhatsApp,
  });

  Widget _tile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0x1AFFFFFF), width: 1),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _P.textHi)),
          Text(subtitle, style: TextStyle(fontSize: 11, color: _P.textMid)),
        ])),
        Icon(Icons.arrow_forward_ios_rounded, size: 13, color: _P.textLow),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: _P.glassBdr, width: 1)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(height: 12),
        Container(width: 36, height: 3, decoration: BoxDecoration(color: _P.textLow, borderRadius: BorderRadius.circular(2))),
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Icon(Icons.ios_share_rounded, color: _P.primary, size: 18),
            SizedBox(width: 8),
            Text('EXPORTER LA FICHE AVC',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _P.primary, letterSpacing: 2)),
          ]),
        ),
        SizedBox(height: 12),
        _tile(icon: Icons.download_rounded,           color: Color(0xFFEF5350), title: 'Télécharger PDF',        subtitle: 'Enregistre la fiche sur l’appareil', onTap: onPdf),
        _tile(icon: Icons.print_outlined,             color: Color(0xFF78909C), title: 'Imprimer',              subtitle: 'Impression directe ou PDF virtuel',   onTap: onPrint),
        _tile(icon: Icons.email_outlined,             color: Color(0xFF42A5F5), title: 'Envoyer par e-mail',    subtitle: 'Ouvre l e-mail avec PDF joint',       onTap: onEmail),
        _tile(icon: Icons.chat_bubble_outline_rounded,color: Color(0xFF25D366), title: 'WhatsApp + PDF',        subtitle: 'Ouvre WhatsApp avec PDF joint',       onTap: onWhatsApp),
        SizedBox(height: 24),
      ]),
    );
  }
}


