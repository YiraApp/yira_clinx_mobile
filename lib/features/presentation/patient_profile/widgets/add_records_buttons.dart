import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class ClinicalSpeedDialFab extends StatefulWidget {
  final VoidCallback onAddNoteTapped;
  final VoidCallback onScheduleTapped;
  final VoidCallback onPrescribeTapped;

  const ClinicalSpeedDialFab({
    super.key,
    required this.onAddNoteTapped,
    required this.onScheduleTapped,
    required this.onPrescribeTapped,
  });

  @override
  State<ClinicalSpeedDialFab> createState() => _ClinicalSpeedDialFabState();
}

class _ClinicalSpeedDialFabState extends State<ClinicalSpeedDialFab> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animateIcon;
  late Animation<double> _translateButton;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() => setState(() {}));

    _animateIcon = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _translateButton = Tween<double>(begin: 56.0, end: -14.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.initState();
  }

  void _toggleMenu() {
    if (_isExpanded) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    _isExpanded = !_isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildChildOption(
          label: 'Prescribe',
          icon: Icons.assignment_outlined,
          color: const Color(0xFFEA4335), // Clinical Red
          onTap: widget.onPrescribeTapped,
          offsetMultiplier: 3,
          isDark: isDark,
        ),
        _buildChildOption(
          label: 'Schedule',
          icon: Icons.calendar_today_outlined,
          color: const Color(0xFF34A853), // Clinical Green
          onTap: widget.onScheduleTapped,
          offsetMultiplier: 2,
          isDark: isDark,
        ),
        _buildChildOption(
          label: 'Add Note',
          icon: Icons.add_circle_outline,
          color: primaryColor, // Base Theme Primary
          onTap: widget.onAddNoteTapped,
          offsetMultiplier: 1,
          isDark: isDark,
        ),

        FloatingActionButton(
          backgroundColor: primaryColor,
          elevation: _isExpanded ? 4 : 2,
          onPressed: _toggleMenu,
          shape: const CircleBorder(),
          foregroundColor: Colors.white,
          child: RotationTransition(
            turns: _animateIcon,
            child: Icon(
              _isExpanded ? Icons.close_rounded : Icons.insights_rounded,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChildOption({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int offsetMultiplier,
    required bool isDark,
  }) {
    final cardBgColor = isDark ? Colors.grey[900]! : Colors.white;
    final cardTextColor = isDark ? Colors.grey[200]! : Colors.black87;
    final cardBorderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Transform(
      transform: Matrix4.translationValues(
        0.0,
        _translateButton.value * offsetMultiplier,
        0.0,
      ),
      child: Opacity(
        opacity: _animationController.value,
        child: Visibility(
          visible: _animationController.value > 0.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, right: 4),
            child: InkWell(
              onTap: (){
                _toggleMenu();
                onTap();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBorderColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cardTextColor,
                      ),
                    ),
                  ),

                  // Small Option Action Round Container
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? color.withOpacity(0.18) : color,
                      shape: BoxShape.circle,
                      border: isDark ? Border.all(color: color.withOpacity(0.4), width: 1.2) : null,
                      boxShadow: !isDark
                          ? [
                        BoxShadow(
                          color: color.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ]
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: isDark ? color : Colors.white,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}