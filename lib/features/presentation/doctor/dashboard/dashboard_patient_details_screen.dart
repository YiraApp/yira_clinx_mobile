import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/shimmer_widgets/patient_details_shimmer.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/patient_deatils_bloc/patient_details_bloc.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/clinical_note_item_tile.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/dashboard_patient_action_hub_item.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/dashboard_patient_card_wrapper.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/dashboard_patient_contact_row.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/dashboard_patient_vital_tile.dart';
import '../../../../core/common_input_fields/common_input_field_unlimited.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/common_widgets/custom_border_button.dart';
import '../../../../core/common_widgets/custom_button.dart';
import '../../../domain/entities/dashboard/dashboard_patient_details_entity.dart';
import '../../../domain/entities/dashboard/doctor_dashboard_entity.dart';

class DashboardPatientDetails{
  final TodaysScheduleEntity? todaysSchedule;
  final RecentPatientsEntity? recentPatients;
  final bool? isRecent;

  DashboardPatientDetails(this.todaysSchedule, this.recentPatients, this.isRecent);
}

class DashboardPatientDetailsScreen extends StatelessWidget {
  final DashboardPatientDetails? dashboardPatientDetails;
  const DashboardPatientDetailsScreen({super.key, this.dashboardPatientDetails});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTab = isTablet(context);

    return BlocProvider<PatientDetailsBloc>(
      create: (context) => PatientDetailsBloc(
        detailsUseCase: sl(),
        clinicalUseCase: sl(),
      )..add(const LoadPatientScreenData(appointmentId: '1')),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: BlocBuilder<PatientDetailsBloc, PatientDetailsState>(
          builder: (context, state) {
            final bool hasPatientData = state.patientData != null;

            if (state is PatientDetailsLoading && !hasPatientData) {
              return PatientDetailsShimmer(isDark: isDark, isTab: isTab);
            }

            if (state is PatientDetailsError && !hasPatientData) {
              return Center(child: CommonText(state.message));
            }

            if (!hasPatientData) {
              return PatientDetailsShimmer(isDark: isDark, isTab: isTab);
            }

            final details = state.patientData!;
            final info = details.data?.patientInfo;
            final contact = details.data?.contactInformation;
            final vitals = details.data?.latestVitals;
            final medical = details.data?.medicalInformation;
            final insurance = details.data?.insurance;

            final clinicalNotesEntity = state.clinicalNotesData;

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: primaryColor,
                  automaticallyImplyLeading: false,
                  toolbarHeight: kToolbarHeight + 16,
                  titleSpacing: screenHorizontalSpacePadding,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: CommonText(
                              "MN",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                color: Colors.white,
                                fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.035,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CommonText(
                                info?.name ?? '--',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  color: Colors.white,
                                  fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.036,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              CommonText(
                                "${info?.age ?? '--'} yrs, ${info?.gender ?? '--'}",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.03,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: screenTopPadding,
                      left: screenHorizontalSpacePadding,
                      right: screenHorizontalSpacePadding,
                      bottom: fieldSpace,
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: fieldSpace),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                CommonText(
                                  "Last: ${info?.lastVisit ?? '--'}",
                                  style: TextStyle(
                                    fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.028,
                                    fontFamily: appPoppinFont,
                                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            DashBoardPatientActionHubItem(icon: Icons.calendar_month, label: "Schedule", iconColor: Colors.blue, onTap: () {}, isTab: isTab),
                            DashBoardPatientActionHubItem(isTab: isTab, icon: Icons.science_outlined, label: "Prescribe", iconColor: Colors.green, onTap: () {}),
                            DashBoardPatientActionHubItem(isTab: isTab, icon: Icons.assignment_outlined, label: "Records", iconColor: Colors.teal, onTap: () {}),
                            DashBoardPatientActionHubItem(isTab: isTab, icon: Icons.cloud_upload_outlined, label: "Documents", iconColor: Colors.orange, onTap: () {}),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: DashBoardPatientDetailCardWrapper(
                    title: "Contact Information",
                    isTab: isTab,
                    child: Column(
                      children: [
                        DashBoardPatientContactRow(icon: Icons.phone_outlined, value: contact?.phone ?? '', isTab: isTab),
                        Divider(height: 30, thickness: 0.5, color: Colors.grey.withOpacity(0.2)),
                        DashBoardPatientContactRow(icon: Icons.mail_outline, value: contact?.email ?? '', isTab: isTab),
                        Divider(height: 30, thickness: 0.5, color: Colors.grey.withOpacity(0.2)),
                        DashBoardPatientContactRow(icon: Icons.location_on_outlined, value: contact?.location ?? "No location provided", isTab: isTab),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: fieldSpace),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonText(
                          "Latest Vitals",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontWeight: FontWeight.w500,
                            fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.035,
                          ),
                        ),
                        const SizedBox(height: titleSpace),
                        _buildVitalsSection(context, vitals, isTab),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: DashBoardPatientDetailCardWrapper(
                    isTab: isTab,
                    title: "Medical Information",
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CommonText(
                          "Blood Group",
                          style: TextStyle(
                            fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.033,
                            fontFamily: appPoppinFont,
                          ),
                        ),
                        CommonText(
                          medical?.bloodGroup ?? "--",
                          style: TextStyle(
                            fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.033,
                            fontFamily: appPoppinFont,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: fieldSpace, bottom: fieldSpace),
                    child: DashBoardPatientDetailCardWrapper(
                      isTab: isTab,
                      title: "Insurance",
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shield_outlined, color: Color(0xFF0066FF), size: 22),
                              const SizedBox(width: 8),
                              CommonText(
                                insurance?.provider ?? "No Insurance Provider",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.035,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: fieldSpace),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CommonText(
                                    "Policy Number",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: appPoppinFont,
                                      fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.03,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  CommonText(
                                    insurance?.policyNumber ?? "-",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: appPoppinFont,
                                      fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.035,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CommonText(
                                    "Valid Till",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: appPoppinFont,
                                      fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.03,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  CommonText(
                                    insurance?.validTill ?? "-",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: appPoppinFont,
                                      fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.035,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: DashBoardPatientDetailCardWrapper(
                    isTab: isTab,
                    title: "Clinical Notes",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 120,
                          child: CommonInputFieldUnlimited(
                            hintText: "Enter clinical notes...",
                            borderRadius: fieldBorderRadius,
                            validator: (value) => null,
                            onChanged: (text) {},
                          ),
                        ),
                        const SizedBox(height: titleSpace),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommonText(
                              "Adding as Dr. Rajesh Nagalingam",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.028,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: fieldSpace),
                            Row(
                              children: [
                                Expanded(
                                  child: CommonBorderButton(
                                    isPatientDetail: true,
                                    height: 35,
                                    text: 'Clear',
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: CustomElevatedButton(
                                    text: "Save Note",
                                    noElevation: true,
                                    onPressed: () {},
                                    width: double.infinity,
                                    height: 35,
                                    borderRadius: 8,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (state is PatientDetailsLoading && clinicalNotesEntity == null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: PatientDetailsShimmer(isDark: isDark, isTab: isTab),
                            ),
                          )
                        else if (state is PatientDetailsError && clinicalNotesEntity == null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: CommonText(state.message),
                            ),
                          )
                        else if (clinicalNotesEntity?.data?.clinicalNotes == null ||
                              clinicalNotesEntity!.data!.clinicalNotes!.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CommonText("No clinical notes recorded yet."),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: clinicalNotesEntity.data!.clinicalNotes!.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final note = clinicalNotesEntity.data!.clinicalNotes![index];
                                return ClinicalNoteItemTile(
                                  doctorName: note.doctorName ?? '--',
                                  date: note.date ?? '--',
                                  text: note.note ?? '--',
                                  isTab: isTab,
                                );
                              },
                            ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVitalsSection(BuildContext context, LatestVitalsEntity? vitals, bool isTab) {
    final List<Widget> vitalTiles = [
      DashBoardPatientVitalTile(
        isTab: isTab,
        label: "Blood Pressure",
        value: vitals?.bloodPressure?.value,
        unit: vitals?.bloodPressure?.unit ?? "mmHg",
        icon: Icons.favorite,
        themeColor: Colors.pink.shade400,
      ),
      DashBoardPatientVitalTile(
        isTab: isTab,
        label: "Pulse",
        value: vitals?.pulse?.value,
        unit: vitals?.pulse?.unit ?? "bpm",
        icon: Icons.bolt,
        themeColor: Colors.pink.shade300,
      ),
      DashBoardPatientVitalTile(
        isTab: isTab,
        label: "Temperature",
        value: vitals?.temperature?.value,
        unit: vitals?.temperature?.unit ?? "°F",
        icon: Icons.thermostat,
        themeColor: Colors.amber.shade600,
      ),
      DashBoardPatientVitalTile(
        isTab: isTab,
        label: "SpO2",
        value: vitals?.spo2?.value,
        unit: vitals?.spo2?.unit ?? "%",
        icon: Icons.opacity,
        themeColor: Colors.blue.shade400,
      ),
      DashBoardPatientVitalTile(
        isTab: isTab,
        label: "Weight",
        value: vitals?.weight?.value,
        unit: vitals?.weight?.unit ?? "kg",
        icon: Icons.scale,
        themeColor: Colors.green.shade400,
      ),
      DashBoardPatientVitalTile(
        isTab: isTab,
        label: "Height",
        value: vitals?.height?.value,
        unit: vitals?.height?.unit ?? "cm",
        icon: Icons.straighten,
        themeColor: Colors.purple.shade300,
      ),
    ];

    if (isTab) {
      return SizedBox(
        height: 110.0,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: vitalTiles.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) => SizedBox(width: 160.0, child: vitalTiles[index]),
        ),
      );
    } else {
      return GridView.count(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: MediaQuery.of(context).size.shortestSide >= 600 ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: vitalTiles,
      );
    }
  }
}