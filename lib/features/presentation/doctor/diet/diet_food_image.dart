import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A food's photo, or a coloured icon for its category while it has none.
/// A small veg / egg / non-veg dot sits on the corner when [foodType] is known.
class DietFoodImage extends StatelessWidget {
  final String? imageUrl;
  final String category;
  final String foodType;
  final double size;

  const DietFoodImage({
    super.key,
    this.imageUrl,
    this.category = '',
    this.foodType = '',
    this.size = 44,
  });

  static ({IconData icon, Color color}) _categoryStyle(String category) {
    switch (category.toLowerCase()) {
      case 'breakfast':
        return (icon: Icons.brunch_dining_rounded, color: const Color(0xFFF59E0B));
      case 'grain':
      case 'cereal':
        return (icon: Icons.rice_bowl_rounded, color: const Color(0xFFD97706));
      case 'protein':
      case 'meat':
      case 'egg':
        return (icon: Icons.egg_rounded, color: const Color(0xFFEF4444));
      case 'vegetable':
        return (icon: Icons.eco_rounded, color: const Color(0xFF10B981));
      case 'fruit':
        return (icon: Icons.apple_rounded, color: const Color(0xFFE11D48));
      case 'dairy':
      case 'milk':
        return (icon: Icons.water_drop_rounded, color: const Color(0xFF0EA5E9));
      case 'beverage':
      case 'drink':
        return (icon: Icons.local_cafe_rounded, color: const Color(0xFF8B5CF6));
      case 'snack':
        return (icon: Icons.cookie_rounded, color: const Color(0xFFF97316));
      case 'oil':
      case 'fat':
      case 'spice':
      case 'condiment':
        return (icon: Icons.opacity_rounded, color: const Color(0xFF78716C));
      case 'sweet':
      case 'dessert':
        return (icon: Icons.cake_rounded, color: const Color(0xFFEC4899));
      default:
        return (icon: Icons.restaurant_rounded, color: const Color(0xFF64748B));
    }
  }

  static Color _foodTypeColor(String foodType) {
    final type = foodType.toLowerCase();
    if (type.contains('non')) return const Color(0xFFDC2626);
    if (type.contains('egg')) return const Color(0xFFD97706);
    return const Color(0xFF059669);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = _categoryStyle(category);
    final radius = BorderRadius.circular(size * 0.28);

    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: radius,
      ),
      child: Icon(style.icon, size: size * 0.5, color: style.color),
    );

    final url = imageUrl?.trim() ?? '';
    final picture = url.isEmpty
        ? placeholder
        : ClipRRect(
            borderRadius: radius,
            child: CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder,
            ),
          );

    if (foodType.isEmpty) return picture;

    final dot = size * 0.26;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          picture,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: _foodTypeColor(foodType),
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
