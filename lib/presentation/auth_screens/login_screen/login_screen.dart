import 'package:flutter/material.dart';
import 'package:luminar_std/presentation/auth_screens/forgot_password/forgot_password.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/controller.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/theme_provider.dart';
import '../../bottom_nav_screens/bottom_nav_screen/bottom_nav_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _particleCtrl;

  // Entry animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _headerFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _formFade;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // Field focus tracking for animated borders
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    // Logo bounces in
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    // Header text fades in
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );

    // Form card slides up
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.4, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );

    _entryCtrl.forward();

    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  Future<void> _checkAutoLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = await authProvider.checkLoginStatus();
    if (isLoggedIn && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavScreen()),
      );
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _particleCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? _validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or phone is required';
    }
    final trimmed = value.trim();
    final isPhone = RegExp(r'^\+?[0-9]{7,15}$').hasMatch(trimmed);
    final isEmail = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(trimmed);
    if (!isPhone && !isEmail) return 'Enter a valid email or phone number';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.clearError();
      final success = await authProvider.login(
        context: context,
        identifier: _emailController.text.toLowerCase().trim(),
        password: _passwordController.text.trim(),
      );
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomNavScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context);

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Stack(
            children: [
              // ── Gradient header background ──────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: size.height * 0.46,
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF2A0E8F),
                            Color(0xFF5A3ED9),
                            Color(0xFF8B7BF2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    // Decorative blobs
                    Positioned(
                      top: -60,
                      right: -50,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: -40,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Floating particles
                    ...List.generate(14, (i) {
                      final rng = math.Random(i * 17);
                      final bx = rng.nextDouble() * size.width;
                      final by = rng.nextDouble() * size.height * 0.46;
                      final ds = 1.5 + rng.nextDouble() * 3.0;
                      final sp = 0.2 + rng.nextDouble() * 0.6;
                      return AnimatedBuilder(
                        animation: _particleCtrl,
                        builder: (_, __) {
                          final t = (_particleCtrl.value * sp) % 1.0;
                          return Positioned(
                            left: bx +
                                math.sin(t * 2 * math.pi + i) * 18,
                            top: by - (t * 100),
                            child: Opacity(
                              opacity:
                                  (1.0 - t).clamp(0.0, 1.0) * 0.4,
                              child: Container(
                                width: ds,
                                height: ds,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),

              // ── Wave clip between header and card ───────
              Positioned(
                top: size.height * 0.40,
                left: 0,
                right: 0,
                child: ClipPath(
                  clipper: _WaveClipper(),
                  child: Container(
                    height: 70,
                    color: AppColors.scaffoldBackground,
                  ),
                ),
              ),

              // ── Scrollable content ───────────────────────
              SafeArea(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // ── Header area: logo + welcome ──────
                          SizedBox(
                            height: size.height * 0.38,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Logo with glow
                                AnimatedBuilder(
                                  animation: _entryCtrl,
                                  builder: (_, __) => Transform.scale(
                                    scale: _logoScale.value,
                                    child: Opacity(
                                      opacity: _logoOpacity.value,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Glow halo
                                          Container(
                                            width: 108,
                                            height: 108,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white
                                                  .withValues(alpha: 0.18),
                                            ),
                                          ),
                                          // White logo circle
                                          Container(
                                            width: 90,
                                            height: 90,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF6C5CE7,
                                                  ).withValues(alpha: 0.5),
                                                  blurRadius: 32,
                                                  spreadRadius: 6,
                                                ),
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.15),
                                                  blurRadius: 16,
                                                  offset:
                                                      const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Image.asset(
                                                'assets/images/lum_logo.png',
                                                width: 50,
                                                height: 50,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // Welcome text
                                FadeTransition(
                                  opacity: _headerFade,
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Welcome Back',
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Sign in to your account',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Form card ────────────────────────
                          Expanded(
                            child: SlideTransition(
                              position: _formSlide,
                              child: FadeTransition(
                                opacity: _formFade,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.scaffoldBackground,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(36),
                                      topRight: Radius.circular(36),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 30,
                                        offset: const Offset(0, -6),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        28, 36, 28, 28),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Section label
                                          Text(
                                            'Login',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Enter your credentials to continue',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),

                                          const SizedBox(height: 28),

                                          // Email / Phone field
                                          _buildFieldLabel('Email or Phone'),
                                          const SizedBox(height: 8),
                                          _buildTextField(
                                            controller: _emailController,
                                            focusNode: _emailFocus,
                                            hint: 'Email or phone number',
                                            icon: Icons.person_outline_rounded,
                                            keyboardType: TextInputType.emailAddress,
                                            validator: _validateIdentifier,
                                            textInputAction: TextInputAction.next,
                                            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                                          ),

                                          const SizedBox(height: 20),

                                          // Password field
                                          _buildFieldLabel('Password'),
                                          const SizedBox(height: 8),
                                          _buildTextField(
                                            controller: _passwordController,
                                            focusNode: _passwordFocus,
                                            hint: '••••••••',
                                            icon: Icons.lock_outline_rounded,
                                            obscure: !_isPasswordVisible,
                                            validator: _validatePassword,
                                            textInputAction: TextInputAction.done,
                                            onFieldSubmitted: (_) => _handleLogin(),
                                            suffix: IconButton(
                                              icon: Icon(
                                                _isPasswordVisible
                                                    ? Icons.visibility_off_rounded
                                                    : Icons.visibility_rounded,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                              onPressed: () => setState(() {
                                                _isPasswordVisible = !_isPasswordVisible;
                                              }),
                                            ),
                                          ),

                                          // Auth error
                                          if (authProvider.errorMessage !=
                                              null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 12),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.error
                                                      .withValues(alpha: 0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppColors.error
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.error_outline,
                                                      color: AppColors.error,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        authProvider
                                                            .errorMessage!,
                                                        style: TextStyle(
                                                          color: AppColors.error,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                          // Forgot password
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ForgotPasswordScreen(),
                                                  ),
                                                );
                                              },
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 4,
                                                  horizontal: 0,
                                                ),
                                              ),
                                              child: Text(
                                                'Forgot Password?',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 16),

                                          // Sign in button
                                          Consumer<AuthProvider>(
                                            builder: (_, auth, __) => SizedBox(
                                              width: double.infinity,
                                              height: 56,
                                              child: ElevatedButton(
                                                onPressed: auth.isLoading ? null : _handleLogin,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primary,
                                                  foregroundColor: Colors.white,
                                                  elevation: 4,
                                                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                ),
                                                child: auth.isLoading
                                                    ? const SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child: CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2.5,
                                                        ),
                                                      )
                                                    : const Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            'Sign In',
                                                            style: TextStyle(
                                                              fontSize: 17,
                                                              fontWeight: FontWeight.w700,
                                                              letterSpacing: 0.3,
                                                            ),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Icon(Icons.arrow_forward_rounded, size: 20),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 8),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onFieldSubmitted,
  }) {
    final isFocused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.borderColor,
          width: isFocused ? 1.8 : 1.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscure,
        validator: validator,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: AppColors.textHint),
          prefixIcon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              color: isFocused
                  ? AppColors.primary
                  : AppColors.textHint,
              size: 20,
            ),
          ),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          errorStyle: TextStyle(
            color: AppColors.error,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

}

// ── Wave clipper for the header/form transition ────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.4);
    path.quadraticBezierTo(
      size.width * 0.25,
      0,
      size.width * 0.5,
      size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.6,
      size.width,
      size.height * 0.2,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper old) => false;
}
