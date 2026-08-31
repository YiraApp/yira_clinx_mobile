import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../domain/entities/prescriptions/prescription_item.dart';

class SinglePrescriptionCard extends StatelessWidget {
  final List<MedicationItem> medications;
  final String date;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onView;
  final bool isTab;

  static const Color _primaryBlue = Color(0xFF2563EB);

  const SinglePrescriptionCard({
    super.key,
    required this.medications,
    required this.date,
    this.onEdit,
    this.onDelete,
    this.onView,
    required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int count = medications.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF64748B).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Icon + Title + Action Buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Title + Actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Rx Icon Badge
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.medication_rounded,
                        color: _primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Title
                    Expanded(
                      child: Text(
                        "Prescription Record",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 16 : 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Direct Action Buttons (Edit & Delete)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onEdit != null)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onEdit,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: _primaryBlue.withValues(alpha: isDark ? 0.15 : 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _primaryBlue.withValues(alpha: 0.25),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: _primaryBlue,
                                ),
                              ),
                            ),
                          ),
                        if (onEdit != null && onDelete != null) const SizedBox(width: 8),
                        if (onDelete != null)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onDelete,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: isDark ? 0.15 : 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.25),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Second Row: Count badge + Timestamp
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 11,
                            color: _primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$count ${count == 1 ? 'Medicine' : 'Medicines'}",
                            style: const TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        date,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
          ),

          // ── Medicine Items List ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: medications.take(3).map((med) {
                final timingParts = <String>[];
                if (med.dosage != null && med.dosage!.trim().isNotEmpty) {
                  timingParts.add(med.dosage!.trim());
                }
                if (med.frequency != null && med.frequency!.trim().isNotEmpty) {
                  timingParts.add(med.frequency!.trim());
                }
                if (med.duration != null && med.duration!.trim().isNotEmpty) {
                  timingParts.add(med.duration!.trim());
                }
                if (med.route != null && med.route!.trim().isNotEmpty) {
                  timingParts.add(med.route!.trim());
                }
                final timingStr = timingParts.join(' • ');

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab ? 13.5 : 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (timingStr.isNotEmpty)
                              Text(
                                timingStr,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 11,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          if (medications.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                "+ ${medications.length - 3} more medications",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),

          // ── Bottom View Action Bar ──
          if (onView != null)
            InkWell(
              onTap: onView,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "View Full Prescription Details",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _primaryBlue,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: _primaryBlue,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}