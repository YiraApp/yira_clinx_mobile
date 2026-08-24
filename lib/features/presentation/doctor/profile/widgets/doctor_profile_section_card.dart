import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class DoctorProfileFieldItem {
  final String label;
  final String value;
  final IconData icon;
  final bool isCopyable;
  final bool isVerified;
  final Color? customValueColor;

  const DoctorProfileFieldItem({
    required this.label,
    required this.value,
    required this.icon,
    this.isCopyable = false,
    this.isVerified = false,
    this.customValueColor,
  });
}

class DoctorProfileSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<DoctorProfileFieldItem> fields;
  final VoidCallback? onEdit;
  final bool isTab;

  const DoctorProfileSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.fields,
    this.onEdit,
    required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: isTab ? 18 : 16,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 15.5 : 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (onEdit != null)
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Edit",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),

          // Field Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: fields.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              thickness: 0.8,
              indent: 48,
              endIndent: 16,
              color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
            ),
            itemBuilder: (context, index) {
              final field = fields[index];
              return _buildFieldRow(context, field, isDark, primaryColor);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(
    BuildContext context,
    DoctorProfileFieldItem field,
    bool isDark,
    Color primaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            field.icon,
            size: isTab ? 18 : 16,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  field.label,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 11.5 : 10.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  field.value,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 13.5 : 12.5,
                    fontWeight: FontWeight.w600,
                    color: field.customValueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
          ),

          // Verified Badge Pill
          if (field.isVerified) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF10B981)),
                  SizedBox(width: 3),
                  Text(
                    "Verified",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],

          // Copy Button
          if (field.isCopyable && field.value.isNotEmpty && field.value != "Not Provided")
            IconButton(
              icon: Icon(
                Icons.copy_rounded,
                size: 15,
                color: isDark ? Colors.white54 : Colors.grey.shade500,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: field.value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${field.label} copied to clipboard"),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
