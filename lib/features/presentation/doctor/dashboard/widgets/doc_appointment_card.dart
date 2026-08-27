import 'package:flutter/material.dart';

import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../../../../core/colors/colors.dart';

class DocAppointmentCard extends StatefulWidget {
  final String? profileImageUrl;
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

  const DocAppointmentCard({
    super.key,
    this.profileImageUrl,
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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              width: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.025),
                  blurRadius: 6,
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
                  // Clean soft avatar: Image if available, else Letters/Initials
                  Container(
                    width: widget.isTab ? 44 : 40,
                    height: widget.isTab ? 44 : 40,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: (widget.profileImageUrl != null &&
                              widget.profileImageUrl!.trim().isNotEmpty &&
                              !widget.profileImageUrl!.contains('placeholder') &&
                              !widget.profileImageUrl!.contains('default_avatar'))
                          ? Image.network(
                              widget.profileImageUrl!.trim(),
                              fit: BoxFit.cover,
                              width: widget.isTab ? 44 : 40,
                              height: widget.isTab ? 44 : 40,
                              errorBuilder: (context, error, stackTrace) => Center(
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
                            )
                          : Center(
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
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + time/category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
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
                        ? Colors.white.withOpacity(0.03)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
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
                children: [
                  // Left items: Video Call button + Patient Status pill
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Video call badge (Only for upcoming/active appointments, not past/completed/cancelled)
                      if (widget.isTeleConsultation &&
                          !widget.statusLabel.toLowerCase().contains('completed') &&
                          !widget.statusLabel.toLowerCase().contains('cancelled') &&
                          !widget.statusLabel.toLowerCase().contains('past')) ...[
                        InkWell(
                          onTap: widget.onJoinCall,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.isTab ? 16.0 : 13.0,
                              vertical: widget.isTab ? 8.0 : 6.5,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2563EB),
                                  Color(0xFF1D4ED8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.videocam_rounded,
                                  size: widget.isTab ? 18 : 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "Join Call",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: widget.isTab
                                        ? width * 0.014
                                        : 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Patient Status Pill (e.g. New Patient / Follow-up)
                      if (widget.patientStatus != null &&
                          widget.patientStatus!.trim().isNotEmpty &&
                          widget.patientStatus!.trim().toLowerCase() != 'active' &&
                          widget.patientStatus!.trim().toLowerCase() != 'inactive')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7.5, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 11,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.patientStatus!,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: widget.isTab
                                      ? width * 0.01
                                      : 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Right item: Clean Appointment Status pill badge
                  GestureDetector(
                    onTap: widget.onStatusTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: widget.statusColor.withOpacity(isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: widget.statusTextColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.statusLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: widget.isTab
                                  ? width * 0.01
                                  : 9.5,
                              fontWeight: FontWeight.w700,
                              color: widget.statusTextColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (widget.onStatusTap != null) ...[
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 13,
                              color: widget.statusTextColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}