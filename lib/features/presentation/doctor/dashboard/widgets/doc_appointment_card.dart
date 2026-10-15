import 'package:flutter/material.dart';

import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../../../../core/colors/colors.dart';
import '../../../../../core/utils/utils.dart';

class DocAppointmentCard extends StatefulWidget {
  final String initials;
  final String name;
  final String subtitle;
  final String description;
  final String timeOrDate;
  final String statusLabel;
  final Color statusColor;
  final Color statusTextColor;
  final String? patientStatus;
  final VoidCallback? onTap;
  final VoidCallback? onStatusTap;
  final bool isTab;
  final bool isTeleConsultation;
  final VoidCallback? onJoinCall;
  final VoidCallback? onPrescriptionTap;
  final VoidCallback? onRescheduleTap;
  final VoidCallback? onCancelTap;
  final dynamic appointmentDate;
  final bool? canJoinCall;
  final bool isUpdatingStatus;

  const DocAppointmentCard({
    super.key,
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.timeOrDate,
    required this.statusLabel,
    required this.statusColor,
    required this.statusTextColor,
    this.patientStatus,
    this.onTap,
    this.onStatusTap,
    required this.isTab,
    this.isTeleConsultation = false,
    this.onJoinCall,
    this.onPrescriptionTap,
    this.onRescheduleTap,
    this.onCancelTap,
    this.appointmentDate,
    this.canJoinCall,
    this.isUpdatingStatus = false,
  });

  @override
  State<DocAppointmentCard> createState() => _DocAppointmentCardState();
}

class _DocAppointmentCardState extends State<DocAppointmentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.985).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final width = displayWidth(context);
    final containerBg = isDark ? darkModeCardColor : Colors.white;

    final s = widget.statusLabel.toLowerCase();
    final bool isCompleted = s.contains('completed') || s.contains('complet');
    final bool isCancelled = s.contains('cancelled') || s.contains('cancel');
    final bool canReschedule = widget.onRescheduleTap != null && !isCompleted && !isCancelled;
    final bool canCancel = widget.onCancelTap != null && !isCompleted && !isCancelled;
    final bool hasMenuOptions = canReschedule || canCancel;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _animController.forward(),
        onTapUp: (_) {
          _animController.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _animController.reverse(),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: containerBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Avatar + Name & Subtitle + Chevron
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Clean soft avatar
                  Container(
                    width: widget.isTab ? 44 : 40,
                    height: widget.isTab ? 44 : 40,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.initials,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: widget.isTab ? width * 0.015 : 13.5,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + time/category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.name,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: widget.isTab
                                      ? width * 0.017
                                      : width * 0.035,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildConsultationModeBadge(isDark, width),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: isDark
                                  ? Colors.white38
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.timeOrDate,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: widget.isTab
                                    ? width * 0.013
                                    : width * 0.026,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            if (widget.subtitle.isNotEmpty) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white24
                                        : const Color(0xFFCBD5E1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  widget.subtitle,
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: widget.isTab
                                        ? width * 0.013
                                        : width * 0.026,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (hasMenuOptions)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Options',
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      elevation: 6,
                      onSelected: (val) {
                        if (val == 'reschedule') {
                          widget.onRescheduleTap?.call();
                        } else if (val == 'cancel') {
                          widget.onCancelTap?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        if (canReschedule)
                          PopupMenuItem<String>(
                            value: 'reschedule',
                            height: 42,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.edit_calendar_rounded,
                                    size: 15,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Reschedule',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (canCancel)
                          PopupMenuItem<String>(
                            value: 'cancel',
                            height: 42,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.cancel_outlined,
                                    size: 15,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Cancel Appointment',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      size: 18.0,
                    ),
                ],
              ),

              // Description row (if present)
              if (widget.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 13,
                        color: isDark
                            ? Colors.white30
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.description,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: widget.isTab
                                ? width * 0.013
                                : width * 0.026,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Bottom row: teleconsultation / patient status + appointment status
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left items: Video Call button + Prescription button + Patient Status pill
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Video call badge (Allowed whole day for active appointments; blocked for previous day)
                        if (widget.isTeleConsultation &&
                            (widget.canJoinCall ?? true) &&
                            !widget.statusLabel.toLowerCase().contains('completed') &&
                            !widget.statusLabel.toLowerCase().contains('cancelled') &&
                            !widget.statusLabel.toLowerCase().contains('past') &&
                            !Utils.isPreviousDay(widget.appointmentDate ?? widget.timeOrDate))
                          Builder(
                            builder: (context) {
                              final isPending = widget.statusLabel.toLowerCase().contains('pending') ||
                                  widget.statusLabel.toLowerCase().contains('payment');

                              return InkWell(
                                onTap: widget.onJoinCall,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.isTab ? 14.0 : 10.0,
                                    vertical: widget.isTab ? 7.0 : 5.5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isPending
                                          ? const [
                                              Color(0xFFD97706),
                                              Color(0xFFB45309),
                                            ]
                                          : const [
                                              Color(0xFF2563EB),
                                              Color(0xFF1D4ED8),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isPending ? const Color(0xFFD97706) : const Color(0xFF2563EB)).withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isPending ? Icons.payment_rounded : Icons.videocam_rounded,
                                        size: widget.isTab ? 16 : 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isPending ? "Pay to Join" : "Join Call",
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: widget.isTab ? 12 : 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                        // Prescription quick button if provided
                        if (widget.onPrescriptionTap != null)
                          InkWell(
                            onTap: widget.onPrescriptionTap,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: widget.isTab ? 9.0 : 7.0,
                                vertical: widget.isTab ? 6.0 : 4.5,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.35),
                                  width: 0.9,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.medication_rounded,
                                    size: widget.isTab ? 14 : 12,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 3.5),
                                  Text(
                                    "Prescription",
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: widget.isTab ? 11 : 10,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),


                        // Patient Status Pill (e.g. For: John Doe / New Patient / Follow-up)
                        if (widget.patientStatus != null &&
                            widget.patientStatus!.trim().isNotEmpty &&
                            widget.patientStatus!.trim().toLowerCase() != 'active' &&
                            widget.patientStatus!.trim().toLowerCase() != 'inactive')
                          Builder(
                            builder: (context) {
                              final isForFamily = widget.patientStatus!.startsWith('For:');
                              final badgeBg = isForFamily
                                  ? (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF))
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9));
                              final badgeText = isForFamily
                                  ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569));
                              final badgeBorder = isForFamily
                                  ? (isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFBFDBFE))
                                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0));

                              return Container(
                                constraints: BoxConstraints(maxWidth: width * 0.45),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: badgeBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isForFamily ? Icons.family_restroom_rounded : Icons.medical_services_outlined,
                                      size: 11,
                                      color: badgeText,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        widget.patientStatus!,
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: widget.isTab
                                              ? width * 0.011
                                              : 10.0,
                                          fontWeight: FontWeight.w600,
                                          color: badgeText,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Right item: Clean, Crisp, Unfaded Appointment Status pill badge
                  Builder(
                    builder: (context) {
                      Color bg;
                      Color txt;
                      Color border;
                      final s = widget.statusLabel.toLowerCase();

                      if (s.contains('cancel')) {
                        bg = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2);
                        txt = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
                        border = isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA);
                      } else if (s.contains('pend')) {
                        bg = isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7);
                        txt = isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706);
                        border = isDark ? const Color(0xFF92400E) : const Color(0xFFFDE68A);
                      } else if (s.contains('complet')) {
                        bg = isDark ? const Color(0xFF172554) : const Color(0xFFDBEAFE);
                        txt = isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);
                        border = isDark ? const Color(0xFF1E40AF) : const Color(0xFFBFDBFE);
                      } else {
                        // Scheduled / Confirmed / Active
                        bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);
                        txt = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF16A34A);
                        border = isDark ? const Color(0xFF065F46) : const Color(0xFFBBF7D0);
                      }

                      return GestureDetector(
                        onTap: widget.isUpdatingStatus ? null : widget.onStatusTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: border, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.isUpdatingStatus) ...[
                                SizedBox(
                                  width: 9,
                                  height: 9,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(txt),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "UPDATING...",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: widget.isTab
                                        ? width * 0.01
                                        : 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: txt,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  width: 5.5,
                                  height: 5.5,
                                  decoration: BoxDecoration(
                                    color: txt,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  widget.statusLabel.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: widget.isTab
                                        ? width * 0.01
                                        : 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: txt,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                if (widget.onStatusTap != null) ...[
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    size: 13,
                                    color: txt,
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsultationModeBadge(bool isDark, double width) {
    final bool isVideo = widget.isTeleConsultation;
    final bg = isVideo
        ? (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFEFF6FF))
        : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5));
    final textCol = isVideo
        ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB))
        : (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669));
    final borderCol = isVideo
        ? (isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.4) : const Color(0xFFBFDBFE))
        : (isDark ? const Color(0xFF10B981).withValues(alpha: 0.4) : const Color(0xFFA7F3D0));

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isTab ? 7.5 : 6.0,
        vertical: widget.isTab ? 3.5 : 2.5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderCol, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVideo ? Icons.videocam_rounded : Icons.storefront_rounded,
            size: widget.isTab ? 13 : 11,
            color: textCol,
          ),
          const SizedBox(width: 3.5),
          Text(
            isVideo ? "Video Call" : "In-Clinic",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: widget.isTab ? 11 : 9.5,
              fontWeight: FontWeight.w600,
              color: textCol,
            ),
          ),
        ],
      ),
    );
  }
}