import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../../../core/colors/colors.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../domain/entities/uploaded_record/uploaded_record_entity.dart';
import '../model/app_pop_up_model.dart';
import 'common_custom_pop_up_menu.dart';

class UploadedRecordCard extends StatelessWidget {
  final UploadedRecord record;
  final VoidCallback onDelete;
  final VoidCallback onDownload;
  final VoidCallback onView;
final bool isTab;
  const UploadedRecordCard({
    super.key,
    required this.record,
    required this.onDelete,
    required this.onDownload,
    required this.onView, required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color currentPrimary = theme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        boxShadow: const [],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.12) : theme.dividerColor.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        child: IntrinsicHeight(
          child: Row(
            children: [
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: currentPrimary.withOpacity(isDark ? 0.15 : 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: isDark ? currentPrimary.withOpacity(0.9) : currentPrimary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommonText(
                            record.fileName,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize:isTab?  displayWidth(context) * 0.018: displayWidth(context) * 0.035,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.titleMedium?.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: currentPrimary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: CommonText(
                              record.category,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                color: isDark ? currentPrimary.withOpacity(0.9) : currentPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: isTab?  displayWidth(context) * 0.014:displayWidth(context) * 0.022,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: theme.hintColor.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          CommonText(
                            DateFormat('MMM dd, yyyy').format(record.uploadDate),
                            style: TextStyle(
                              color: theme.hintColor.withOpacity(0.7),
                              fontSize:isTab?  displayWidth(context) * 0.018: displayWidth(context) * 0.031,
                              fontFamily: appPoppinFont,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file_outlined,
                            size: 12,
                            color: theme.hintColor.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          CommonText(
                            '${record.fileSizeKB} KB',
                            style: TextStyle(
                              color: theme.hintColor.withOpacity(0.7),
                              fontSize:isTab?  displayWidth(context) * 0.018: displayWidth(context) * 0.031,
                              fontFamily: appPoppinFont,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                child: VerticalDivider(
                  color: isDark ? Colors.white10 : const Color(0xFFE9EBF0),
                  width: 1,
                  thickness: 1,
                ),
              ),
              CommonCustomPopupMenu(
                items: [
                  AppPopupItemModel(
                    icon: Icons.visibility_outlined,
                    title: 'View Document',
                    onTap: onView,
                  ),
                  AppPopupItemModel(
                    icon: Icons.download_rounded,
                    title: 'Download',
                    onTap: onDownload,
                  ),
                  AppPopupItemModel(
                    icon: Icons.delete_outline_rounded,
                    title: 'Delete',
                    onTap: onDelete,
                    isDestructive: true,
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
                  child: Icon(
                    Icons.more_vert_rounded,
                    color: theme.appBarTheme.iconTheme?.color ?? (isDark ? Colors.white70 : Colors.black54),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}