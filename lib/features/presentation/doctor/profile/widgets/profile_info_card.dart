import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class ProfileInfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<ProfileInfoRowData> items;
  final bool isTab;
  final VoidCallback? onEdit;

  const ProfileInfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.items,
    required this.isTab,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: isTab ? 20 : 18,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 16 : 14.5,
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
                              fontSize: 12.5,
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
          Divider(
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
          ),
          // Content Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            itemCount: items.length,
            separatorBuilder: (_, _) => Divider(
              height: 16,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF8FAFC),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildInfoRow(context, item, isDark, isTab);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    ProfileInfoRowData item,
    bool isDark,
    bool isTab,
  ) {
    return InkWell(
      onTap: item.isCopyable == true
          ? () {
              Clipboard.setData(ClipboardData(text: item.value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${item.label} copied to clipboard"),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (item.rowIcon != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.rowIcon,
                  size: isTab ? 16 : 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
            ],
            SizedBox(
              width: isTab ? 170 : 125,
              child: Text(
                item.label,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 13 : 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      item.value,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 14 : 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (item.isVerified == true) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 11,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            "Verified",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (item.isCopyable == true) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.copy_rounded,
                      size: 12,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileInfoRowData {
  final String label;
  final String value;
  final IconData? rowIcon;
  final bool? isVerified;
  final bool? isCopyable;

  const ProfileInfoRowData({
    required this.label,
    required this.value,
    IconData? icon,
    IconData? rowIcon,
    this.isVerified,
    this.isCopyable,
  }) : rowIcon = icon ?? rowIcon;
}

typedef ProfileInfoItem = ProfileInfoRowData;
