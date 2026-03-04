import 'package:flutter/material.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/core/theme/theme_provider.dart';
import 'package:luminar_std/presentation/bottom_nav_screen/bottom_nav_screen.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Form Key for validation
  final _formKey = GlobalKey<FormState>();

  // 2. State for password visibility
  bool _obscurePassword = true;

  // Validation Logic
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password is required";
    if (value.length < 8) return "Must be at least 8 characters";
    if (!RegExp(r'[A-Z]').hasMatch(value))
      return "Must contain one uppercase letter";
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value))
      return "Must contain one special character";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Form(
                // 3. Wrap everything in a Form
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: themeProvider.isDarkMode
                          ? AppColors.borderDark
                          : AppColors.surfaceLight,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// THEME BUTTON
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: Icon(
                              themeProvider.isDarkMode
                                  ? Icons.light_mode
                                  : Icons.dark_mode,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: () => themeProvider.toggleTheme(),
                          ),
                        ),

                        /// LOGO
                        Container(
                          height: 80,
                          width: 80,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage("assets/images/lum_logo.png"),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// EMAIL FIELD
                        TextFormField(
                          validator: (value) =>
                              (value == null || !value.contains('@'))
                              ? "Enter a valid email"
                              : null,
                          decoration: _inputDecoration(
                            theme,
                            "Email ID",
                            Icons.person_outline,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// PASSWORD FIELD (With Eye Button)
                        TextFormField(
                          obscureText: _obscurePassword,
                          validator: _validatePassword,
                          decoration: _inputDecoration(
                            theme,
                            "Password",
                            Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: theme.colorScheme.primary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Forgot Password",
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// SIGN IN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                // Logic for successful validation
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BottomNavScreen(),
                                  ),
                                );
                                // ScaffoldMessenger.of(context).showSnackBar(
                                //   const SnackBar(
                                //     content: Text('Processing Login...'),
                                //   ),
                                // );
                              }
                            },
                            child: const Text(
                              "SIGN IN",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        /// REGISTER TEXT
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Not a student? ",
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                            Text(
                              "Register here",
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to keep the code clean
  InputDecoration _inputDecoration(
    ThemeData theme,
    String label,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: theme.colorScheme.primary),
      suffixIcon: suffixIcon,
      labelText: label,
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.6),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}
