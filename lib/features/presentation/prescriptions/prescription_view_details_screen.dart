import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/detailed_prescription_expandable_card.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../di/dependency_injection.dart';
import '../../../core/common_widgets/custom_button.dart';
import '../../../core/common_widgets/in_app_document_viewer.dart';
import '../../../core/api/base_api_configuration.dart';
import '../../../core/shimmer_widgets/base_shimmer.dart';

class PrescriptionViewDetailsScreen extends StatelessWidget {
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;

  const PrescriptionViewDetailsScreen({
    super.key,
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    return BlocProvider(
      create: (context) => sl<PrescriptionBloc>()..add(LoadPrescriptionData(
        patientId: patientId,
        appointmentId: appointmentId,
        hospitalId: hospitalId,
        orgId: orgId,
      )),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: BlocBuilder<PrescriptionBloc, PrescriptionState>(
            builder: (context, state) {
              return Column(
                children: [
                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(fieldBorderRadius),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            color: theme.primaryColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Details',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: displayWidth(context) * (isTab ? 0.024 : 0.045),
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Prescription Details',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: displayWidth(context) * (isTab ? 0.014 : 0.025),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: isDark ? Colors.white70 : Colors.black54,
                          onPressed: () => Navigator.of(context).pop(),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
                    ),
                  ),

                  // ── Body ──
                  Expanded(
                    child: state.status == PrescriptionStatus.loading
                        ? const DetailedPrescriptionCardShimmer(itemCount: 3)
                        : ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: screenHorizontalSpacePadding, top: 12, bottom: 6),
                                child: Text(
                                  'Prescribed Medications',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: displayWidth(context) * (isTab ? 0.015 : 0.035),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),

                              state.medications.where((m) => m.name.trim().isNotEmpty).isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 30),
                                        child: Text(
                                          'No medications mapped.',
                                          style: TextStyle(fontFamily: appPoppinFont, color: Colors.grey.shade400),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: state.medications.where((m) => m.name.trim().isNotEmpty).length,
                                      itemBuilder: (context, index) {
                                        final validMeds = state.medications.where((m) => m.name.trim().isNotEmpty).toList();
                                        return DetailedPrescriptionExpandableCard(
                                          key: ValueKey(validMeds[index].id),
                                          item: validMeds[index],
                                        );
                                      },
                                    ),

                              if (state.additionalNotes.trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Notes',
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: displayWidth(context) * (isTab ? 0.015 : 0.035),
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isDark ? darkModeCardColor : Colors.white,
                                          borderRadius: BorderRadius.circular(fieldBorderRadius),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.06)
                                                : Colors.grey.shade200,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Text(
                                          state.additionalNotes,
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: displayWidth(context) * (isTab ? 0.016 : 0.031),
                                            fontWeight: FontWeight.w400,
                                            color: isDark ? Colors.white70 : Colors.black87,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),

                  // ── Action Buttons ──
                  Container(
                    padding: EdgeInsets.only(
                      left: screenHorizontalSpacePadding,
                      right: screenHorizontalSpacePadding,
                      top: 14,
                      bottom: MediaQuery.of(context).padding.bottom > 0
                          ? MediaQuery.of(context).padding.bottom + 6
                          : 14,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade100,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                            label: const Text(
                              "View PDF",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            onPressed: () {
                              final rawBaseUrl = EnvironmentService.config.accountBaseUrl;
                              final baseUrl = rawBaseUrl.startsWith('http') ? rawBaseUrl : 'https://$rawBaseUrl';
                              final validMeds = state.medications.where((m) => m.name.trim().isNotEmpty).toList();
                              final presId = state.prescriptionId ?? (validMeds.isNotEmpty ? validMeds.first.id : '');
                              final effectivePdfUrl = (state.pdfUrl != null && state.pdfUrl!.isNotEmpty)
                                  ? state.pdfUrl!
                                  : (presId.isNotEmpty ? '$baseUrl/v1/api/auth/prescriptions/$presId/pdf' : '');

                              if (effectivePdfUrl.isNotEmpty) {
                                InAppDocumentViewer.show(
                                  context,
                                  title: 'Digital Prescription',
                                  category: 'Prescription',
                                  fileUrl: effectivePdfUrl,
                                  hospitalName: 'Yira Super Speciality Hospitals',
                                  isAppointmentDoc: true,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Prescription document is being processed.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomElevatedButton(
                            noElevation: true,
                            backgroundColor: Colors.black,
                            height: 50,
                            width: double.infinity,
                            text: "Close View",
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}