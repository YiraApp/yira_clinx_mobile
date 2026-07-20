import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/customer_card_section.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/input_search_field.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/prescribed_medication_card.dart';
import '../../../core/common_input_fields/common_input_field_unlimited.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/common_widgets/custom_border_button.dart';
import '../../../core/common_widgets/custom_button.dart';
import '../../../di/dependency_injection.dart';

class AddPrescriptionRecordScreen extends StatelessWidget {
  const AddPrescriptionRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isTab = isTablet(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return BlocProvider(
      create: (context) => sl<PrescriptionBloc>()..add(LoadPrescriptionData()),
      child: Scaffold(
        appBar: CommonAppBar(
          actions: [],
          titleText: "Create Prescription Record",
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom > 0
                ? MediaQuery.of(context).padding.bottom + 8
                : 16,
          ),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light
                ? Colors.white
                : theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(fieldBorderRadius),
              topRight: Radius.circular(fieldBorderRadius),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: fieldBorderRadius,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: CommonBorderButton(
                  height: buttonHeight,
                  text: 'Cancel',
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomElevatedButton(
                  noElevation: true,
                  height: buttonHeight,
                  width: displayWidth(context),
                  text: "save",
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<PrescriptionBloc, PrescriptionState>(
            builder: (context, state) {
              if (state.status == PrescriptionStatus.loading) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    CustomCardSection(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: isTablet(context) ? 28 : 22,
                            backgroundColor: theme.primaryColor,
                            child: CommonText(
                              'DM',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize:isTab
                                    ? displayWidth(context) * 0.018 :displayWidth(context) * 0.032,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CommonText(
                                      'Demo Manikanta',
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize:isTab
                                            ? displayWidth(context) * 0.02: displayWidth(context) * 0.035,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor,
                                        borderRadius: BorderRadius.circular(fieldBorderRadius),
                                      ),
                                      child: CommonText(
                                        '30Y',
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize:
                                          isTab
                                              ? displayWidth(context) * 0.018:displayWidth(context) * 0.03,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      size: 10,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    CommonText(
                                      'neelimanikanta02@gmail.com',
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize:isTab
                                            ? displayWidth(context) * 0.018: displayWidth(context) * 0.03,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.call_outlined,
                                      size: 10,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    CommonText(
                                      '+91 9908875796',
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize:isTab
                                            ? displayWidth(context) * 0.018: displayWidth(context) * 0.03,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Diagnosis Card
                    CustomCardSection(
                      child: InputSearchChipField(
                        isTab: isTab,
                        title: 'Diagnosis',
                        subtitle:
                            'Search and add diagnoses — press Enter to add custom, click X to remove',
                        hintText: 'Add more...',
                        icon: Icons.assignment_outlined,
                        selectedTokens: state.diagnoses,
                        onRemoveToken: (token) {
                          context.read<PrescriptionBloc>().add(
                            RemoveDiagnosis(token),
                          );
                        },
                        onSubmitted: (val) {
                          context.read<PrescriptionBloc>().add(
                            AddDiagnosis(val),
                          );
                        },
                      ),
                    ),

                    CustomCardSection(
                      child: InputSearchChipField(
                        isTab: isTab,
                        title: 'Add Medications',
                        subtitle:
                            'Search and add medications — press Enter to add custom, click X to remove',
                        hintText: 'Add more...',
                        icon: Icons.add,
                        selectedTokens: state.medications
                            .map((m) => m.name)
                            .toList(),
                        onRemoveToken: (token) {
                          final match = state.medications.firstWhere(
                            (element) => element.name == token,
                          );
                          context.read<PrescriptionBloc>().add(
                            RemoveMedication(match.id),
                          );
                        },
                        onSubmitted: (val) {
                          context.read<PrescriptionBloc>().add(
                            AddMedication(val),
                          );
                        },
                      ),
                    ),

                    CustomCardSection(
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              context.read<PrescriptionBloc>().add(
                                TogglePrescriptionExpansion(),
                              );
                            },
                            borderRadius: BorderRadius.circular(fieldBorderRadius),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CommonText(
                                    'Prescribed Medications (${state.medications.length})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: appPoppinFont,
                                      fontSize:isTab
                                          ? displayWidth(context) * 0.02: displayWidth(context) * 0.038,
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: state.isPrescriptionExpanded
                                        ? 0.0
                                        : 0.5,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.fastOutSlowIn,
                                    child: Icon(
                                      Icons.keyboard_arrow_up,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          AnimatedSize(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.fastOutSlowIn,
                            child: Container(
                              width: double.infinity,
                              clipBehavior: Clip.antiAlias,
                              decoration: const BoxDecoration(),
                              child: state.isPrescriptionExpanded
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        top: fieldSpace,
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: state.medications.length,
                                        itemBuilder: (context, index) {
                                          final item = state.medications[index];
                                          return PrescribedPrescriptionCard(
                                            isTab: isTab,
                                            key: ValueKey(item.id),
                                            medicineName: item.name,
                                            currentDosage: item.dosage,
                                            currentFreq: item.frequency,
                                            currentDuration: item.duration,
                                            currentRoute: item.route,
                                            onRemove: () {
                                              context
                                                  .read<PrescriptionBloc>()
                                                  .add(
                                                    RemoveMedication(item.id),
                                                  );
                                            },
                                            onDosageChanged: (val) => context
                                                .read<PrescriptionBloc>()
                                                .add(
                                                  UpdateMedicationDetails(
                                                    id: item.id,
                                                    dosage: val,
                                                  ),
                                                ),
                                            onFreqChanged: (val) => context
                                                .read<PrescriptionBloc>()
                                                .add(
                                                  UpdateMedicationDetails(
                                                    id: item.id,
                                                    frequency: val,
                                                  ),
                                                ),
                                            onDurationChanged: (val) => context
                                                .read<PrescriptionBloc>()
                                                .add(
                                                  UpdateMedicationDetails(
                                                    id: item.id,
                                                    duration: val,
                                                  ),
                                                ),
                                            onRouteChanged: (val) => context
                                                .read<PrescriptionBloc>()
                                                .add(
                                                  UpdateMedicationDetails(
                                                    id: item.id,
                                                    route: val,
                                                  ),
                                                ),
                                          );
                                        },
                                      ),
                                    )
                                  : const SizedBox(
                                      width: double.infinity,
                                      height: 0,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CustomCardSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notes,
                                color: theme.primaryColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              CommonText(
                                'Additional Notes',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab? displayWidth(context) * 0.02:displayWidth(context) * 0.038,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 30,
                              bottom: 12,
                            ),
                            child: CommonText(
                              'Any special instructions for the patient or pharmacy',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontFamily: appPoppinFont,
                                fontSize:isTab? displayWidth(context) * 0.018: displayWidth(context) * 0.028,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 120,
                            child: CommonInputFieldUnlimited(
                              hintText:
                                  "Enter any additional notes or instructions...",
                              borderRadius: fieldBorderRadius,
                              validator: (value) => null,
                              onChanged: (text) {},
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
