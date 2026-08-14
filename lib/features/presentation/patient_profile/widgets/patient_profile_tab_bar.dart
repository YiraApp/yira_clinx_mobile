import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class PatientProfileTabBar extends StatefulWidget {
  final List<String> tabs;
  final int selectedIndex;
  final Function(int) onTabSelected;
  final bool isTab;

  const PatientProfileTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected, required this.isTab,
  });

  @override
  State<PatientProfileTabBar> createState() => _PatientProfileTabBarState();
}

class _PatientProfileTabBarState extends State<PatientProfileTabBar> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.selectedIndex > 0) {
        _scrollToIndex(widget.selectedIndex);
      }
    });
  }

  @override
  void didUpdateWidget(covariant PatientProfileTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollToIndex(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  IconData _getTabIcon(String tabName) {
    switch (tabName.toLowerCase()) {
      case 'info':
        return Icons.info_outline_rounded;
      case 'medical record':
      case 'medical records':
        return Icons.medical_services_outlined;
      case 'prescribe':
      case 'prescriptions':
        return Icons.medication_outlined;
      case 'notes':
      case 'clinical notes':
        return Icons.sticky_note_2_outlined;
      case 'documents':
      case 'records':
        return Icons.folder_open_rounded;
      default:
        return Icons.tab_rounded;
    }
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;

    const double estimatedItemWidth = 130.0;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double targetOffset = (index * estimatedItemWidth) - (screenWidth / 2) + (estimatedItemWidth / 2);

    final double maxScrollExtent = _scrollController.position.maxScrollExtent;
    final double safeScrollOffset = targetOffset.clamp(0.0, maxScrollExtent);

    _scrollController.animateTo(
      safeScrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.isTab ? 50 : 40,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.tabs.length,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, idx) {
          final isActive = widget.selectedIndex == idx;
          final activeBgColor = Colors.white.withOpacity(0.2);
          final activeTextColor = Colors.white;
          final inactiveTextColor = Colors.white.withOpacity(0.7);

          return GestureDetector(
            onTap: () => widget.onTabSelected(idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? activeBgColor : Colors.transparent,
                borderRadius: BorderRadius.circular(fieldBorderRadius),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTabIcon(widget.tabs[idx]),
                      size: widget.isTab ? 18 : 15,
                      color: isActive ? activeTextColor : inactiveTextColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.tabs[idx],
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: widget.isTab
                            ? displayWidth(context) * 0.02
                            : displayWidth(context) * 0.032,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? activeTextColor : inactiveTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}