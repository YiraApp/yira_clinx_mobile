import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/clinical_note_item_tile.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/dashboard_patient_action_hub_item.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/dashboard_patient_card_wrapper.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/dashboard_patient_contact_row.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/dashboard_patient_vital_tile.dart';

import '../../../../core/common_input_fields/common_input_field_unlimited.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/common_widgets/custom_border_button.dart';
import '../../../../core/common_widgets/custom_button.dart';
import 'doctor_dashboard_bloc/doctor_dashboard_bloc.dart';

class DashboardPatientDetailsScreen extends StatefulWidget {
  const DashboardPatientDetailsScreen({super.key});

  @override
  State<DashboardPatientDetailsScreen> createState() =>
      _DashboardPatientDetailsScreenState();
}

class _DashboardPatientDetailsScreenState
    extends State<DashboardPatientDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DoctorDashboardBloc>().add(
      FetchPatientDetails(patientId: '1'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<DoctorDashboardBloc, DoctorDashboardState>(
        builder: (context, state) {
          if (state is DoctorDashboardLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (state is! PatientDetailsLoadedState) {
            return const Center(child: CommonText("No Patient Profile Loaded"));
          }

          final data = state.patientData;
          final vitals = data["vitals"] as Map<String, dynamic>;
          final insurance = data["insurance"] as Map<String, dynamic>;
          final notes = data["notes"] as List<dynamic>;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                snap: false,
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
                              fontSize: displayWidth(context) * 0.035,
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
                              'Mani N',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                color: Colors.white,
                                fontSize: displayWidth(context) * 0.036,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            CommonText(
                              "${data["age"]} yrs, ${data["gender"]}",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                color: Colors.white.withOpacity(0.8),
                                fontSize: displayWidth(context) * 0.03,
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
                                "Last: ${data["last_updated"] ?? '--'}",
                                style: TextStyle(
                                  fontSize: displayWidth(context) * 0.028,
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
                          DashBoardPatientActionHubItem(
                            icon: Icons.calendar_month,
                            label: "Schedule",
                            iconColor: Colors.blue,
                            onTap: () {},
                          ),
                          DashBoardPatientActionHubItem(
                            icon: Icons.science_outlined,
                            label: "Prescribe",
                            iconColor: Colors.green,
                            onTap: () {},
                          ),
                          DashBoardPatientActionHubItem(
                            icon: Icons.assignment_outlined,
                            label: "Records",
                            iconColor: Colors.teal,
                            onTap: () {},
                          ),
                          DashBoardPatientActionHubItem(
                            icon: Icons.cloud_upload_outlined,
                            label: "Documents",
                            iconColor: Colors.orange,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: DashBoardPatientDetailCardWrapper(
                  title: "Contact Information",
                  child: Column(
                    children: [
                      DashBoardPatientContactRow(
                        icon: Icons.phone_outlined,
                        value: data["phone"],
                      ),
                      Divider(
                        height: 30,
                        thickness: 0.5,
                        color: Colors.grey.withOpacity(0.2),
                      ),
                      DashBoardPatientContactRow(
                        icon: Icons.mail_outline,
                        value: data["email"],
                      ),
                      Divider(
                        height: 30,
                        thickness: 0.5,
                        color: Colors.grey.withOpacity(0.2),
                      ),
                      DashBoardPatientContactRow(
                        icon: Icons.location_on_outlined,
                        value: data["location"] ?? "No location provided",
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: screenHorizontalSpacePadding,
                    vertical: fieldSpace,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonText(
                        "Latest Vitals",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w500,
                          fontSize: displayWidth(context) * 0.035,
                        ),
                      ),
                      const SizedBox(height: titleSpace),
                      GridView.count(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount:
                        MediaQuery.of(context).size.shortestSide >= 600
                            ? 3
                            : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [
                          DashBoardPatientVitalTile(
                            label: "Blood Pressure",
                            value: vitals["bp"],
                            unit: "mmHg",
                            icon: Icons.favorite,
                            themeColor: Colors.pink.shade400,
                          ),
                          DashBoardPatientVitalTile(
                            label: "Pulse",
                            value: vitals["pulse"],
                            unit: "bpm",
                            icon: Icons.bolt,
                            themeColor: Colors.pink.shade300,
                          ),
                          DashBoardPatientVitalTile(
                            label: "Temperature",
                            value: vitals["temp"],
                            unit: "°F",
                            icon: Icons.thermostat,
                            themeColor: Colors.amber.shade600,
                          ),
                          DashBoardPatientVitalTile(
                            label: "SpO2",
                            value: vitals["spo2"],
                            unit: "%",
                            icon: Icons.opacity,
                            themeColor: Colors.blue.shade400,
                          ),
                          DashBoardPatientVitalTile(
                            label: "Weight",
                            value: vitals["weight"],
                            unit: "kg",
                            icon: Icons.scale,
                            themeColor: Colors.green.shade400,
                          ),
                          DashBoardPatientVitalTile(
                            label: "Height",
                            value: vitals["height"],
                            unit: "cm",
                            icon: Icons.straighten,
                            themeColor: Colors.purple.shade300,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: DashBoardPatientDetailCardWrapper(
                  title: "Medical Information",
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CommonText(
                        "Blood Group",
                        style: TextStyle(
                          fontSize: displayWidth(context) * 0.033,
                          fontFamily: appPoppinFont,
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.pink.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: fieldSpace,
                    bottom: fieldSpace,
                  ),
                  child: DashBoardPatientDetailCardWrapper(
                    title: "Insurance",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              color: Color(0xFF0066FF),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            CommonText(
                              insurance["provider"],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontFamily: appPoppinFont,
                                fontSize: displayWidth(context) * 0.035,
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
                                    fontSize: displayWidth(context) * 0.03,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CommonText(
                                  insurance["policy_number"],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: appPoppinFont,
                                    fontSize: displayWidth(context) * 0.035,
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
                                    fontSize: displayWidth(context) * 0.03,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CommonText(
                                  insurance["valid_till"] ?? "-",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: appPoppinFont,
                                    fontSize: displayWidth(context) * 0.035,
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
                      SizedBox(height: titleSpace),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommonText(
                            "Adding as Dr. bhargava c",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: displayWidth(context) * 0.028,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          SizedBox(height: fieldSpace),
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
                              SizedBox(width: 15),
                              Expanded(
                                child: CustomElevatedButton(
                                  text: "Save Note",
                                  noElevation: true,
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
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
                      ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: notes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return ClinicalNoteItemTile(
                            doctorName: note["doctor"],
                            date: note["date"],
                            text: note["text"],
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
    );
  }
}