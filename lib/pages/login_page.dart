import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme_controller.dart';
import 'register_page.dart';
import 'dashboard_page.dart';

final supabase = Supabase.instance.client;

class LoginPage extends StatefulWidget { //Parce que la page change dynamiquement
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Palette — Dark Medical Premium
  static Color get bg        => AppThemeController.color(Color(0xFF0D2B22), Color(0xFFF4F8F6));
  static Color get surface   => AppThemeController.color(Color(0xFF132E24), Color(0xFFFFFFFF));
  static Color get primary   => AppThemeController.color(Color(0xFF4CAF92), Color(0xFF1D7D63));
  static Color get primaryDk => AppThemeController.color(Color(0xFF2E7D64), Color(0xFF14634E));
  static Color get textHi    => AppThemeController.color(Color(0xFFFFFFFF), Color(0xFF10241D));
  static Color get textMid   => AppThemeController.color(Color(0x99FFFFFF), Color(0xAA10241D));
  static Color get textLow   => AppThemeController.color(Color(0x44FFFFFF), Color(0x6610241D));
  static Color get glass     => AppThemeController.color(Color(0x0FFFFFFF), Color(0xDFFFFFFF));
  static Color get glassBdr  => AppThemeController.color(Color(0x1AFFFFFF), Color(0x263E6B5A));
  static Color get accentBdr => AppThemeController.color(Color(0x3A4CAF92), Color(0x553D9B7B));

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }
//Animation fluide.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session != null && mounted) { //mounted est vérifié avant chaque setState pour éviter les crashes si la page est fermée pendant la requête
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardPage()),
        );
      }
    } on AuthException catch (e) {
      _showSnackBar(_mapAuthError(e.message), isError: true);
    } catch (_) {
      _showSnackBar('Une erreur est survenue', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: isError ? Color(0xFFB71C1C) : primaryDk,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) return 'Email ou mot de passe incorrect';
    if (message.contains('Email not confirmed')) return 'Veuillez confirmer votre email';
    return 'Erreur de connexion';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Positioned.fill(
       // 🔥 ajuste ici (0.1 → 0.3 recommandé)
        child: Image.asset(
          'assets/images/medicine.png',
          fit: BoxFit.cover,
          color: Color.fromARGB(255, 48, 67, 61).withOpacity(0.50), // fusionne directement avec l'image
        colorBlendMode: BlendMode.srcOver,
        ),
      ),
    

    // 🔥 overlay sombre pour garder lisibilité
    Positioned.fill(
      child: Container(
        color: bg.withOpacity(0.85),
      ),
    ),
          // Arrière-plan décoratif
          Positioned(
            top: -80,
            right: -80,
            child: _glowCircle(260, primary.withOpacity(0.12)),
          ),
          Positioned(
            bottom: 60,
            left: -60,
            child: _glowCircle(200, primaryDk.withOpacity(0.10)),
          ),
          // Contenu
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  child: Column(
                    children: [
                      _buildHeader(),
                      SizedBox(height: 32),
                      _buildFormCard(),
                      SizedBox(height: 20),
                      _buildStatsBar(),
                      SizedBox(height: 24),
                      _buildFooterLink(),
                      SizedBox(height: 16),
                      _buildRgpdMention(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo ring
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: primary.withOpacity(0.10),
            border: Border.all(color: primary.withOpacity(0.25), width: 1.5),
          ),
          child: Icon(Icons.medical_services_outlined, color: primary, size: 34),
        ),
        SizedBox(height: 16),
        Text(
          'MEDIPORTAL',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: textHi,
            letterSpacing: 4,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'ESPACE MÉDECIN',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: primary.withOpacity(0.75),
            letterSpacing: 3,
          ),
        ),
        SizedBox(height: 16),
        // Ligne décorative
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [Colors.transparent, primary, Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: glass,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: glassBdr, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connexion sécurisée',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textHi.withOpacity(0.92),
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 20),
          _buildLabel('EMAIL PROFESSIONNEL'),
          SizedBox(height: 6),
          _buildTextField(
            controller: _emailController,
            hint: 'dr.nom@hopital.fr',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 18),
          _buildLabel('MOT DE PASSE'),
          SizedBox(height: 6),
          _buildPasswordField(),
          SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: Text(
                'Mot de passe oublié ?',
                style: TextStyle(
                  fontSize: 12,
                  color: primary.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(height: 22),
          _buildPrimaryButton(
            label: 'SE CONNECTER',
            onTap: _isLoading ? null : _signIn,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBdr, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat('99.9%', 'Sécurisé'),
          Container(width: 1, height: 36, color: glassBdr),
          _buildStat('12K+', 'Médecins'),
          Container(width: 1, height: 36, color: glassBdr),
          _buildStat('24/7', 'Support'),
        ],
      ),
    );
  }

  Widget _buildFooterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Pas encore inscrit ? ",
          style: TextStyle(fontSize: 13, color: textMid),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => RegisterPage()),
          ),
          child: Text(
            "Créer un compte",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: primary,
              decoration: TextDecoration.underline,
              decorationColor: primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRgpdMention() {
    return Text(
      'Conforme RGPD  ·  Données chiffrées  ·  Support 24/7',
      style: TextStyle(fontSize: 10, color: textLow, letterSpacing: 0.5),
      textAlign: TextAlign.center,
    );
  }

  // ─── Widgets réutilisables ────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppThemeController.color(Colors.white.withOpacity(0.04), Colors.black.withOpacity(0.04)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glassBdr, width: 1),
      ),
      child: TextField(
        controller: controller,
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

  Widget _buildPasswordField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppThemeController.color(Colors.white.withOpacity(0.04), Colors.black.withOpacity(0.04)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glassBdr, width: 1),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: TextStyle(color: textHi, fontSize: 14),
        cursorColor: primary,
        decoration: InputDecoration(
          hintText: '••••••••••',
          hintStyle: TextStyle(color: textLow, fontSize: 13),
          prefixIcon: Icon(Icons.lock_outline_rounded, color: primary.withOpacity(0.65), size: 18),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: textLow,
              size: 18,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [primaryDk, Color(0xFF1B4D3E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: accentBdr, width: 1),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: primary,
          ),
        ),
        SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: textMid, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _glowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

