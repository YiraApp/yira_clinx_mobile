import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';

import '../../../../core/common_widgets/custom_border_button.dart';
import '../../../../core/common_widgets/custom_button.dart';
import '../../../../core/constants/constants.dart';

class ClinicalNotesScreen extends StatefulWidget {
  const ClinicalNotesScreen({super.key});

  @override
  State<ClinicalNotesScreen> createState() => _ClinicalNotesScreenState();
}

class _ClinicalNotesScreenState extends State<ClinicalNotesScreen> {
  late final TextEditingController _notesController;

  final bool _isEmptyScenario = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Breakpoint: Treats widths over 650dp as tablet/desktop widescreen layouts
    final bool isWideScreen = screenWidth > 650;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Input Canvas Container Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWideScreen ? 24.0 : screenHorizontalSpacePadding,
                  vertical: 16.0,
                ),
                child: _buildInputCanvasCard(context, isWideScreen),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: fieldSpace)),

            // Core Conditional Display
            if (_isEmptyScenario)
            // Fixed viewport rendering crash by wrapping empty state view inside a box adapter
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideScreen ? 24.0 : screenHorizontalSpacePadding,
                  ),
                  child: _buildEmptyStateView(context, isWideScreen),
                ),
              )
            else
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: EdgeInsets.only(
                      right: isWideScreen ? 24.0 : screenHorizontalSpacePadding,
                      left: isWideScreen ? 24.0 : screenHorizontalSpacePadding,
                      bottom: 100,
                    ),
                    child: _buildHistoricalNoteCard(context, isWideScreen),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCanvasCard(BuildContext context, bool isWideScreen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _notesController,
            maxLines: isWideScreen ? 4 : 5,
            style: TextStyle(
              fontFamily: appPoppinFont,
              // Optimized text sizing limits using an alternative clean fallback bounds strategy
              fontSize: isWideScreen ? 14 : displayWidth(context) * 0.035,
            ),
            decoration: InputDecoration(
              hintText: 'Enter clinical notes...',
              hintStyle: TextStyle(
                fontSize: isWideScreen ? 14 : displayWidth(context) * 0.035,
                color: Colors.grey.shade400,
                fontFamily: appPoppinFont,
              ),
              filled: true,
              fillColor: isDark ? darkModeCardColor.withOpacity(0.8) : Colors.white,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(fieldBorderRadius),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(fieldBorderRadius),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isWideScreen)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDoctorIdentityLabel(isWideScreen),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 140,
                      child: _buildCancelButton(context),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      child: _buildSaveButton(),
                    ),
                  ],
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDoctorIdentityLabel(isWideScreen),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildCancelButton(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSaveButton(),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDoctorIdentityLabel(bool isWideScreen) {
    return Text(
      'Adding by Dr. Rajesh Nagalingam',
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: isWideScreen ? 13 : displayWidth(context) * 0.03,
        color: Colors.grey.shade500,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return  CommonBorderButton(
      isPatientDetail: true,
      height: 40,
      text: 'Clear',
      onPressed: (){},
    );
  }

  Widget _buildSaveButton() {
    return CustomElevatedButton(
      text: "Save Note",
      onPressed: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      width: double.infinity,
      height: 40,
      borderRadius: 8,
    );
  }

  Widget _buildHistoricalNoteCard(BuildContext context, bool isWideScreen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  size: 14,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '26 MAY 2026, 06:40 AM',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const Spacer(),
              Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 14),
              Icon(Icons.close, size: 16, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Patient Notes\n'
                'Patient Name: John Doe  Date: 26 May 2026\n'
                'Age/Gender: 45 / Male\n\n'
                'Chief Complaint: Patient presented with complaints of headache, mild fever, and fatigue for the past 3 days. History of Present Illness: Patient reports intermittent headaches associated with low-grade fever and generalized body weakness. No history of nausea, vomiting, chest pain, or shortness of breath. Vital Signs: Blood Pressure: 120/80 mmHg Pulse: 78 bpm Temperature: 99.5°F Oxygen Saturation: 98%. Examination: Patient is conscious, alert, and oriented. Mild throat redness noted. Chest clear on auscultation. No abnormal findings observed. Assessment: Likely viral upper respiratory tract infection. Plan: Prescribed Paracetamol for fever and headache. Encourage adequate hydration and rest. Monitor symptoms for worsening. Follow-up in 5–7 days or earlier if symptoms persist.',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isWideScreen ? 14 : displayWidth(context) * 0.035,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 16),
          Text(
            'By Dr. Rajesh Nagalingam',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateView(BuildContext context, bool isWideScreen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: isWideScreen ? 56 : 44,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No Historical Clinical Notes Found',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isWideScreen ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}