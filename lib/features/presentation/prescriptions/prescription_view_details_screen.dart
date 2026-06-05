import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/detailed_prescription_expandable_card.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../di/dependency_injection.dart';
import '../../../core/common_widgets/custom_button.dart';

class PrescriptionViewDetailsScreen extends StatelessWidget {
  const PrescriptionViewDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    return BlocProvider(
      create: (context) => sl<PrescriptionBloc>()..add(LoadPrescriptionData()),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: BlocBuilder<PrescriptionBloc, PrescriptionState>(
            builder: (context, state) {
              if (state.status == PrescriptionStatus.loading) {
                return const Center(child: CircularProgressIndicator.adaptive());
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
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
                              CommonText(
                                'Details',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: displayWidth(context) * (isTab ? 0.024 : 0.045),
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              CommonText(
                                'Prescription View ID: 8r793049884',
                                maxLines: 2,
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
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 10),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark ? darkModeCardColor : Colors.white,
                            borderRadius: BorderRadius.circular(fieldBorderRadius),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade200.withOpacity(0.5),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CommonText(
                                'Diagnosis',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: displayWidth(context) * (isTab ? 0.014 : 0.035),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: theme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              CommonText(
                                state.diagnoses.isNotEmpty
                                    ? state.diagnoses.join(', ')
                                    : 'Hyperoxia, Hypermetropia',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: displayWidth(context) * (isTab ? 0.024 : 0.031),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: screenHorizontalSpacePadding, top: fieldSpace, bottom: 6),
                          child: CommonText(
                            'Medication Details',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: displayWidth(context) * (isTab ? 0.015 : 0.035),
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),

                        state.medications.isEmpty
                            ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 30),
                            child: CommonText('No medications mapped.', style: TextStyle(fontFamily: appPoppinFont, color: Colors.grey.shade400)),
                          ),
                        )
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.medications.length,
                          itemBuilder: (context, index) {
                            return DetailedPrescriptionExpandableCard(
                              key: ValueKey(state.medications[index].id),
                              item: state.medications[index],
                            );
                          },
                        ),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark ? darkModeCardColor : Colors.white,
                            borderRadius: BorderRadius.circular(fieldBorderRadius),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade200.withOpacity(0.5),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CommonText(
                                'Additional Notes',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: displayWidth(context) * (isTab ? 0.014 : 0.035),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              CommonText(
                                'Personal & Clinical Data: If you are a patient, access your medical records directly through your local healthcare provider, or check health insurance portals (such as those tied to Ayushman Bharat or local state programs) for digital health records.',
                                softWrap: true,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: displayWidth(context) * (isTab ? 0.016 : 0.031),
                                  fontWeight: FontWeight.w400,
                                  height: 1.45,
                                  color: isDark ? Colors.grey.shade400 : additionalNotesColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade100,
                        width: 1,
                      ),
                    ),
                    child:CustomElevatedButton(
                      noElevation: true,
                      backgroundColor: Colors.black,
                      height: 50,
                      width: double.infinity,
                      text: "Close View",
                      onPressed: () {
                      },
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