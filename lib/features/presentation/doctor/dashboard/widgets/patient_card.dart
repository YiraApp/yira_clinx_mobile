import 'package:flutter/material.dart';
import '../../../../../core/constants/constants.dart';
import '../../../../../core/services/favorite_patients_service.dart';
import '../../../../domain/entities/dashboard/patient_entity.dart';

class PatientCard extends StatelessWidget {
  final PatientEntity patient;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;
  final bool isTab;

  const PatientCard({
    super.key,
    required this.patient,
    required this.onTap,
    this.onToggleFavorite,
    required this.isTab,
  });

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'PT';
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].length >= 2 ? parts[0].substring(0, 2).toUpperCase() : parts[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final initials = _getInitials(patient.name);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main Card Content & Navigation Tap
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.all(isTab ? 16 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Avatar + Name & Demographics
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Avatar: Image if available, else Letters/Initials
                        Container(
                          width: isTab ? 48 : 42,
                          height: isTab ? 48 : 42,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white10 : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: (patient.profileImageUrl != null &&
                                    patient.profileImageUrl!.trim().isNotEmpty &&
                                    !patient.profileImageUrl!.contains('placeholder') &&
                                    !patient.profileImageUrl!.contains('default_avatar'))
                                ? Image.network(
                                    patient.profileImageUrl!.trim(),
                                    fit: BoxFit.cover,
                                    width: isTab ? 48 : 42,
                                    height: isTab ? 48 : 42,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Text(
                                        initials,
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontWeight: FontWeight.w700,
                                          fontSize: isTab ? 16 : 14,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      initials,
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontWeight: FontWeight.w700,
                                        fontSize: isTab ? 16 : 14,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Name & Sub-details
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: onToggleFavorite != null ? 36.0 : 0.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.name.isNotEmpty ? patient.name : "Unnamed Patient",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isTab ? 16 : 14.5,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        "${patient.id.isNotEmpty ? patient.id : 'PT-ID'} • ${patient.age > 0 ? '${patient.age}y' : 'N/A'} • ${patient.gender.isNotEmpty ? patient.gender : 'Gender N/A'}",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: isTab ? 12.5 : 11.5,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

            // Row 2: Meta items (Visits + Last Visit + Allergy) + Right Chevron Action
            Row(
              children: [
                // Visits
                _buildMetaChip(
                  icon: Icons.history_rounded,
                  label: "${patient.visits} ${patient.visits == 1 ? 'visit' : 'visits'}",
                  isDark: isDark,
                  isTab: isTab,
                ),
                const SizedBox(width: 6),

                // Last visit
                if (patient.lastVisit.isNotEmpty) ...[
                  _buildMetaChip(
                    icon: Icons.calendar_today_outlined,
                    label: patient.lastVisit,
                    isDark: isDark,
                    isTab: isTab,
                  ),
                  const SizedBox(width: 6),
                ],

                // Allergy alert (if present)
                if (patient.allergy.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 11, color: Color(0xFFEF4444)),
                        const SizedBox(width: 3),
                        Text(
                          patient.allergy,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? 11 : 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // Action Chevron Indicator
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),

    // Isolated Favorite Button on top
    if (onToggleFavorite != null)
      Positioned(
        top: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: ValueListenableBuilder<Set<String>>(
            valueListenable: FavoritePatientsService().favoriteIdsNotifier,
            builder: (context, favSet, _) {
              final bool isFav = favSet.contains(patient.userId) ||
                  favSet.contains(patient.id) ||
                  patient.isFavorite == true;

              return InkWell(
                onTap: onToggleFavorite,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isFav
                        ? const Color(0xFFFEF3C7) // Amber 100
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFav
                          ? const Color(0xFFFDE68A)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: isTab ? 20 : 18,
                    color: isFav
                        ? const Color(0xFFD97706) // Amber 600
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
  ],
),
);
}

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required bool isDark,
    required bool isTab,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isTab ? 11.5 : 10.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab ? 11.5 : 10.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
