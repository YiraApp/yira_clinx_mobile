import 'package:flutter/material.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';

class DigitalConsentSignScreen extends StatefulWidget {
  final String? link;

  const DigitalConsentSignScreen({super.key, this.link});

  @override
  State<DigitalConsentSignScreen> createState() => _DigitalConsentSignScreenState();
}

class _DigitalConsentSignScreenState extends State<DigitalConsentSignScreen> {
  bool _agreedToTerms = false;
  bool _signedSuccess = false;

  void _handleConsentSign() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the consent terms to proceed.')),
      );
      return;
    }

    setState(() => _signedSuccess = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Digital Consent Sign', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(screenHorizontalSpacePadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTab ? 600 : double.infinity),
            child: Container(
              padding: EdgeInsets.all(isTab ? 28 : 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12),
                ],
              ),
              child: _signedSuccess
                  ? Column(
                      children: [
                        const Icon(Icons.verified_rounded, color: Colors.green, size: 64),
                        const SizedBox(height: 16),
                        const Text('Consent Signed & Verified!', style: TextStyle(fontFamily: appPoppinFont, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Your digital signature and consent timestamp have been stored securely in your electronic health record.', textAlign: TextAlign.center, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Done', style: TextStyle(fontFamily: appPoppinFont, color: Colors.white)),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Medical & Teleconsultation Consent', style: TextStyle(fontFamily: appPoppinFont, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Please read and sign below to consent to telehealth services and electronic medical record sharing.', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 16),

                        // Consent Terms Container
                        Container(
                          height: 180,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const SingleChildScrollView(
                            child: Text(
                              '1. CONSENT TO TREATMENT: I hereby authorize licensed healthcare providers at Apollo City Hospital / Yira Clinx to perform necessary clinical evaluations and teleconsultations.\n\n'
                              '2. ELECTRONIC RECORDS & PRIVACY: I consent to the electronic transmission of medical data, prescriptions, and diagnostic reports in compliance with healthcare data protection standards.\n\n'
                              '3. TELECONSULTATION LIMITATIONS: I understand that teleconsultations are not designed for life-threatening emergencies. In case of emergency, I will contact emergency services immediately.',
                              style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, height: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Agreement Checkbox
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('I have read and agree to all consent terms above.', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600)),
                          value: _agreedToTerms,
                          activeColor: primaryColor,
                          onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                        ),
                        const SizedBox(height: 16),

                        // Signature Box Mock
                        Container(
                          width: double.infinity,
                          height: 100,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.draw_rounded, color: primaryColor),
                              const SizedBox(width: 8),
                              Text('Tap to Sign / Draw Signature', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: primaryColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                            onPressed: _handleConsentSign,
                            child: const Text('Sign & Submit Consent', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
