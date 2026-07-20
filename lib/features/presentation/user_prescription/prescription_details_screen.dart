import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/common_widgets/common_text.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/user_prescription/prescription_bloc/prescription_bloc.dart';
import '../../../di/dependency_injection.dart';

class PrescriptionDetailScreen extends StatelessWidget {
  final String prescriptionId;

  const PrescriptionDetailScreen({super.key, required this.prescriptionId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double width = displayWidth(context);

    return BlocProvider(
      create: (context) => sl<MedicationBloc>()..add(LoadPrescriptionDetails(prescriptionId)),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CommonAppBar(
         titleText: "Prescription Details",
        ),
        body: BlocBuilder<MedicationBloc, MedicationState>(
          builder: (context, state) {
            if (state.status == MedicationStatus.loading || state.status == MedicationStatus.initial) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            final data = state.selectedPrescriptionDetail;
            if (data == null) {
              return Center(
                child: CommonText(
                  "Data not found",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontFamily: appPoppinFont,
                    fontSize: width * 0.04,
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderGrid(context, data, theme),
                  SizedBox(height: width * 0.06),
                  CommonText(
                    "Medications",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: appPoppinFont,
                      fontSize: width * 0.042,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: width * 0.03),
                  ...List.generate(
                    data['medications'].length,
                        (index) => _buildMedicationCard(context, data['medications'][index], theme),
                  ),
                  SizedBox(height: width * 0.06),
                  CommonText(
                    "Clinical Notes",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: appPoppinFont,
                      fontSize: width * 0.042,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: width * 0.02),
                  _buildNotesBox(context, data['notes'], theme),
                  SizedBox(height: width * 0.08),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderGrid(BuildContext context, Map<String, dynamic> data, ThemeData theme) {
    return Wrap(
      runSpacing: displayWidth(context) * 0.04,
      children: [
        _infoTile(context, "Doctor:", data['doctor'], theme),
        _infoTile(context, "Specialty:", data['specialty'], theme),
        _infoTile(context, "Date:", data['date'], theme),
        _infoTile(context, "Condition:", data['condition'], theme),
        _statusTile(context, "Status:", data['status'], theme),
        _infoTile(context, "Pharmacy:", data['pharmacy'], theme),
      ],
    );
  }

  Widget _infoTile(BuildContext context, String label, String value, ThemeData theme) {
    final double width = displayWidth(context);
    return SizedBox(
      width: width * 0.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: appPoppinFont,
              fontSize: width * 0.03,
            ),
          ),
          CommonText(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: appPoppinFont,
              fontWeight: FontWeight.w600,
              fontSize: width * 0.035,
            ),
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _statusTile(BuildContext context, String label, String status, ThemeData theme) {
    final double width = displayWidth(context);
    return SizedBox(
      width: width * 0.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: appPoppinFont,
                fontSize: width * 0.03,
              )
          ),
          const SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: width * 0.025, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(fieldBorderRadius),
            ),
            child: CommonText(
              status,
              style: TextStyle(
                fontFamily: appPoppinFont,
                color: Colors.green,
                fontSize: width * 0.028,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(BuildContext context, Map<String, dynamic> med, ThemeData theme) {
    final double width = displayWidth(context);
    return Container(
      margin: EdgeInsets.only(bottom: width * 0.03),
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface
            : theme.cardColor,
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white10
              : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(fieldBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CommonText(
                med['name'],
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: appPoppinFont,
                  fontSize: width * 0.038,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _pillChip(context, "${med['remaining']} remaining", theme),
            ],
          ),
          CommonText(
            med['dosage'],
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: appPoppinFont,
              fontSize: width * 0.032,
            ),
          ),
          SizedBox(height: width * 0.04),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Align top for unequal text lengths
            children: [
              Expanded(
                child: _infoTile(context, "Frequency:", med['frequency'], theme),
              ),
              SizedBox(width: width * 0.02), // Optional spacing between tiles
              Expanded(
                child: _infoTile(context, "Duration:", med['duration'], theme),
              ),
            ],
          ),
          SizedBox(height: width * 0.03),
          CommonText(
              "Instructions:",
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: appPoppinFont,
                fontSize: width * 0.03,
              )
          ),
          CommonText(
            med['instructions'],
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: appPoppinFont,
              fontWeight: FontWeight.w600,
              fontSize: width * 0.035,
            ),
            softWrap: true,
            maxLines: 5,
          ),
          SizedBox(height: width * 0.03),
          CommonText(
              "Refills Available:",
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: appPoppinFont,
                fontSize: width * 0.03,
              )
          ),
          CommonText(
            med['refills'].toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: appPoppinFont,
              fontWeight: FontWeight.w600,
              fontSize: width * 0.035,
            ),
          ),
          SizedBox(height: width * 0.04),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CommonText(
                  "Usage Progress",
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: appPoppinFont,
                    fontSize: width * 0.028,
                  )
              ),
              CommonText(
                "${(med['progress'] * 100).toInt()}%",
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: appPoppinFont,
                  fontSize: width * 0.028,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: med['progress'],
            backgroundColor: theme.brightness == Brightness.dark
                ? Colors.white10
                : Colors.grey.shade100,
            color: theme.primaryColor,
            minHeight: 6,
            borderRadius: BorderRadius.circular(fieldBorderRadius),
          ),
        ],
      ),
    );
  }

  Widget _pillChip(BuildContext context, String text, ThemeData theme) {
    final double width = displayWidth(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(fieldBorderRadius),
      ),
      child: CommonText(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontFamily: appPoppinFont,
          color: theme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: width * 0.025,
        ),
      ),
    );
  }

  Widget _buildNotesBox(BuildContext context, String notes, ThemeData theme) {
    final double width = displayWidth(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(fieldBorderRadius),
      ),
      child: CommonText(
        notes,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: appPoppinFont,
          height: 1.4,
          fontSize: width * 0.032,
        ),
        softWrap: true,
        maxLines: 10,
      ),
    );
  }
}