import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../common_widgets/common_text.dart';

class CustomMenuTile extends StatelessWidget {
  final String title;
  final String icon;
  final VoidCallback onTap;
  final Color? customColor;
  final double? parentWidth;
  final IconData? fallbackIcon;

  const CustomMenuTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.customColor,
    this.parentWidth,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isTab = isTablet(context);
    final double referenceWidth =
        parentWidth ?? (isTab ? 360.0 : displayWidth(context));
    final Color inactiveTextColor =
        theme.textTheme.bodyLarge?.color ?? Colors.black;
    final Color resolvedColor = customColor ?? inactiveTextColor;

    final double iconSize = isTab
        ? displayWidth(context) * 0.032
        : displayWidth(context) * 0.045;
    final String sanitizedUrl = icon.trim();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: referenceWidth * 0.045,
        vertical: 4.0,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: referenceWidth * 0.045,
            vertical: referenceWidth * 0.038,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(fieldBorderRadius),
          ),
          child: Row(
            children: [
              SizedBox(
                height: isTab
                    ? displayWidth(context) * 0.032
                    : displayHeight(context) * 0.025,
                width: iconSize,
                child: sanitizedUrl.isEmpty
                    ? Icon(
                        fallbackIcon,
                        color:
                            customColor ?? (inactiveTextColor.withOpacity(0.7)),
                        size: referenceWidth * (isTab ? 0.048 : 0.045),
                      )
                    : CachedNetworkImage(
                        imageUrl: sanitizedUrl,
                        cacheKey: sanitizedUrl,
                        maxHeightDiskCache: 100,
                        maxWidthDiskCache: 100,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          fallbackIcon ?? Icons.broken_image,
                          size: iconSize * 0.8,
                          color: resolvedColor,
                        ),
                      ),
              ),
              SizedBox(width: referenceWidth * 0.045),
              Expanded(
                child: CommonText(
                  title,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    color: resolvedColor,
                    fontSize: referenceWidth * (isTab ? 0.042 : 0.033),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomIconMenuTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? customColor;
  final double? parentWidth;

  const CustomIconMenuTile({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.customColor,
    this.parentWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isTab = isTablet(context);

    final double referenceWidth =
        parentWidth ?? (isTab ? 360 : displayWidth(context));

    final Color activeBgColor = theme.primaryColor;
    final Color activeTextColor = Colors.white;
    final Color inactiveTextColor =
        theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: referenceWidth * 0.045,
        vertical: 4.0,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: referenceWidth * 0.045,
            vertical: referenceWidth * 0.038,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(fieldBorderRadius),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: customColor ?? (inactiveTextColor.withOpacity(0.7)),
                size: referenceWidth * (isTab ? 0.048 : 0.045),
              ),
              SizedBox(width: referenceWidth * 0.045),
              Expanded(
                child: CommonText(
                  title,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    color: customColor ?? (inactiveTextColor),
                    fontSize: referenceWidth * (isTab ? 0.042 : 0.033),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
