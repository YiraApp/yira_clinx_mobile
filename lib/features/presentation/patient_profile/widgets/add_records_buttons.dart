import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
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

class _ClinicalSpeedDialFabState extends State<ClinicalSpeedDialFab>
    with SingleTickerProviderStateMixin {
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

    _iconRotation = Tween<double>(
      begin: 0,
      end: 0.125,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _menuScale = Tween<double>(
      begin: 0.92,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _menuOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
                  margin: EdgeInsets.only(bottom: isTab ? 18 : 14),
                  padding: EdgeInsets.all(isTab ? 18 : 14),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _animatedOption(
                        delay: 0,
                        child: _buildChildOption(
                          context,
                          label: "Prescribe",
                          icon: Icons.medication_outlined,
                          color: const Color(0xFFF97316),
                          onTap: widget.onPrescribeTapped,
                          isDark: isDark,
                          isTab: isTab,
                        ),
                      ),

                      SizedBox(height: isTab ? 14 : 12),

                      _animatedOption(
                        delay: 50,
                        child: _buildChildOption(
                          context,
                          label: "Schedule",
                          icon: Icons.calendar_month_outlined,
                          color: const Color(0xFF10B981),
                          onTap: widget.onScheduleTapped,
                          isDark: isDark,
                          isTab: isTab,
                        ),
                      ),

                      SizedBox(height: isTab ? 14 : 12),

                      _animatedOption(
                        delay: 100,
                        child: _buildChildOption(
                          context,
                          label: "Add Note",
                          icon: Icons.edit_note_rounded,
                          color: theme.primaryColor,
                          onTap: widget.onAddNoteTapped,
                          isDark: isDark,
                          isTab: isTab,
                        ),
                      ),
                    ],
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
              _isExpanded ? Icons.close_rounded : Icons.auto_awesome_rounded,
              color: Colors.white,
              size: isTab ? 28 : 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _animatedOption({required Widget child, required int delay}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 250 + delay),
      tween: Tween(begin: 0, end: _isExpanded ? 1 : 0),
      builder: (context, value, widget) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: Opacity(opacity: value, child: widget),
        );
      },
      child: child,
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
          Container(
            width: isTab ? 50 : 44,
            height: isTab ? 50 : 44,
            // decoration: BoxDecoration(
            //   shape: BoxShape.circle,
            //   color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.12),
            //   border: Border.all(color: color.withOpacity(0.25)),
            // ),
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
              // border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
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

          Icon(Icons.keyboard_arrow_right,size: 18,),
        ],
      ),
    );
  }
}
