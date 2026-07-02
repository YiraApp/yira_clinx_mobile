import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class MedicalRecordFab extends StatefulWidget {
  final VoidCallback onAddRecordTapped;

  const MedicalRecordFab({
    super.key,
    required this.onAddRecordTapped,
  });

  @override
  State<MedicalRecordFab> createState() => _MedicalRecordFabState();
}

class _MedicalRecordFabState extends State<MedicalRecordFab> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _iconRotation;
  late Animation<double> _menuScale;
  late Animation<double> _menuOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _iconRotation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _menuScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _menuOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            if (!_isExpanded && _controller.value == 0) {
              return const SizedBox.shrink();
            }

            return FadeTransition(
              opacity: _menuOpacity,
              child: ScaleTransition(
                scale: _menuScale,
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: EdgeInsets.only(bottom: isTab ? 18 : 14, right: 2),
                  padding: EdgeInsets.all(isTab ? 14 : 10),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _buildChildOption(
                    context,
                    label: "Add Medical Record",
                    icon: Icons.note_add_outlined,
                    color: theme.primaryColor,
                    onTap: widget.onAddRecordTapped,
                    isDark: isDark,
                    isTab: isTab,
                  ),
                ),
              ),
            );
          },
        ),
        _buildFab(context, isTab),
      ],
    );
  }

  Widget _buildFab(BuildContext context, bool isTab) {
    final theme = Theme.of(context);
    final fabSize = isTab ? 68.0 : 60.0;

    return Container(
      width: fabSize,
      height: fabSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: _toggleMenu,
          child: RotationTransition(
            turns: _iconRotation,
            child: Icon(
              _isExpanded ? Icons.close_rounded : Icons.description_outlined,
              color: Colors.white,
              size: isTab ? 28 : 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChildOption(
      BuildContext context, {
        required String label,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
        required bool isDark,
        required bool isTab,
      }) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
        _toggleMenu();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: isTab ? 50 : 44,
            height: isTab ? 50 : 44,
            child: Icon(icon, color: color, size: isTab ? 22 : 20),
          ),
          SizedBox(width: isTab ? 14 : 0),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTab ? 16 : 12,
              vertical: isTab ? 10 : 8,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? 14 : 13,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
          SizedBox(width: isTab ? 14 : 12),
          const Icon(Icons.keyboard_arrow_right, size: 18),
        ],
      ),
    );
  }
}