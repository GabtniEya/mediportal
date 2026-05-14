import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme_controller.dart';
import 'login_page.dart';

final supabase = Supabase.instance.client;

class ProfilePage extends StatefulWidget {
  // ✅ FIX: onBack callback pour éviter Navigator.pop() qui vide la pile
  final VoidCallback? onBack;
  ProfilePage({super.key, this.onBack});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _doctorData;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving  = false;

  int _patientCount = 0;
  int _fileCount    = 0;
  int _pendingCount = 0;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  static Color get bg        => AppThemeController.color(Color(0xFF0D2B22), Color(0xFFF4F8F6));
  static Color get surface   => AppThemeController.color(Color(0xFF132E24), Color(0xFFFFFFFF));
  static Color get card      => AppThemeController.color(Color(0xFF0F2620), Color(0xFFFFFFFF));
  static Color get primary   => AppThemeController.color(Color(0xFF4CAF92), Color(0xFF1D7D63));
  static Color get primaryDk => AppThemeController.color(Color(0xFF2E7D64), Color(0xFF14634E));
  static Color get textHi    => AppThemeController.color(Color(0xFFFFFFFF), Color(0xFF10241D));
  static Color get textMid   => AppThemeController.color(Color(0x99FFFFFF), Color(0xAA10241D));
  static Color get textLow   => AppThemeController.color(Color(0x44FFFFFF), Color(0x6610241D));
  static Color get glass     => AppThemeController.color(Color(0x0AFFFFFF), Color(0xDFFFFFFF));
  static Color get glassBdr  => AppThemeController.color(Color(0x1AFFFFFF), Color(0x263E6B5A));
  static Color get accentBdr => AppThemeController.color(Color(0x3A4CAF92), Color(0x553D9B7B));
  static Color get accent    => AppThemeController.color(Color(0xFFB3CFE5), Color(0xFF3E6B5A));
  static Color get green     => AppThemeController.color(Color(0xFF4CAF92), Color(0xFF1D7D63));
  static Color orange    = Color(0xFFFFA726);
  static Color red       = Color(0xFFEF5350);

  final _prenomCtrl    = TextEditingController();
  final _nomCtrl       = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _specialtyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _loadProfile();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _specialtyCtrl.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      Map<String, dynamic>? data;
      List patients = [];
      List files    = [];
      List pending  = [];

      try {
        data = await supabase
            .from('doctors')
            .select()
            .eq('id', userId)
            .maybeSingle();
      } catch (e) { debugPrint('doctors error: $e'); }

      try {
        patients = await supabase
            .from('patients')
            .select('id')
            .eq('doctor_id', userId);
      } catch (e) { debugPrint('❌ patients error: $e'); }

      try {
        files = await supabase
            .from('avc_records')
            .select('id')
            .eq('doctor_id', userId);
      } catch (e) { debugPrint('❌ avc_records error: $e'); }

      try {
        pending = await supabase
            .from('avc_records')
            .select('id')
            .eq('doctor_id', userId)
            .isFilter('date_avc', null);
      } catch (e) { debugPrint('❌ pending error: $e'); }

      if (mounted) {
        setState(() {
          _doctorData   = data;
          _patientCount = patients.length;
          _fileCount    = files.length;
          _pendingCount = pending.length;
          _isLoading    = false;
        });

        if (data != null) {
          final parts = (data['full_name'] ?? '').toString().split(' ');
          _prenomCtrl.text    = parts.isNotEmpty ? parts.first : '';
          _nomCtrl.text       = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          _emailCtrl.text     = data['email']     ?? '';
          _phoneCtrl.text     = data['phone']     ?? '';
          _specialtyCtrl.text = data['specialty'] ?? '';
        }
      }
    } catch (e) {
      debugPrint('❌ _loadProfile global error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final userId   = supabase.auth.currentUser?.id;
      final fullName = '${_prenomCtrl.text.trim()} ${_nomCtrl.text.trim()}';
      await supabase.from('doctors').update({
        'full_name' : fullName,
        'phone'     : _phoneCtrl.text.trim(),
        'specialty' : _specialtyCtrl.text.trim(),
      }).eq('id', userId!);
      if (mounted) {
        setState(() { _isEditing = false; _isSaving = false; });
        _showSnack('Profil mis à jour ✓');
        _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnack('Erreur : $e', isError: true);
      }
    }
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (mounted)
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => LoginPage()));
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: Colors.white)),
      backgroundColor: isError ? red : primaryDk,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [
        Positioned(top: -80, right: -80,
            child: _glowCircle(260, primary.withOpacity(0.12))),
        Positioned(bottom: 80, left: -60,
            child: _glowCircle(200, primaryDk.withOpacity(0.10))),
        _isLoading
            ? Center(child: CircularProgressIndicator(color: primary))
            : FadeTransition(
                opacity: _fadeAnim,
                child: CustomScrollView(
                  physics: BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildStatStrip()),
                    SliverToBoxAdapter(child: _buildFormCard()),
                    SliverToBoxAdapter(child: _buildAccountCard()),
                    SliverToBoxAdapter(child: _buildMenuCard()),
                    SliverToBoxAdapter(child: _buildLogoutBtn()),
                    SliverToBoxAdapter(child: _buildRgpd()),
                    SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final name = _doctorData?['full_name'] ?? 'Médecin';
    final spec = _doctorData?['specialty'] ?? '';

    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: glassBdr)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          SizedBox(height: 8),
          Row(children: [
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
                padding: EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppThemeController.color(Colors.white.withOpacity(0.05), Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: glassBdr),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: textMid, size: 16),
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: _isEditing ? _saveProfile
                  : () => setState(() => _isEditing = true),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _isEditing ? primary : primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentBdr),
                ),
                child: Row(children: [
                  _isSaving
                      ? SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Icon(
                          _isEditing ? Icons.check_rounded : Icons.edit_outlined,
                          color: _isEditing ? Colors.white : accent,
                          size: 14),
                  SizedBox(width: 6),
                  Text(
                    _isEditing ? 'Enregistrer' : 'Modifier',
                    style: TextStyle(
                      color: _isEditing ? Colors.white : accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]),
              ),
            ),
          ]),
          SizedBox(height: 24),
          Stack(children: [
            Container(
              width: 84, height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withOpacity(0.12),
                border: Border.all(color: primary.withOpacity(0.4), width: 2.5),
              ),
              child: Icon(Icons.person_rounded, color: primary, size: 42),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary,
                  border: Border.all(color: surface, width: 2),
                ),
                child: Icon(Icons.check_rounded, color: Colors.white, size: 12),
              ),
            ),
          ]),
          SizedBox(height: 14),
          Text('Dr. $name',
              style: TextStyle(
                  color: textHi, fontSize: 20, fontWeight: FontWeight.w800)),
          if (spec.isNotEmpty) ...[
            SizedBox(height: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentBdr),
              ),
              child: Text(spec,
                  style: TextStyle(
                      color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
      ),
    );
  }

  // ── Stat Strip ────────────────────────────────────────────────────────────
  Widget _buildStatStrip() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: glassBdr),
        ),
        child: Row(children: [
          Expanded(child: _statItem('$_patientCount', 'Patients', primary)),
          Container(width: 1, height: 44, color: glassBdr),
          Expanded(child: _statItem('$_fileCount', 'Dossiers AVC', primary)),
          Container(width: 1, height: 44, color: glassBdr),
          Expanded(child: _statItem('$_pendingCount', 'En attente', orange)),
        ]),
      ),
    );
  }

  Widget _statItem(String val, String label, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Column(children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 800),
          curve: Curves.easeOut,
          builder: (_, t, __) => Opacity(
            opacity: t,
            child: Text(val,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          ),
        ),
        SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 10, color: textMid)),
      ]),
    );
  }

  // ── Form Card ────────────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: glassBdr),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('INFORMATIONS PERSONNELLES'),
            SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildField('PRÉNOM', _prenomCtrl,
                  Icons.person_outline_rounded, enabled: _isEditing)),
              SizedBox(width: 12),
              Expanded(child: _buildField('NOM', _nomCtrl,
                  Icons.person_outline_rounded, enabled: _isEditing)),
            ]),
            SizedBox(height: 14),
            _buildField('EMAIL', _emailCtrl,
                Icons.mail_outline_rounded, enabled: false),
            SizedBox(height: 14),
            _buildField('TÉLÉPHONE', _phoneCtrl,
                Icons.phone_outlined, enabled: _isEditing),
            SizedBox(height: 14),
            _buildField('SPÉCIALITÉ', _specialtyCtrl,
                Icons.medical_information_outlined, enabled: _isEditing),
          ],
        ),
      ),
    );
  }

  // ── Account Card ─────────────────────────────────────────────────────────
  Widget _buildAccountCard() {
    final email   = _doctorData?['email']
        ?? supabase.auth.currentUser?.email
        ?? '';
    final shortId = (supabase.auth.currentUser?.id ?? '')
        .substring(0, 8)
        .toUpperCase();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('COMPTE'),
          SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: card.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: glassBdr),
            ),
            child: Column(children: [
              _infoRow(Icons.badge_outlined, 'ID Médecin', shortId),
              Divider(color: glassBdr, height: 1),
              _infoRow(Icons.email_outlined, 'Email de connexion', email),
              Divider(color: glassBdr, height: 1),
              _infoRow(Icons.verified_outlined, 'Statut',
                  '● Vérifié · Actif', valueColor: green),
              Divider(color: glassBdr, height: 1),
              _infoRow(Icons.calendar_today_outlined,
                  'Membre depuis', 'Janvier 2024'),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Menu Card ────────────────────────────────────────────────────────────
  Widget _buildMenuCard() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('PARAMÈTRES'),
          SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: card.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: glassBdr),
            ),
            child: Column(children: [
              _menuRow(
                icon: Icons.lock_outline_rounded,
                iconColor: primary,
                title: 'Sécurité & mot de passe',
                subtitle: 'Changer le mot de passe',
                onTap: () {},
              ),
              Divider(color: glassBdr, height: 1),
              _menuRow(
                icon: Icons.notifications_none_rounded,
                iconColor: primary,
                title: 'Notifications',
                subtitle: 'Rappels et alertes',
                onTap: () {},
              ),
              Divider(color: glassBdr, height: 1),
              _menuRow(
                icon: Icons.security_outlined,
                iconColor: orange,
                title: 'Confidentialité RGPD',
                subtitle: 'Gérer vos données',
                onTap: () {},
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Widget _buildLogoutBtn() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: _signOut,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: red.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: red, size: 18),
              SizedBox(width: 10),
              Text('Se déconnecter',
                  style: TextStyle(
                      color: red, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  // ── RGPD ──────────────────────────────────────────────────────────────────
  Widget _buildRgpd() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Text(
        'Conforme RGPD  ·  Données chiffrées  ·  Support 24/7',
        style: TextStyle(fontSize: 10, color: textLow, letterSpacing: 0.5),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── Reusable Widgets ──────────────────────────────────────────────────────
  Widget _buildField(String label, TextEditingController ctrl, IconData icon,
      {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: primary, letterSpacing: 2)),
        SizedBox(height: 6),
        AnimatedContainer(
          duration: Duration(milliseconds: 200),
          height: 46,
          decoration: BoxDecoration(
            color: enabled
                ? AppThemeController.color(Colors.white.withOpacity(0.07), Colors.black.withOpacity(0.07))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
                color: enabled ? primary.withOpacity(0.4) : glassBdr),
          ),
          child: TextField(
            controller: ctrl,
            enabled: enabled,
            style: TextStyle(color: textHi, fontSize: 13),
            cursorColor: primary,
            decoration: InputDecoration(
              prefixIcon: Icon(icon,
                  color: enabled ? primary : textLow, size: 16),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 10, vertical: 14),
              hintStyle: TextStyle(color: textLow),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: primary, size: 16),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 10, color: textMid)),
              Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? textHi)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textHi)),
                Text(subtitle,
                    style: TextStyle(fontSize: 11, color: textMid)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: textLow, size: 18),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: accent,
            letterSpacing: 2.5));
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

