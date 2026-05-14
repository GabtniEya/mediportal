import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../app_theme_controller.dart';
import 'patients_page.dart';
import 'login_page.dart';
import 'medical_files_page.dart';
import 'avc_registration_page.dart';
import 'profil_page.dart';

final supabase = Supabase.instance.client;

class DashboardPage extends StatefulWidget {
  DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _doctorData;  // profil du médecin connecté
  List<Map<String, dynamic>> _recentFiles = [];  // 5 derniers dossiers AVC
  int _patientCount = 0;
  int _fileCount    = 0;
  int _monthCount   = 0;
  int _pendingCount = 0;
  int _syncCount    = 0;
  bool _isLoading   = true;
  int _navIndex     = 0;

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay  = DateTime.now();

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
  static Color get green     => AppThemeController.color(Color(0xFF4CAF92), Color(0xFF1D7D63));
  static Color orange    = Color(0xFFFFA726);
  static Color blue      = Color(0xFF4A9ECC);
  static Color get accent    => AppThemeController.color(Color(0xFFB3CFE5), Color(0xFF3E6B5A));

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─── Data ─────────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final now   = DateTime.now();
      final start = DateTime(now.year, now.month, 1).toIso8601String();

      Map<String, dynamic>? doctor;
      List patients  = [];
      List files     = [];
      List monthly   = [];
      List pending   = [];
      List synced    = [];
      List recentRaw = [];

      try {
        doctor = await supabase.from('doctors').select().eq('id', userId).maybeSingle();
      } catch (e) { debugPrint('doctors error: $e'); }

      try {
        patients = await supabase.from('patients').select('id').eq('doctor_id', userId);
      } catch (e) { debugPrint(' patients error: $e'); }

      try {
        files = await supabase.from('avc_records').select('id').eq('doctor_id', userId);
      } catch (e) { debugPrint(' avc_records error: $e'); }

      try {
        monthly = await supabase
            .from('avc_records')
            .select('id')
            .eq('doctor_id', userId)
            .gte('created_at', start);
      } catch (e) { debugPrint(' monthly error: $e'); }

      try {
        pending = await supabase
            .from('avc_records')
            .select('id')
            .eq('doctor_id', userId)
            .isFilter('date_avc', null);
      } catch (e) { debugPrint(' pending error: $e'); }

      try {
        synced = await supabase
            .from('avc_records')
            .select('id')
            .eq('doctor_id', userId)
            .not('date_avc', 'is', null);
      } catch (e) { debugPrint(' synced error: $e'); }

      try {
        recentRaw = await supabase
            .from('avc_records')
            .select('id,created_at,date_avc,patient_id,patients(first_name,last_name)') // ← JOINture
            .eq('doctor_id', userId)
            .order('created_at', ascending: false)
            .limit(5);
      } catch (e) { debugPrint(' recentRaw error: $e'); }

      if (mounted) {
        setState(() {
          _doctorData   = doctor;
          _patientCount = patients.length;
          _fileCount    = files.length;
          _monthCount   = monthly.length;
          _pendingCount = pending.length;
          _syncCount    = synced.length;
          _recentFiles  = List<Map<String, dynamic>>.from(recentRaw);
          _isLoading    = false;
        });
      }
    } catch (e) {
      debugPrint(' _loadData global error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (mounted)
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => LoginPage()));
  }

  // ─── Navigation ───────────────────────────────────────────────────────────
  // on passe onBack à chaque sous-page.
  // Sans ça, Navigator.pop() dans ces pages vidait la pile
  // → écran blanc sur PC, écran noir sur mobile.
  Widget _currentPage() {
    switch (_navIndex) {
      case 0:
        return _buildHome();
      case 1:
        return PatientsPage(
          isSelectMode: false,
          onBack: () => setState(() => _navIndex = 0),
        );
      case 2:
        return PatientsPage(
          isSelectMode: true,
          onBack: () => setState(() => _navIndex = 0),
        );
      case 3:
        return ProfilePage(
          onBack: () => setState(() => _navIndex = 0),
        );
      default:
        return _buildHome();
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override //la structure visuelle standard d'un écran mobile.
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
            : FadeTransition(opacity: _fadeAnim, child: _currentPage()),
      ]),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Bottom Nav ───────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined,  'active': Icons.home_rounded,       'label': 'Accueil'},
      {'icon': Icons.people_outline, 'active': Icons.people_alt_rounded, 'label': 'Patients'},
      {'icon': Icons.sync_outlined,  'active': Icons.sync_rounded,       'label': 'Dossiers'},
      {'icon': Icons.person_outline, 'active': Icons.person_rounded,     'label': 'Profil'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: glassBdr)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = _navIndex == i;
              final item   = items[i];
              return GestureDetector(
                onTap: () => setState(() => _navIndex = i),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 250),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? primary.withOpacity(0.18) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      active ? item['active'] as IconData : item['icon'] as IconData,
                      color: active ? primary : textMid,
                      size: 22,
                    ),
                    SizedBox(height: 4),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                        color: active ? primary : textMid,
                      ),
                    ),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ─── HOME ─────────────────────────────────────────────────────────────────
  Widget _buildHome() {
    final name = _doctorData?['full_name']
        ?? supabase.auth.currentUser?.email
        ?? 'Médecin';
    final spec    = _doctorData?['specialty'] ?? '';
    final total   = _patientCount + _fileCount;
    final syncPct = total == 0
        ? 0
        : ((_syncCount / total.clamp(1, 9999)) * 100).round();

    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(name, spec)), //la structure visuelle standard d'un écran mobile.
        SliverToBoxAdapter(child: _sectionLabel('STATISTIQUES')),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(child: _buildStatCircle(
                title: 'Patients', value: _patientCount,
                total: _patientCount == 0 ? 1 : _patientCount * 2,
                color: green, subtitle: 'enregistrés',
              )),
              SizedBox(width: 14),
              Expanded(child: _buildStatCircle(
                title: 'Dossiers AVC', value: _fileCount,
                total: _fileCount == 0 ? 1 : _fileCount * 2,
                color: blue, subtitle: 'enregistrés',
              )),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(children: [
              Expanded(child: _buildMiniStat('$_monthCount', 'Ce mois', primary)),
              SizedBox(width: 10),
              Expanded(child: _buildMiniStat('$_pendingCount', 'En attente', orange)),
              SizedBox(width: 10),
              Expanded(child: _buildMiniStat('$syncPct%', 'Complétés', blue)),
            ]),
          ),
        ),
        SliverToBoxAdapter(child: _sectionLabel('ACTIVITÉ — 7 JOURS')),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _buildActivityChart(),
          ),
        ),
        SliverToBoxAdapter(child: _sectionLabel('CALENDRIER')),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _buildCalendar(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: _buildTodayChip(),
          ),
        ),
        SliverToBoxAdapter(child: _sectionLabel('DERNIERS DOSSIERS AVC')),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _buildRecentFiles(),
          ),
        ),
        SliverToBoxAdapter(child: _sectionLabel('ACTIONS RAPIDES')),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.35,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildListDelegate([
              _buildActionCard('Mes patients', Icons.people_alt_outlined, green,
                  'Gérer la liste', () => setState(() => _navIndex = 1)),
              _buildActionCard('Dossiers AVC', Icons.folder_open_outlined, blue,
                  'Nouvelle fiche', () => setState(() => _navIndex = 2)),
              _buildActionCard('Calendrier', Icons.event_outlined, orange,
                  'Rendez-vous', () {}),
              _buildActionCard('Mon profil', Icons.account_circle_outlined, accent,
                  'Paramètres', () => setState(() => _navIndex = 3)),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildSecurityBanner(),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader(String name, String spec) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: glassBdr)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 8),
          Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: accentBdr, width: 1.5),
              ),
              child: Icon(Icons.medical_services_outlined, color: primary, size: 24),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('MEDIPORTAL',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                        color: accent, letterSpacing: 3)),
                Text('Dr. $name',
                    style: TextStyle(color: textHi, fontSize: 17, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis),
                if (spec.isNotEmpty)
                  Text(spec, style: TextStyle(color: primary.withOpacity(0.85), fontSize: 12)),
              ]),
            ),
            GestureDetector(
              onTap: _signOut,
              child: Container(
                padding: EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppThemeController.color(Colors.white.withOpacity(0.05), Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: glassBdr),
                ),
                child: Icon(Icons.logout_outlined, color: textMid, size: 19),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Text(text,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
              color: accent, letterSpacing: 2.5)),
    );
  }

  Widget _buildStatCircle({
    required String title, required int value,
    required int total, required Color color, required String subtitle,
  }) {
    final pct = total == 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: glassBdr),
      ),
      child: Column(children: [
        SizedBox(
          width: 90, height: 90,
          child: Stack(alignment: Alignment.center, children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: pct),
              duration: Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => SizedBox(
                width: 90, height: 90,
                child: CircularProgressIndicator(
                  value: v, strokeWidth: 6,
                  backgroundColor: AppThemeController.color(Colors.white.withOpacity(0.06), Colors.black.withOpacity(0.06)),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$v', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color, height: 1)),
                Text(subtitle, style: TextStyle(fontSize: 9, color: textLow)),
              ]),
            ),
          ]),
        ),
        SizedBox(height: 12),
        Text(title, style: TextStyle(color: textHi, fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: glassBdr),
      ),
      child: Column(children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 900),
          curve: Curves.easeOut,
          builder: (_, t, __) => Opacity(
            opacity: t,
            child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: textMid, letterSpacing: 0.3)),
      ]),
    );
  }

  Widget _buildActivityChart() {
    final barValues = [3.0, 5.0, 8.0, 4.0, 9.0, 6.0, 11.0];
    final days      = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final maxVal    = barValues.reduce((a, b) => a > b ? a : b);
    final todayIdx  = (DateTime.now().weekday - 1) % 7;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: glassBdr),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Dossiers créés',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textHi)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentBdr),
            ),
            child: Text('+24% vs S-1',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: primary)),
          ),
        ]),
        SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(barValues.length, (i) {
              final pct   = barValues[i] / maxVal;
              final today = i == todayIdx;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: pct),
                        duration: Duration(milliseconds: 900 + i * 80),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => Container(
                          height: (82 * v).clamp(4.0, 82.0),
                          decoration: BoxDecoration(
                            color: today ? primary : primary.withOpacity(0.35 + 0.2 * pct),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                            boxShadow: today
                                ? [BoxShadow(color: primary.withOpacity(0.4), blurRadius: 6)]
                                : null,
                          ),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(days[i], style: TextStyle(
                          fontSize: 9,
                          color: today ? primary : textLow,
                          fontWeight: today ? FontWeight.w700 : FontWeight.w400)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ]),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: glassBdr),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2027, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
        onDaySelected: (sel, foc) => setState(() { _selectedDay = sel; _focusedDay = foc; }),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(color: primary, shape: BoxShape.circle),
          selectedTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          todayDecoration: BoxDecoration(
            color: Colors.transparent, shape: BoxShape.circle,
            border: Border.all(color: primary, width: 1.5),
          ),
          todayTextStyle: TextStyle(color: primary, fontWeight: FontWeight.bold),
          defaultTextStyle: TextStyle(color: textHi),
          weekendTextStyle: TextStyle(color: accent.withOpacity(0.7)),
          outsideTextStyle: TextStyle(color: textLow),
          markerDecoration: BoxDecoration(color: orange, shape: BoxShape.circle),
          cellMargin: EdgeInsets.all(5),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(color: textHi, fontWeight: FontWeight.w800, fontSize: 15),
          leftChevronIcon: Icon(Icons.chevron_left_rounded, color: primary),
          rightChevronIcon: Icon(Icons.chevron_right_rounded, color: primary),
          headerPadding: EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(bottom: BorderSide(color: glassBdr)),
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: textMid, fontSize: 12, fontWeight: FontWeight.w600),
          weekendStyle: TextStyle(color: accent.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildTodayChip() {
    final now    = DateTime.now();
    final months = ['Janvier','Février','Mars','Avril','Mai','Juin',
                    'Juillet','Août','Septembre','Octobre','Novembre','Décembre'];
    final days   = ['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche'];
    final dateStr = '${days[(now.weekday - 1) % 7]} ${now.day} ${months[now.month - 1]} ${now.year}';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentBdr),
      ),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: green, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: green.withOpacity(0.5), blurRadius: 6)],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("AUJOURD'HUI", style: TextStyle(
                fontSize: 9, color: accent, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Text(dateStr, style: TextStyle(fontSize: 13, color: textHi, fontWeight: FontWeight.w600)),
          ]),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentBdr),
          ),
          child: Text('3 RDV',
              style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _buildRecentFiles() {
    if (_recentFiles.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: glassBdr),
        ),
        child: Center(
          child: Text('Aucun dossier AVC récent',
              style: TextStyle(color: textMid, fontSize: 13)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBdr),
      ),
      child: Column(
        children: List.generate(_recentFiles.length, (i) {
          final file = _recentFiles[i];
          final pm   = file['patients'];
          String name = 'Patient inconnu';
          if (pm != null) {
            final fn = (pm['first_name'] ?? '').toString().trim();
            final ln = (pm['last_name']  ?? '').toString().trim();
            name = '$fn $ln'.trim().isEmpty ? 'Patient inconnu' : '$fn $ln';
          }
          final raw   = file['created_at'] ?? '';
          String date = '';
          if (raw.isNotEmpty) {
            final d = DateTime.tryParse(raw);
            if (d != null)
              date = '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
          }
          final dateSvc   = file['date_avc'];
          final isSync    = dateSvc != null && dateSvc.toString().isNotEmpty;
          final statut    = isSync ? 'Complété' : 'En attente';
          final patientId = file['patient_id']?.toString() ?? '';

          return Column(children: [
            GestureDetector(
              onTap: patientId.isNotEmpty
                  ? () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AvcRegistrationPage(patientId: patientId)))
                  : null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.person_outline_rounded, color: primary, size: 18),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: TextStyle(color: textHi, fontSize: 13, fontWeight: FontWeight.w700)),
                      Text(date, style: TextStyle(color: textMid, fontSize: 11)),
                    ]),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isSync ? green : orange).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: (isSync ? green : orange).withOpacity(0.3)),
                    ),
                    child: Text(statut,
                        style: TextStyle(
                            color: isSync ? green : orange,
                            fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: textLow, size: 18),
                ]),
              ),
            ),
            if (i < _recentFiles.length - 1)
              Divider(color: glassBdr, height: 1, indent: 16, endIndent: 16),
          ]);
        }),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: glassBdr),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                padding: EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.arrow_outward_rounded, color: textLow, size: 14),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textHi)),
              SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 10, color: textMid)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentBdr),
      ),
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.verified_user_outlined, color: primary, size: 22),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Plateforme sécurisée',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textHi)),
            SizedBox(height: 3),
            Text('Conforme RGPD · Données chiffrées · Support 24/7',
                style: TextStyle(color: textMid, fontSize: 11)),
          ]),
        ),
      ]),
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

