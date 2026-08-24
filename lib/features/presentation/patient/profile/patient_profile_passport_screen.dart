import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../di/dependency_injection.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import '../../patient_profile/patient_over_view_bloc/patient_over_view_bloc.dart';
import '../widgets/health_passport_card.dart';

import '../../../../core/shimmer_widgets/over_view_shimmer_card.dart';

class PatientProfilePassportScreen extends StatefulWidget {
  const PatientProfilePassportScreen({super.key});

  @override
  State<PatientProfilePassportScreen> createState() => _PatientProfilePassportScreenState();
}

class _PatientProfilePassportScreenState extends State<PatientProfilePassportScreen> {
  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Digital Health Passport QR', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 150, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            const Text('Scan at hospital check-in for instant record verification.', textAlign: TextAlign.center, style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';
    final orgId = currentUser?.data?.latestOrgId?.toString() ?? '1';
    final hospitalId = currentUser?.data?.latestHospitalId?.toString() ?? '1';
    final firstName = currentUser?.data?.firstName ?? '';
    final lastName = currentUser?.data?.lastName ?? '';
    final patientName = '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : 'Patient';

    return BlocProvider<PatientOverViewBloc>(
      create: (_) => sl<PatientOverViewBloc>()
        ..add(LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId)),
      child: BlocBuilder<PatientOverViewBloc, PatientOverViewState>(
        builder: (context, state) {
          PatientOverViewEntity? overViewEntity;
          if (state is LoadPatientDataState) {
            overViewEntity = state.patientOverViewEntity;
          }

          final data = overViewEntity?.data;
          final phone = data?.contactInformation?.phone ?? currentUser?.data?.phoneNumber ?? '';
          final email = data?.contactInformation?.emailAddress ?? currentUser?.data?.email ?? '';
          final address = data?.contactInformation?.residentialAddress ?? '';
          final emergencyName = data?.contactInformation?.emergencyContact?.name ?? '';
          final emergencyPhone = data?.contactInformation?.emergencyContact?.phone ?? '';
          final condition = data?.medicalInformation?.condition ?? 'None';
          final allergies = data?.medicalInformation?.allergies ?? 'None';
          final bloodGroup = data?.medicalInformation?.bloodGroup ?? '';
          final policyName = data?.insurance?.policyName ?? '';
          final policyNumber = data?.insurance?.policyNumber ?? '';

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              title: const Text(
                'My Profile & Health Passport',
                style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold),
              ),
            ),
            body: SingleChildScrollView(
        padding: const EdgeInsets.all(screenHorizontalSpacePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Digital Health Passport Card
            HealthPassportCard(
              patientName: 'Ch. Raja Vardan',
              mrnNumber: 'MRN-998241',
              bloodGroup: 'O+',
              emergencyContact: '+91 98765 43210',
              insurancePolicy: 'HDFC Ergo #POL-9920',
              onShowQrCode: () => _showQrDialog(context),
            ),
            const SizedBox(height: 20),

            // 2. Personal Information Section
            _buildSectionCard(
              context: context,
              title: 'Personal Information',
              icon: Icons.person_rounded,
              iconColor: Colors.blue,
              children: [
                _buildInfoRow(context, 'Full Name', 'Ch. Raja Vardan'),
                _buildInfoRow(context, 'Date of Birth', '14 May 1995 (31 Yrs)'),
                _buildInfoRow(context, 'Gender', 'Male'),
                _buildInfoRow(context, 'Blood Group', 'O+ Positive'),
                _buildInfoRow(context, 'Phone Number', '+91 98765 43210'),
                _buildInfoRow(context, 'Email Address', 'raja.vardan@yiramail.com'),
                _buildInfoRow(context, 'Residential Address', 'Plot #42, Health City, Jubilee Hills, Hyderabad'),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Emergency Contact Section
            _buildSectionCard(
              context: context,
              title: 'Emergency Contact',
              icon: Icons.contact_phone_rounded,
              iconColor: Colors.red,
              children: [
                _buildInfoRow(context, 'Contact Person', 'Srinivas Rao (Father)'),
                _buildInfoRow(context, 'Relationship', 'Parent / Father'),
                _buildInfoRow(context, 'Primary Phone', '+91 98490 12345'),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Insurance Details Section
            _buildSectionCard(
              context: context,
              title: 'Insurance Details',
              icon: Icons.health_and_safety_rounded,
              iconColor: Colors.teal,
              children: [
                _buildInfoRow(context, 'Insurance Provider', 'HDFC Ergo Health Insurance'),
                _buildInfoRow(context, 'Policy Number', 'POL-992019482'),
                _buildInfoRow(context, 'Coverage Plan', 'Comprehensive Family Floater (₹10 Lakhs)'),
                _buildInfoRow(context, 'Validity', 'Active until Dec 2027'),
              ],
            ),
            const SizedBox(height: 16),

            // 5. Medical History & Allergies Section
            _buildSectionCard(
              context: context,
              title: 'Medical History & Allergies',
              icon: Icons.medical_information_rounded,
              iconColor: Colors.purple,
              children: [
                _buildInfoRow(context, 'Known Conditions', 'Mild Hypertension, Seasonal Asthma'),
                _buildInfoRow(context, 'Drug Allergies', 'Penicillin (Severe Reaction)'),
                _buildInfoRow(context, 'Food Allergies', 'Peanuts, Shellfish'),
                _buildInfoRow(context, 'Past Surgeries', 'Appendectomy (2021)'),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  },
),
);
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
