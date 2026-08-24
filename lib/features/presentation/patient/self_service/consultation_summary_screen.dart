import 'package:flutter/material.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';

class ViewConsultationSummaryScreen extends StatelessWidget {
  final String? token;

  const ViewConsultationSummaryScreen({super.key, this.token});

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
        title: const Text('Consultation Summary', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating printable summary PDF...')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(screenHorizontalSpacePadding),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTab ? 650 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: primaryColor.withOpacity(0.12),
                        child: Icon(Icons.medical_services_rounded, color: primaryColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Apollo City Hospital', style: TextStyle(fontFamily: appPoppinFont, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('Attending Physician: Dr. Sarah Jenkins (Cardiologist)', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600])),
                            Text('Consultation Date: 20 Aug 2026', style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: primaryColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Chief Complaint & Diagnosis
                _buildSummarySection(
                  context: context,
                  title: 'Chief Complaint & Diagnosis',
                  icon: Icons.search_rounded,
                  iconColor: Colors.blue,
                  content: 'Patient presented with mild chest tightness and dyspnea on exertion. EKG showed normal sinus rhythm. Primary Diagnosis: Mild Stress-Induced Angina.',
                ),
                const SizedBox(height: 14),

                // Doctor Advice & Treatment Plan
                _buildSummarySection(
                  context: context,
                  title: 'Doctor Advice & Instructions',
                  icon: Icons.assignment_rounded,
                  iconColor: Colors.teal,
                  content: '1. Maintain low-sodium diet and avoid high-caffeine beverages.\n2. Daily 30-minute moderate walking.\n3. Repeat Lipid Profile test in 30 days.',
                ),
                const SizedBox(height: 14),

                // Prescribed Medications
                _buildSummarySection(
                  context: context,
                  title: 'Prescribed Medications',
                  icon: Icons.medication_rounded,
                  iconColor: Colors.purple,
                  content: '• Atorvastatin 10mg — 1 tablet daily at bedtime (30 Days)\n• Aspirin 75mg — 1 tablet daily post breakfast (30 Days)\n• Metoprolol 25mg — 1/2 tablet twice daily (15 Days)',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
        ],
      ),
    );
  }
}
