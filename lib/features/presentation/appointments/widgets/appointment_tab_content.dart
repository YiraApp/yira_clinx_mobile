import 'package:flutter/material.dart';
import '../../../../core/colors/colors.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';
import '../../../domain/entities/appointments/appointment_entity.dart';
import 'appointment_card.dart';

class AppointmentTabContent extends StatelessWidget {
  final List<Appointment> appointments;
  final String tabTitle;
  final String emptyMessage;
  final VoidCallback? onBookAppointment;
  final int? tabIndex;

  const AppointmentTabContent({
    super.key,
    required this.appointments,
    required this.tabTitle,
    required this.emptyMessage,
    this.onBookAppointment,
    this.tabIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (appointments.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  size: displayWidth(context) * 0.18,
                  color: Theme.of(context).hintColor.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                CommonText(
                  "No Records Available",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w600,
                    fontSize: displayWidth(context) * 0.04,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                CommonText(
                  emptyMessage,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w400,
                    fontSize: displayWidth(context) * 0.03,
                    color: Theme.of(context).hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: onBookAppointment,
                    icon: const Icon(Icons.add, size: 16),
                    label: CommonText(
                      "Book Appointment",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontWeight: FontWeight.w500,
                        fontSize: displayWidth(context) * 0.03,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonText(
                tabTitle,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: displayWidth(context) * 0.036,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: fieldSpace),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            itemCount: appointments.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return AppointmentCard(
                appointment: appointment,
                isTeleConsultation: tabIndex == 3,
                onEdit: () {},
              );
            },
          ),
        ),
      ],
    );
  }
}