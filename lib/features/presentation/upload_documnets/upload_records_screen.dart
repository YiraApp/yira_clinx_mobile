import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/uploaded_bloc/uploaded_bloc.dart';

import '../../../../core/common_widgets/common_text.dart';
import '../../../core/common_drop_down/common_drop_down.dart';
import '../../../core/common_widgets/custom_border_button.dart';
import '../../../core/common_widgets/custom_button.dart';

class UploadDocumentsScreen extends StatefulWidget {
  final String? patientName;

  const UploadDocumentsScreen({super.key, required this.patientName});

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final List<String> categoriesList = [
    'Imaging / Radiology',
    'Appointments',
    'General',
    'Self(Patient)',
  ];
  late String selectedCategory;
  List<Map<String, dynamic>> stagedFiles = [];
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    selectedCategory = categoriesList.first;
  }

  void _simulateFileSelection() {
    final mockFileNames = [
      'Xray_Chest_AP.jpg',
      'MRI_Brain_T2.png',
      'Ultrasound_Abdomen.jpg',
      'CT_Scan_Spine.pdf',
    ];
    final selectedName = mockFileNames[Random().nextInt(mockFileNames.length)];
    final mockSizes = [1024, 2048, 4500, 8120];
    final selectedSize = mockSizes[Random().nextInt(mockSizes.length)];

    setState(() {
      stagedFiles.add({'name': selectedName, 'size': selectedSize});
    });
  }

  void _handleUploadConfirmation(BuildContext context) async {
    if (stagedFiles.isEmpty) return;

    setState(() {
      isUploading = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      final bloc = context.read<UploadedBloc>();

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                screenHorizontalSpacePadding,
                0,
                screenHorizontalSpacePadding,
                28,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonText(
                    "Upload Clinical Documents",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab
                          ? displayWidth(context) * 0.032
                          : displayWidth(context) * 0.054,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CommonText(
                    "For patient: ${widget.patientName}",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab
                          ? displayWidth(context) * 0.022
                          : displayWidth(context) * 0.034,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: screenHorizontalSpacePadding,
                  vertical: 26.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonText(
                      "Document Category",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab
                            ? displayWidth(context) * 0.02
                            : displayWidth(context) * 0.035,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CommonDropdown(
                      title: "Select Doctor",
                      selectedValue: selectedCategory,
                      options: const [
                        'Imaging / Radiology',
                        'Appointments',
                        'General',
                        'Self(Patient)',
                      ],
                      onSelected: (value) {},
                    ),
                    const SizedBox(height: fieldSpace),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CommonText(
                          "Selected Files",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab
                                ? displayWidth(context) * 0.02
                                : displayWidth(context) * 0.035,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: CommonText(
                            "${stagedFiles.length} Files",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab
                                  ? displayWidth(context) * 0.018
                                  : displayWidth(context) * 0.026,
                              color: primaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    stagedFiles.isEmpty
                        ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.transparent
                            : Colors.white,
                        borderRadius: BorderRadius.circular(
                          fieldBorderRadius,
                        ),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                fieldBorderRadius,
                              ),
                            ),
                            child: const Icon(
                              Icons.note_add_rounded,
                              color: Color(0xFF0066FF),
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CommonText(
                            "Drag and drop files here",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab
                                  ? displayWidth(context) * 0.02
                                  : displayWidth(context) * 0.035,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          CommonText(
                            "Support for PDF, JPG, PNG up to 10MB",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab
                                  ? displayWidth(context) * 0.018
                                  : displayWidth(context) * 0.03,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: _simulateFileSelection,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.transparent
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(
                                  fieldBorderRadius,
                                ),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey.withOpacity(0.2)
                                      : primaryColor,
                                  width: 0.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CommonText(
                                "Browse Files",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isTab
                                      ? displayWidth(context) * 0.018
                                      : displayWidth(context) * 0.032,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        : SizedBox.shrink(),
                    const SizedBox(height: fieldSpace),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stagedFiles.length,
                      itemBuilder: (context, index) {
                        final file = stagedFiles[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.surface
                                : const Color(0xFFFAFBFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : const Color(0xFFEDEFF3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(
                                    isDark ? 0.15 : 0.06,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.description_outlined,
                                  color: isDark
                                      ? primaryColor.withOpacity(0.9)
                                      : primaryColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CommonText(
                                      file['name'],
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontWeight: FontWeight.w600,
                                        fontSize: isTab
                                            ? displayWidth(context) * 0.018
                                            : displayWidth(context) * 0.03,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    CommonText(
                                      '${(file['size'] / 1024).toStringAsFixed(1)} MB',
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        color: theme.hintColor,
                                        fontSize: isTab
                                            ? displayWidth(context) * 0.018
                                            : displayWidth(context) * 0.028,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.cancel_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    stagedFiles.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (stagedFiles.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Center(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              side: const BorderSide(
                                color: primaryColor,
                                width: 0.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  fieldBorderRadius,
                                ),
                              ),
                            ),
                            onPressed: _simulateFileSelection,
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              color: primaryColor,
                              size: 18,
                            ),
                            label: CommonText(
                              "Add More Files",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: isTab
                                    ? displayWidth(context) * 0.02
                                    : displayWidth(context) * 0.035,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 4. Off-White Bottom Footer Section Action Bar
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: BoxDecoration(
                // color: isDark ? theme.colorScheme.surface : const Color(0xFFF4F5F7),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(fieldBorderRadius),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : const Color(0xFFE5E9F0),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CommonBorderButton(
                      height: 40,
                      text: 'Cancel',
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2.5,
                            ),
                          )
                        : CustomElevatedButton(
                            text: "Confirm Upload",
                            onPressed: () {
                              stagedFiles.isEmpty || isUploading
                                  ? null
                                  : () => _handleUploadConfirmation(context);
                            },
                            width: double.infinity,
                            height: 40,
                            borderRadius: 8,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
