import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme_controller.dart';
import 'login_page.dart';
import 'dashboard_page.dart';

final supabase = Supabase.instance.client;

class RegisterPage extends StatefulWidget {
  RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedSpecialty;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Palette — Dark Medical Premium (identique LoginPage)
  static Color get bg        => AppThemeController.color(Color(0xFF0D2B22), Color(0xFFF4F8F6));
  static Color get primary   => AppThemeController.color(Color(0xFF4CAF92), Color(0xFF1D7D63));
  static Color get primaryDk => AppThemeController.color(Color(0xFF2E7D64), Color(0xFF14634E));
  static Color get textHi    => AppThemeController.color(Color(0xFFFFFFFF), Color(0xFF10241D));
  static Color get textMid   => AppThemeController.color(Color(0x99FFFFFF), Color(0xAA10241D));
  static Color get textLow   => AppThemeController.color(Color(0x44FFFFFF), Color(0x6610241D));
  static Color get glass     => AppThemeController.color(Color(0x0FFFFFFF), Color(0xDFFFFFFF));
  static Color get glassBdr  => AppThemeController.color(Color(0x1AFFFFFF), Color(0x263E6B5A));
  static Color get accentBdr => AppThemeController.color(Color(0x3A4CAF92), Color(0x553D9B7B));

  final List<String> _specialties = [
    'Cardiologie', 'Dermatologie', 'Gynécologie', 'Médecine générale',
    'Neurologie', 'Ophtalmologie', 'Pédiatrie', 'Psychiatrie',
    'Radiologie', 'Urgences',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async { //Validation locale
    if (!_formKey.currentState!.validate()) return;  // ← clé du Form pour valider tout d'un coup

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Les mots de passe ne correspondent pas', isError: true);
      return;
    }
    if (_selectedSpecialty == null) {
      _showSnackBar('Veuillez sélectionner une spécialité', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {         //crée le compte dans l'Auth Supabase et retourne un user avec un ID unique
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user == null) {
        _showSnackBar('Erreur lors de la création du compte', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final userId = response.user!.id; // Le lien entre Auth et DB
      final fullName = '${_prenomController.text.trim()} ${_nomController.text.trim()}';

      await supabase.from('doctors').insert({
        'id': userId,
        'full_name': fullName,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'specialty': _selectedSpecialty,
      });

      if (!mounted) return;

      if (response.session != null) {
        _showSnackBar('Bienvenue Dr. $fullName !');
        await Future.delayed(Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DashboardPage()),
          );
        }
      } else {
        _showSnackBar('Inscription réussie ! Vérifiez votre email.');
        await Future.delayed(Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
          );
        }
      }
    } on AuthException catch (e) {
      _showSnackBar(_mapAuthError(e.message), isError: true);
    } on PostgrestException catch (e) {
      _showSnackBar(
        e.code == '23505' ? 'Un compte avec cet email existe déjà' : 'Erreur base de données',
        isError: true,
      );
    } catch (e) {
      _showSnackBar('Erreur inattendue', isError: true);
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
    if (message.contains('User already registered')) return 'Cet email est déjà utilisé';
    if (message.contains('Password should be at least')) return 'Minimum 6 caractères requis';
    return 'Erreur d\'inscription';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // 1️⃣ Image de fond — identique LoginPage
          Positioned.fill(
          
              child: Image.asset(
                'assets/images/medicine.png',
                fit: BoxFit.cover,
                color: Color.fromARGB(255, 48, 67, 61).withOpacity(0.50
              ),
              colorBlendMode: BlendMode.srcOver,
            ),
          ),

          // 2️⃣ Overlay sombre — identique LoginPage
          Positioned.fill(
            child: Container(
              color: bg.withOpacity(0.85),
            ),
          ),

          // 3️⃣ Cercles décoratifs
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

          // 4️⃣ Contenu
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildHeader(),
                      SizedBox(height: 28),
                      _buildFormCard(),
                      SizedBox(height: 24),
                      _buildFooterLink(),
                      SizedBox(height: 12),
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
          'INSCRIPTION MÉDECIN',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: primary.withOpacity(0.75),
            letterSpacing: 3,
          ),
        ),
        SizedBox(height: 16),
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
          Row(
            children: [
              Text(
                'Créer votre compte',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textHi,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentBdr, width: 1),
                ),
                child: Text(
                  'Nouveau',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: primary.withOpacity(0.9),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'PRÉNOM',
                  hint: 'Prénom',
                  icon: Icons.person_outline_rounded,
                  controller: _prenomController,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFormField(
                  label: 'NOM',
                  hint: 'Nom de famille',
                  icon: Icons.person_outline_rounded,
                  controller: _nomController,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          _buildFormField(
            label: 'EMAIL PROFESSIONNEL',
            hint: 'dr.exemple@hopital.fr',
            icon: Icons.mail_outline_rounded,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          SizedBox(height: 16),

          _buildFormField(
            label: 'TÉLÉPHONE (optionnel)',
            hint: '+216 12 345 678',
            icon: Icons.phone_outlined,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            required: false,
          ),
          SizedBox(height: 16),

          _buildLabel('SPÉCIALITÉ MÉDICALE'),
          SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: AppThemeController.color(Colors.white.withOpacity(0.04), Colors.black.withOpacity(0.04)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: glassBdr, width: 1),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedSpecialty,
              dropdownColor: AppThemeController.color(Color(0xFF183D2E), Color(0xFFFFFFFF)),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: primary.withOpacity(0.7)),
              style: TextStyle(color: textHi, fontSize: 14),
              hint: Text('Sélectionnez une spécialité', style: TextStyle(color: textLow, fontSize: 13)),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              items: _specialties.map((s) {
                return DropdownMenuItem(value: s, child: Text(s));
              }).toList(),
              onChanged: (v) => setState(() => _selectedSpecialty = v),
              validator: (v) => (v == null) ? 'Veuillez sélectionner' : null,
            ),
          ),
          SizedBox(height: 16),

          _buildPasswordFormField(
            label: 'MOT DE PASSE',
            controller: _passwordController,
            obscure: _obscurePassword,
            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          SizedBox(height: 16),

          _buildPasswordFormField(
            label: 'CONFIRMER LE MOT DE PASSE',
            controller: _confirmPasswordController,
            obscure: _obscureConfirmPassword,
            onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          SizedBox(height: 24),

          _buildPrimaryButton(
            label: "CRÉER LE COMPTE",
            onTap: _isLoading ? null : _signUp,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Déjà inscrit ? ", style: TextStyle(fontSize: 13, color: textMid)),
        GestureDetector(
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
          ),
          child: Text(
            "Se connecter",
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

  Widget _buildFormField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppThemeController.color(Colors.white.withOpacity(0.04), Colors.black.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: glassBdr, width: 1),
          ),
          child: TextFormField(
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
            validator: validator ??
                (v) {
                  if (required && (v == null || v.isEmpty)) return 'Ce champ est requis';
                  return null;
                },
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordFormField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppThemeController.color(Colors.white.withOpacity(0.04), Colors.black.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: glassBdr, width: 1),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(color: textHi, fontSize: 14),
            cursorColor: primary,
            decoration: InputDecoration(
              hintText: '••••••••••',
              hintStyle: TextStyle(color: textLow, fontSize: 13),
              prefixIcon: Icon(Icons.lock_outline_rounded, color: primary.withOpacity(0.65), size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: textLow,
                  size: 18,
                ),
                onPressed: onToggle,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ce champ est requis';
              if (v.length < 6) return 'Minimum 6 caractères';
              return null;
            },
          ),
        ),
      ],
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

  Widget _glowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

