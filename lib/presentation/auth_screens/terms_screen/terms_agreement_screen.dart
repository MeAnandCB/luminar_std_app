import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luminar_std/core/theme/app_colors.dart';
import 'package:luminar_std/presentation/auth_screens/login_screen/login_screen.dart';

/// Shown once before login. Required by App Store Guideline 1.2 (UGC):
/// users must agree to terms that state there is zero tolerance for
/// objectionable content or abusive behavior before they can access the
/// app's chat features.
class TermsAgreementScreen extends StatefulWidget {
  static const String prefsKey = 'has_accepted_terms';

  const TermsAgreementScreen({super.key});

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  bool _agreed = false;
  bool _saving = false;

  Future<void> _accept() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(TermsAgreementScreen.prefsKey, true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Terms of Use'),
        backgroundColor: AppColors.cardBackground,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Luminar Student App – Terms of Use & End User License Agreement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _section(
                      'Acceptance of Terms',
                      'By creating an account or signing in, you agree to be bound by these Terms of Use. '
                          'If you do not agree, please do not use the app.',
                    ),
                    _section(
                      'User Conduct & Zero-Tolerance Policy',
                      'The app includes chat features that allow you to communicate with trainers, batchmates and '
                          'other students. There is ZERO TOLERANCE for objectionable content or abusive behavior of '
                          'any kind, including but not limited to: harassment, hate speech, threats, bullying, '
                          'sexually explicit content, illegal content, spam, and impersonation.',
                    ),
                    _section(
                      'Content Moderation',
                      'Messages and shared files may be automatically screened for prohibited content. Users who '
                          'violate this policy may have their content removed and their access to chat or the app '
                          'suspended or terminated.',
                    ),
                    _section(
                      'Reporting Objectionable Content',
                      'If you encounter objectionable content or an abusive user, you can report it directly from '
                          'the chat using the "Report" option on a message or from the chat menu. Reports are '
                          'reviewed by our team, and we commit to act on valid reports — including removing the '
                          'content and ejecting the offending user — within 24 hours.',
                    ),
                    _section(
                      'Blocking Users',
                      'You can block any user from a chat at any time using the "Block user" option in the chat '
                          'menu. Once blocked, that user\'s messages will be hidden from your chat instantly, and '
                          'we will be notified so we can review the reported user\'s conduct.',
                    ),
                    _section(
                      'Account Termination',
                      'We reserve the right to remove content and suspend or terminate accounts of users who '
                          'violate this policy, without prior notice.',
                    ),
                    _section(
                      'Privacy',
                      'Information you provide is handled in accordance with our Privacy Policy, available within '
                          'the app and on our website.',
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _agreed = !_agreed),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _agreed,
                            onChanged: (v) => setState(() => _agreed = v ?? false),
                            activeColor: AppColors.primary,
                          ),
                          Expanded(
                            child: Text(
                              'I have read and agree to the Terms of Use, including the zero-tolerance policy '
                              'for objectionable content and abusive behavior.',
                              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_agreed && !_saving) ? _accept : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Agree & Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
