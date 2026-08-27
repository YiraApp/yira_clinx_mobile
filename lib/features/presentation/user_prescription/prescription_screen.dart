import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/user_prescription/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/user_prescription/widgets/prescription_card.dart';
import '../../../core/colors/colors.dart';
import '../../../core/common_drop_down/common_drop_down.dart';
import '../../../core/models/medication_insight.dart';
import '../../../di/dependency_injection.dart';
import '../../domain/entities/medication/medication_entity.dart';

import 'package:yiraclinics/core/common_widgets/common_text.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';

class PrescriptionManagementScreen extends StatelessWidget {
  const PrescriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => sl<MedicationBloc>()..add(LoadMedicationData()),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          title: CommonText(
            "Prescription Management",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: displayWidth(context) * 0.045,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.recentNotifications);
              },
              icon: Icon(
                Icons.notifications_none,
                size: 20,
                color: theme.iconTheme.color,
              ),
            ),
          ],
        ),
        body: BlocConsumer<MedicationBloc, MedicationState>(
          listener: (context, state) {
            if (state.status == MedicationStatus.failure) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error ?? "Error")));
            }
          },
          builder: (context, state) {
            if (state.status == MedicationStatus.loading) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    displayWidth(context) * 0.04,
                    16,
                    displayWidth(context) * 0.04,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildSummaryGrid(context, state.summary, isDark),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: displayWidth(context) * 0.04,
                    vertical: 24,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildInsightSection(context, isDark),
                  ),
                ),

                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: displayWidth(context) * 0.04,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: TextField(
                              onChanged: (val) {
                              },
                              style: TextStyle(
                                decorationThickness: 0,
                                fontFamily: appPoppinFont,
                                fontSize: displayWidth(context) * 0.03,
                              ),
                              decoration: InputDecoration(
                                hintStyle: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: displayWidth(context) * 0.03,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                                ),
                                hintText: "Search prescriptions...",
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.blueGrey,
                                  size: 18,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 16,
                                ),

                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.2),
                                    width: 1.0,
                                  ),
                                ),

                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.2),
                                    width: 1.0,
                                  ),
                                ),

                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: displayWidth(context) * 0.33,
                          child: CommonDropdown(
                            title: "Filter by Status",
                            selectedValue: state.selectedStatus ?? "All",
                            options: const [
                              "All",
                              "Active",
                              "Completed",
                              "Pending",
                              "Expired",
                            ],
                            onSelected: (value) {
                              context.read<MedicationBloc>().add(
                                FilterByStatus(value),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


                SliverPadding(
                  padding: EdgeInsets.all(displayWidth(context) * 0.04),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final bool isFirst = index == 0;
                      return PrescriptionCard(
                        context: context,
                        title: isFirst
                            ? "Prescription for Hypertension"
                            : "Prescription for Eczema",
                        doctor: isFirst
                            ? "Dr. Rajesh Kumar - Cardiologist"
                            : "Dr. Priya Sharma - Dermatologist",
                        date: isFirst ? "2024-01-18" : "2024-01-15",
                        status: isFirst ? "Active" : "Completed",
                        pharmacy: isFirst
                            ? "Yira Pharmacy, MG Road"
                            : "MedPlus, Commercial Street",
                        medications: isFirst
                            ? [
                                {
                                  "name": "Lisinopril",
                                  "code": "386873009",
                                  "left": "25/30 left",
                                  "dosage": "10mg - Once daily",
                                  "progress": 0.7,
                                },
                                {
                                  "name": "Amlodipine",
                                  "code": "387585004",
                                  "left": "28/30 left",
                                  "dosage": "5mg - Once daily",
                                  "progress": 0.9,
                                },
                              ]
                            : [
                                {
                                  "name": "Hydrocortisone Cream",
                                  "code": "116601002",
                                  "dosage": "1% - Twice daily",
                                },
                                {
                                  "name": "Cetirizine",
                                  "code": "372682005",
                                  "dosage": "10mg - Once daily",
                                },
                              ],
                      );
                    }, childCount: 2),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(
    BuildContext context,
    MedicationEntity? summary,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double dynamicAspectRatio = (constraints.maxWidth / 2) / 85.0;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: dynamicAspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _statCard(
              context,
              "Total Prescriptions",
              summary?.totalPrescriptions ?? 0,
              Colors.blue,
              isDark,
            ),
            _statCard(
              context,
              "Active Meds",
              summary?.activeMeds ?? 0,
              Colors.blue,
              isDark,
            ),
            _statCard(
              context,
              "Total Medications",
              summary?.totalMedications ?? 0,
              Colors.blue,
              isDark,
            ),
            _statCard(
              context,
              "Need Refill",
              summary?.needRefill ?? 0,
              Colors.red,
              isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(
    BuildContext context,
    String title,
    int value,
    Color valueColor,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CommonText(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: displayWidth(context) * 0.03,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          CommonText(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: displayWidth(context) * 0.045,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    final List<MedicationInsight> insights = [
      MedicationInsight(
        title: "Critical Interaction",
        subTitle: "Lisinopril + Potassium",
        message: "Potential risk of hyperkalemia. Consult physician.",
        isCritical: true,
      ),
      MedicationInsight(
        title: "Dosing Advisory",
        subTitle: "Best time for Amlodipine: morning",
        message:
            "Research suggests morning dosing improves blood pressure control.",
        isCritical: false,
      ),
      MedicationInsight(
        title: "Adherence Status",
        subTitle: "Estimated adherence at 85%",
        message: "Good progress! You've missed 2 doses in the last 14 days.",
        isCritical: false,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.psychology, color: Colors.blue),
            const SizedBox(width: 8),
            CommonText(
              "AI Medication Insights",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontWeight: FontWeight.w600,
                fontSize: displayWidth(context) * 0.04,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: insights.length,
          itemBuilder: (context, index) {
            final item = insights[index];
            final Color bg = item.isCritical
                ? (isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFFEBEE))
                : (primaryColor.withOpacity(0.09));
            final Color text = item.isCritical ? (Colors.red) : (primaryColor);

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == insights.length - 1 ? 0 : 12.0,
              ),
              child: _insightAlert(
                context,
                item.title,
                item.subTitle,
                item.message,
                bg,
                text,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _insightAlert(
    BuildContext context,
    String title,
    String sub,
    String msg,
    Color bg,
    Color text,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            title,
            maxLines: 2,
            style: TextStyle(
              fontFamily: appPoppinFont,
              color: text,
              fontWeight: FontWeight.w600,
              fontSize: displayWidth(context) * 0.03,
            ),
          ),
          CommonText(
            sub,
            maxLines: 2,
            style: TextStyle(
              fontFamily: appPoppinFont,
              color: text,
              fontWeight: FontWeight.w600,
              fontSize: displayWidth(context) * 0.03,
            ),
          ),
          CommonText(
            msg,
            maxLines: 3,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontFamily: appPoppinFont,
              color: text,
              fontSize: displayWidth(context) * 0.03,
            ),
          ),
        ],
      ),
    );
  }
}
