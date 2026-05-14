import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme_controller.dart';
import 'medical_files_page.dart';
import 'avc_registration_page.dart';

final supabase = Supabase.instance.client;

class PatientsPage extends StatefulWidget {
  final bool isSelectMode;// false = gérer patients / true = choisir un patient
 
  final VoidCallback? onBack; 

  PatientsPage({super.key, this.isSelectMode = false, this.onBack});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  static Color get bg        => AppThemeController.color(Color(0xFF0D2B22), Color(0xFFF4F8F6));
  static Color get primary   => AppThemeController.color(Color(0xFF4CAF92), Color(0xFF1D7D63));
  static Color get primaryDk => AppThemeController.color(Color(0xFF2E7D64), Color(0xFF14634E));
  static Color get textHi    => AppThemeController.color(Color(0xFFFFFFFF), Color(0xFF10241D));
  static Color get textMid   => AppThemeController.color(Color(0x99FFFFFF), Color(0xAA10241D));
  static Color get textLow   => AppThemeController.color(Color(0x44FFFFFF), Color(0x6610241D));
  static Color get glass     => AppThemeController.color(Color(0x0FFFFFFF), Color(0xDFFFFFFF));
  static Color get glassBdr  => AppThemeController.color(Color(0x1AFFFFFF), Color(0x263E6B5A));
  static Color get accentBdr => AppThemeController.color(Color(0x3A4CAF92), Color(0x553D9B7B));
  static Color get blue      => AppThemeController.color(Color(0xFF64B5F6), Color(0xFF1976D2));
  static Color amber     = Color(0xFFFFA726);
  static Color errorRed  = Color(0xFFEF5350);

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await supabase
          .from('patients')
          .select()
          .eq('doctor_id', userId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _patients  = List<Map<String, dynamic>>.from(data);
          _filtered  = _patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Erreur: $e', isError: true);
      }
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _patients // pas de filtre → tout afficher
          : _patients.where((p) {
              final full = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.toLowerCase();
              return full.contains(q);
            }).toList();
    });
  }

  String _fullName(Map<String, dynamic> p) {
    final fn   = (p['first_name'] ?? '').toString().trim();
    final ln   = (p['last_name']  ?? '').toString().trim();
    final full = '$fn $ln'.trim();
    return full.isEmpty ? 'Patient' : full;
  }

  String _initials(Map<String, dynamic> p) {
    final fn = (p['first_name'] ?? '').toString().trim();
    final ln = (p['last_name']  ?? '').toString().trim();
    if (fn.isNotEmpty && ln.isNotEmpty) return '${fn[0]}${ln[0]}'.toUpperCase();
    if (fn.isNotEmpty) return fn[0].toUpperCase();
    return '?';
  }

  Color _avatarColor(int index) {
    final colors = [primary, blue, amber, Color(0xFFCE93D8)];
    return colors[index % colors.length];
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) age--;
    return age;
  }

  String _ageFromDob(dynamic dobRaw) {
    if (dobRaw == null) return '';
    try {
      return '${_calculateAge(DateTime.parse(dobRaw.toString()))} ans';
    } catch (_) {
      return '';
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: Colors.white)),
      backgroundColor: isError ? errorRed : primaryDk,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _mapDbError(PostgrestException e) {
    final code = e.code ?? '';
    if (code == '23505') return 'Ce patient existe déjà';
    if (code == '23502') {
      final match = RegExp(r'column "(\w+)"').firstMatch(e.message);
      return 'Champ requis: ${match?.group(1) ?? '?'}';
    }
    if (code == '42501') return 'Accès refusé — vérifiez les règles RLS Supabase';
    return 'Erreur DB [${e.code}]: ${e.message}';
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> _deletePatient(Map<String, dynamic> patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer le patient',
            style: TextStyle(color: textHi, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Voulez-vous vraiment supprimer ${_fullName(patient)} ? Cette action est irréversible.',
          style: TextStyle(color: textMid, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: Color(0xFF4CAF92))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: TextStyle(color: Color(0xFFEF5350))),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await supabase.from('patients').delete().eq('id', patient['id']);
      await _loadPatients();
      if (mounted) _showSnackBar('${_fullName(patient)} supprimé(e)');
    } catch (e) {
      if (mounted) _showSnackBar('Erreur: $e', isError: true);
    }
  }

  // ── BOTTOM SHEET AJOUT / ÉDITION ──────────────────────────────────────────
  void _showPatientForm({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;  // ← null = nouveau / objet = édition

    final firstNameCtrl = TextEditingController(text: existing?['first_name'] ?? '');
    final lastNameCtrl  = TextEditingController(text: existing?['last_name']  ?? '');
    final phoneCtrl     = TextEditingController(text: existing?['phone']      ?? '');
    final emailCtrl     = TextEditingController(text: existing?['email']      ?? '');
    final emergencyCtrl = TextEditingController(text: existing?['emergency_contact'] ?? '');

    DateTime? dateOfBirth;
    if (existing?['date_of_birth'] != null) {
      try { dateOfBirth = DateTime.parse(existing!['date_of_birth']); } catch (_) {}
    }

    String  gender        = existing?['gender']         ?? 'Homme';
    String  maritalStatus = existing?['marital_status'] ?? 'Célibataire';
    String? profession    = existing?['profession'];
    bool    saving        = false;
    String? errorMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: glassBdr, width: 1),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: EdgeInsets.symmetric(vertical: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: glassBdr, borderRadius: BorderRadius.circular(4)),
                ),

                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: Row(children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: primary.withOpacity(0.25), width: 1),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit_outlined : Icons.person_add_outlined,
                        color: primary, size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      isEdit ? 'Modifier le patient' : 'Nouveau patient',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textHi),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: glass,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: glassBdr),
                        ),
                        child: Icon(Icons.close, color: textMid, size: 16),
                      ),
                    ),
                  ]),
                ),
                Container(height: 1, color: glassBdr),
                SizedBox(height: 16),

                // Erreur
                if (errorMsg != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: errorRed.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: errorRed.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: errorRed, size: 16),
                        SizedBox(width: 8),
                        Expanded(child: Text(errorMsg!,
                            style: TextStyle(color: errorRed, fontSize: 12))),
                      ]),
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Prénom + Nom
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _sheetLabel('PRÉNOM *'),
                          SizedBox(height: 6),
                          _sheetField(firstNameCtrl, 'Ex: Ahmed', Icons.person_outline_rounded),
                        ])),
                        SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _sheetLabel('NOM *'),
                          SizedBox(height: 6),
                          _sheetField(lastNameCtrl, 'Ex: Mansouri', Icons.person_outline_rounded),
                        ])),
                      ]),
                      SizedBox(height: 14),

                      _sheetLabel('TÉLÉPHONE'),
                      SizedBox(height: 6),
                      _sheetField(phoneCtrl, '+216 XX XXX XXX', Icons.phone_outlined,
                          keyboardType: TextInputType.phone),
                      SizedBox(height: 14),

                      _sheetLabel('EMAIL (optionnel)'),
                      SizedBox(height: 6),
                      _sheetField(emailCtrl, 'patient@email.com', Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress),
                      SizedBox(height: 14),

                      // Sexe + Statut marital
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _sheetLabel('SEXE'),
                          SizedBox(height: 6),
                          _sheetDropdown(
                            value: gender,
                            items: ['Homme', 'Femme'],
                            onChanged: (v) => setSheet(() => gender = v!),
                          ),
                        ])),
                        SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _sheetLabel('STATUT MARITAL'),
                          SizedBox(height: 6),
                          _sheetDropdown(
                            value: maritalStatus,
                            items: ['Célibataire', 'Marié(e)', 'Divorcé(e)', 'Veuf/Veuve'],
                            onChanged: (v) => setSheet(() => maritalStatus = v!),
                          ),
                        ])),
                      ]),
                      SizedBox(height: 14),

                      // Date naissance
                      _sheetLabel('DATE DE NAISSANCE'),
                      SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: dateOfBirth ?? DateTime(1980),
                            firstDate: DateTime(1920),
                            lastDate: DateTime.now(),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: AppThemeController.isDark
                                    ? ColorScheme.dark(primary: primary, surface: bg, onSurface: textHi)
                                    : ColorScheme.light(primary: primary, surface: Colors.white, onSurface: textHi),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) setSheet(() => dateOfBirth = picked);
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppThemeController.color(Colors.white.withOpacity(0.04), Colors.black.withOpacity(0.04)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: glassBdr, width: 1),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Row(children: [
                            Icon(Icons.calendar_today_outlined,
                                color: primary.withOpacity(0.65), size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                dateOfBirth != null
                                    ? '${dateOfBirth!.day.toString().padLeft(2, '0')}/${dateOfBirth!.month.toString().padLeft(2, '0')}/${dateOfBirth!.year}'
                                    : 'JJ/MM/AAAA',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: dateOfBirth != null ? textHi : textLow),
                              ),
                            ),
                            if (dateOfBirth != null)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: accentBdr, width: 1),
                                ),
                                child: Text(
                                  '${_calculateAge(dateOfBirth!)} ans',
                                  style: TextStyle(
                                      color: primary, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                          ]),
                        ),
                      ),
                      SizedBox(height: 14),

                      // Profession
                      _sheetLabel('PROFESSION'),
                      SizedBox(height: 6),
                      _sheetDropdown(
                        value: profession,
                        hint: 'Sélectionner...',
                        items: [
                          'Étudiant(e)', 'Salarié(e)', 'Indépendant(e)',
                          'Fonctionnaire', 'Retraité(e)', 'Sans emploi', 'Autre'
                        ],
                        onChanged: (v) => setSheet(() => profession = v),
                      ),
                      SizedBox(height: 14),

                      _sheetLabel('CONTACT D\'URGENCE (optionnel)'),
                      SizedBox(height: 6),
                      _sheetField(emergencyCtrl, 'Nom + téléphone', Icons.emergency_outlined),
                      SizedBox(height: 22),

                      // Bouton Enregistrer
                      GestureDetector(
                        onTap: saving ? null : () async {
                          if (firstNameCtrl.text.trim().isEmpty ||
                              lastNameCtrl.text.trim().isEmpty) {
                            setSheet(() => errorMsg = 'Le prénom et le nom sont obligatoires');
                            return;
                          }
                          setSheet(() { saving = true; errorMsg = null; });
                          try {
                            final userId = supabase.auth.currentUser?.id;
                            if (userId == null) {
                              setSheet(() {
                                saving   = false;
                                errorMsg = 'Session expirée, reconnectez-vous';
                              });
                              return;
                            }

                            final Map<String, dynamic> payload = {
                              'first_name'    : firstNameCtrl.text.trim(),
                              'last_name'     : lastNameCtrl.text.trim(),
                              'gender'        : gender,
                              'marital_status': maritalStatus,
                            };

                            final phone = phoneCtrl.text.trim();
                            if (phone.isNotEmpty) payload['phone'] = phone;

                            final email = emailCtrl.text.trim();
                            if (email.isNotEmpty) payload['email'] = email;

                            final emergency = emergencyCtrl.text.trim();
                            if (emergency.isNotEmpty) payload['emergency_contact'] = emergency;

                            if (dateOfBirth != null) {
                              payload['date_of_birth'] =
                                  '${dateOfBirth!.year}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}';
                            }

                            if (profession != null && profession!.isNotEmpty) {
                              payload['profession'] = profession;
                            }

                            if (isEdit) {
                              await supabase.from('patients').update(payload).eq('id', existing!['id']);
                            } else {
                              payload['doctor_id'] = userId;
                              await supabase.from('patients').insert(payload);
                            }

                            if (ctx.mounted) Navigator.pop(ctx);
                            await _loadPatients();
                            if (mounted) {
                              _showSnackBar(
                                '${firstNameCtrl.text.trim()} ${lastNameCtrl.text.trim()} '
                                '${isEdit ? 'modifié(e)' : 'enregistré(e)'} ✓',
                              );
                            }
                          } on PostgrestException catch (e) {
                            setSheet(() { saving = false; errorMsg = _mapDbError(e); });
                          } catch (e) {
                            setSheet(() { saving = false; errorMsg = 'Erreur: ${e.toString()}'; });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: saving
                                ? LinearGradient(colors: [
                                    primaryDk.withOpacity(0.5),
                                    Color(0xFF1B4D3E).withOpacity(0.5)
                                  ])
                                : LinearGradient(
                                    colors: [primaryDk, Color(0xFF1B4D3E)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            border: Border.all(color: accentBdr, width: 1),
                          ),
                          child: Center(
                            child: saving
                                ? SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5))
                                : Text(
                                    isEdit
                                        ? 'ENREGISTRER LES MODIFICATIONS'
                                        : 'ENREGISTRER LE PATIENT',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 2),
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── WIDGETS HELPERS ───────────────────────────────────────────────────────
  Widget _sheetLabel(String text) => Text(
        text,
        style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w700,
            color: primary, letterSpacing: 2),
      );

  Widget _sheetField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppThemeController.color(Colors.white.withOpacity(0.04), Colors.black.withOpacity(0.04)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glassBdr, width: 1),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: TextStyle(color: textHi, fontSize: 14),
        cursorColor: primary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: textLow, fontSize: 13),
          prefixIcon: Icon(icon, color: primary.withOpacity(0.65), size: 18),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _sheetDropdown({
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? hint,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppThemeController.color(Colors.white.withOpacity(0.04), Colors.black.withOpacity(0.04)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glassBdr),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
              dropdownColor: AppThemeController.color(Color(0xFF183D2E), Color(0xFFFFFFFF)),
          style: TextStyle(color: textHi, fontSize: 13),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: primary.withOpacity(0.7)),
          isExpanded: true,
          hint: hint != null
              ? Text(hint, style: TextStyle(color: textLow, fontSize: 13))
              : null,
          items: items.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/medicine.png',
              fit: BoxFit.cover,
              color: Color.fromARGB(255, 48, 67, 61).withOpacity(0.50),
              colorBlendMode: BlendMode.srcOver,
            ),
          ),
          Positioned.fill(child: Container(color: bg.withOpacity(0.88))),
          Positioned(top: -80, right: -80,
              child: _glowCircle(220, primary.withOpacity(0.10))),

          Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: glass,
                  border: Border(bottom: BorderSide(color: glassBdr, width: 1)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(22, 14, 22, 0),
                        child: Row(
                          children: [
                            // ✅ FIX: utilise onBack si disponible, sinon Navigator.pop
                            GestureDetector(
                              onTap: () {
                                if (widget.onBack != null) {
                                  widget.onBack!();
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                              child: Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                  color: glass,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: glassBdr),
                                ),
                                child: Icon(Icons.arrow_back_ios_new_rounded,
                                    color: textMid, size: 15),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.isSelectMode ? 'Dossiers médicaux' : 'Mes patients',
                                    style: TextStyle(
                                        fontSize: 19, fontWeight: FontWeight.w800, color: textHi),
                                  ),
                                  Text(
                                    widget.isSelectMode
                                        ? 'Sélectionnez un patient'
                                        : '${_filtered.length} patient${_filtered.length > 1 ? 's' : ''}',
                                    style: TextStyle(fontSize: 11, color: primary.withOpacity(0.7)),
                                  ),
                                ],
                              ),
                            ),
                            if (!widget.isSelectMode)
                              GestureDetector(
                                onTap: () => _showPatientForm(),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [primaryDk, Color(0xFF1B4D3E)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(color: accentBdr, width: 1),
                                  ),
                                  child: Row(children: [
                                    Icon(Icons.add, color: Colors.white, size: 15),
                                    SizedBox(width: 5),
                                    Text('Ajouter', style: TextStyle(
                                        color: Colors.white, fontSize: 12,
                                        fontWeight: FontWeight.w700, letterSpacing: .5)),
                                  ]),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Search bar
                      Padding(
                        padding: EdgeInsets.fromLTRB(22, 12, 22, 14),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppThemeController.color(Colors.white.withOpacity(0.04), Colors.black.withOpacity(0.04)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: glassBdr, width: 1),
                          ),
                          child: Row(children: [
                            SizedBox(width: 14),
                            Icon(Icons.search_rounded,
                                color: primary.withOpacity(0.65), size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                style: TextStyle(color: textHi, fontSize: 13),
                                cursorColor: primary,
                                decoration: InputDecoration(
                                  hintText: 'Rechercher un patient...',
                                  hintStyle: TextStyle(color: textLow, fontSize: 13),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Liste patients ───────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: primary))
                    : _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline, color: textLow, size: 52),
                                SizedBox(height: 12),
                                Text('Aucun patient trouvé',
                                    style: TextStyle(color: textMid, fontSize: 15)),
                                SizedBox(height: 6),
                                Text(
                                  widget.isSelectMode
                                      ? 'Ajoutez des patients d\'abord'
                                      : 'Appuyez sur + Ajouter',
                                  style: TextStyle(color: textLow, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.fromLTRB(22, 16, 22, 30),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) {
                              final p    = _filtered[i];
                              final name = _fullName(p);
                              final age  = _ageFromDob(p['date_of_birth']);
                              final prof = (p['profession'] ?? '').toString();
                              final subtitle =
                                  [age, prof].where((s) => s.isNotEmpty).join(' · ');
                              final col = _avatarColor(i);

                              return GestureDetector(
                                onTap: () {
                                  if (widget.isSelectMode) {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => AvcRegistrationPage(
                                          patientId: p['id'].toString()),
                                    ));
                                  } else {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => MedicalFilesPage(
                                          patientId: p['id'].toString()),
                                    ));
                                  }
                                },
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 10),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: glass,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: widget.isSelectMode ? accentBdr : glassBdr,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(children: [
                                    // Avatar
                                    Container(
                                      width: 46, height: 46,
                                      decoration: BoxDecoration(
                                        color: col.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color: col.withOpacity(0.25), width: 1),
                                      ),
                                      child: Center(
                                        child: Text(_initials(p),
                                            style: TextStyle(
                                                color: col,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800)),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    // Nom + sous-titre
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name,
                                              style: TextStyle(
                                                  color: textHi,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700)),
                                          if (subtitle.isNotEmpty) ...[
                                            SizedBox(height: 3),
                                            Text(subtitle,
                                                style: TextStyle(
                                                    color: textLow, fontSize: 11)),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Actions (mode Patients uniquement)
                                    if (!widget.isSelectMode) ...[
                                      GestureDetector(
                                        onTap: () => _showPatientForm(existing: p),
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: primary.withOpacity(0.10),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                                color: primary.withOpacity(0.25), width: 1),
                                          ),
                                          child: Icon(Icons.edit_outlined,
                                              color: primary, size: 16),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _deletePatient(p),
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: errorRed.withOpacity(0.10),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                                color: errorRed.withOpacity(0.25), width: 1),
                                          ),
                                          child: Icon(Icons.delete_outline,
                                              color: errorRed, size: 16),
                                        ),
                                      ),
                                    ],

                                    // Badge dossier (mode Dossiers)
                                    if (widget.isSelectMode) ...[
                                      SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: blue.withOpacity(0.10),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                              color: blue.withOpacity(0.25), width: 1),
                                        ),
                                        child: Icon(Icons.folder_open_outlined,
                                            color: blue, size: 16),
                                      ),
                                    ],
                                  ]),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

