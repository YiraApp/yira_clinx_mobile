import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_widgets/common_text.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class PrescriptionCard extends StatelessWidget {
  final String title;
  final String doctor;
  final String date;
  final String status;
  final String pharmacy;
  final BuildContext context;
  final List<Map<String, dynamic>> medications;

  const PrescriptionCard({
    super.key,
    required this.title,
    required this.doctor,
    required this.date,
    required this.status,
    required this.pharmacy,
    required this.medications, required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isActive = status.toLowerCase() == "active";
    final double screenWidth = displayWidth(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.3 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.045),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER SECTION ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAdaptiveIconBox(colorScheme),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: displayWidth(context) / 2,
                        child: CommonText(
                          maxLines: null,
                          softWrap: true,
                          title,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontWeight: FontWeight.w600,
                            fontSize: displayWidth(context) * 0.034,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildLabel(
                        context,
                        Icons.person_2_outlined,
                        doctor,
                        colorScheme,
                      ),
                      _buildLabel(
                        context,
                        Icons.calendar_month_outlined,
                        date,
                        colorScheme,
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(context, isActive, colorScheme),
              ],
            ),

             Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(thickness: 1.5,color: Colors.grey.withOpacity(0.1),),
            ),

            CommonText(
              "MEDICATIONS",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontWeight: FontWeight.w600,
                fontSize: displayWidth(context)*0.03,
                letterSpacing: 1.2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            ...medications.map(
                  (med) => _buildMedItem(med, colorScheme, isActive),
            ),

            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(fieldBorderRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_pharmacy_rounded,
                    size: 16,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CommonText(
                      "Pharmacy: $pharmacy",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: displayWidth(context)*0.026,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            LayoutBuilder(
              builder: (context, constraints) {
                bool isSmall = constraints.maxWidth < 280;
                return isSmall
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isActive)
                      _buildRefillBtn(context, colorScheme, true),
                    if (isActive) const SizedBox(height: 10),
                    _buildDetailsBtn(context, colorScheme, true),
                  ],
                )
                    : Row(
                  children: [
                    if (isActive) ...[
                      Expanded(
                        child: _buildRefillBtn(
                          context,
                          colorScheme,
                          false,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: _buildDetailsBtn(
                        context,
                        colorScheme,
                        false,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdaptiveIconBox(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.medication_liquid_sharp,
        color: colorScheme.onPrimaryContainer,
        size: 26,
      ),
    );
  }

  Widget _buildStatusBadge(
      BuildContext context,
      bool active,
      ColorScheme colorScheme,
      ) {
    final baseColor = active ? Colors.green : colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(color: baseColor.withOpacity(0.2)),
      ),
      child: CommonText(
        status,
        style: TextStyle(
          fontFamily: appPoppinFont,
          color: baseColor,
          fontSize: displayWidth(context) * 0.024,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLabel(
      BuildContext context,
      IconData icon,
      String text,
      ColorScheme colorScheme,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          SizedBox(
            width: displayWidth(context) / 2.6,
            child: CommonText(
              maxLines: null,
              softWrap: true,
              text,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontWeight: FontWeight.normal,
                fontSize: displayWidth(context) * 0.026,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedItem(
      Map<String, dynamic> med,
      ColorScheme colorScheme,
      bool active,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CommonText(
                  med['name'],
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context)*0.028,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (med['left'] != null)
                CommonText(
                  med['left'],
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context)*0.026,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),

          // SNOMED Code Label
          if (med['code'] != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: CommonText(
                "MEDICATION (SNOMED) ${med['code']}",
                style:  TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: displayWidth(context)*0.025,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const SizedBox(height: 6),
          CommonText(
            med['dosage'],
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: displayWidth(context)*0.028,
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (active && med['progress'] != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(fieldBorderRadius),
              child: LinearProgressIndicator(
                value: med['progress'],
                minHeight: 5,
                backgroundColor: colorScheme.outlineVariant.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CommonText(
                  "${(med['progress'] * 100).toInt()}% Completed",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context)*0.025,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRefillBtn(
      BuildContext context,
      ColorScheme colorScheme,
      bool full,
      ) {
    return OutlinedButton.icon(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        minimumSize: Size(full ? double.infinity : 0, 40),
        side: const BorderSide(color: Colors.red, width: 1.2),
        foregroundColor: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
      ),
      icon: const Icon(Icons.refresh_rounded, size: 16),
      label: CommonText(
        "Request Refill",
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontWeight: FontWeight.w500,
          fontSize: displayWidth(context) * 0.028,
        ),
      ),
    );
  }

  Widget _buildDetailsBtn(
      BuildContext context,
      ColorScheme colorScheme,
      bool full,
      ) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        minimumSize: Size(full ? double.infinity : 0, 40),
        backgroundColor: colorScheme.primary,
        // foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
      ),
      child: CommonText(
        "View Details",
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontWeight: FontWeight.w500,
          fontSize: displayWidth(context) * 0.028,
        ),
      ),
    );
  }
}