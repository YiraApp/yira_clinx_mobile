import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/constants/constants.dart';
import '../../../../../core/shimmer_widgets/base_shimmer.dart';
import '../models/offer_banner_model.dart';
import '../services/offer_banner_service.dart';
import '../services/offer_redirection_helper.dart';

class OfferBannerCarousel extends StatefulWidget {
  final String? organizationId;

  const OfferBannerCarousel({super.key, this.organizationId});

  @override
  OfferBannerCarouselState createState() => OfferBannerCarouselState();
}

class OfferBannerCarouselState extends State<OfferBannerCarousel> {
  final OfferBannerService _service = OfferBannerService();
  PageController? _pageController;
  Timer? _autoScrollTimer;

  Future<void> refresh() => _loadBanners();

  List<OfferBannerModel> _banners = [];
  int _currentPage = 0;
  bool _userInteracting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPageController();
    _loadBanners();
  }

  void _initPageController() {
    final double fraction = (_banners.length <= 1) ? 1.0 : 0.93;
    if (_pageController == null) {
      _pageController = PageController(
        initialPage: _currentPage,
        viewportFraction: fraction,
      );
    } else if (_pageController!.viewportFraction != fraction) {
      final oldPage = _currentPage;
      _pageController?.dispose();
      _pageController = PageController(
        initialPage: oldPage.clamp(0, _banners.isEmpty ? 0 : _banners.length - 1),
        viewportFraction: fraction,
      );
    }
  }

  @override
  void didUpdateWidget(covariant OfferBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId) {
      _loadBanners();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    try {
      final list = await _service.fetchActiveOffers(
        organizationId: widget.organizationId,
        placement: 'carousel',
      );
      if (mounted) {
        setState(() {
          _banners = list;
          _isLoading = false;
          _currentPage = 0;
        });
        _initPageController();
        _startAutoScroll();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_banners.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_userInteracting || !mounted || _pageController == null || !_pageController!.hasClients) {
        return;
      }

      final nextPage = (_currentPage + 1) % _banners.length;
      _pageController!.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> _handleBannerTap(OfferBannerModel banner) async {
    await OfferRedirectionHelper.handleRedirection(context, banner);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmerPlaceholder(context);
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final fraction = (_banners.length <= 1) ? 1.0 : 0.93;
        final cardWidth = (totalWidth * fraction) - 8.0;
        const aspectRatio = 16.0 / 9.0;
        final bannerHeight = cardWidth / aspectRatio;
        final containerHeight = bannerHeight + 14.0; // Extra clearance for ambient elevation shadows

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: containerHeight,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification) {
                    _userInteracting = true;
                  } else if (notification is ScrollEndNotification) {
                    _userInteracting = false;
                  }
                  return false;
                },
                child: PageView.builder(
                  clipBehavior: Clip.none,
                  controller: _pageController,
                  itemCount: _banners.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final banner = _banners[index];
                    return _buildAnimatedSlide(index, banner, isDark, primaryColor);
                  },
                ),
              ),
            ),
            if (_banners.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_banners.length, (index) {
                  final isSelected = index == _currentPage;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _pageController?.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        width: isSelected ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    primaryColor,
                                    primaryColor.withValues(alpha: 0.8),
                                  ],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.22)
                                  : Colors.black.withValues(alpha: 0.15)),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.45),
                                    blurRadius: 5,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 14),
          ],
        );
      },
    );
  }

  Widget _buildShimmerPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const aspectRatio = 16.0 / 9.0;
        final bannerHeight = totalWidth / aspectRatio;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: bannerHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: BaseShimmer(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSlide(
    int index,
    OfferBannerModel banner,
    bool isDark,
    Color primaryColor,
  ) {
    if (_banners.length <= 1 || _pageController == null) {
      return _BannerCard(
        banner: banner,
        isDark: isDark,
        primaryColor: primaryColor,
        onTap: () => _handleBannerTap(banner),
        onPointerDown: () => _userInteracting = true,
        onPointerUp: () => _userInteracting = false,
      );
    }

    return AnimatedBuilder(
      animation: _pageController!,
      builder: (context, child) {
        double pageOffset = 0.0;
        if (_pageController!.hasClients && _pageController!.position.haveDimensions) {
          pageOffset = (_pageController!.page ?? _currentPage.toDouble()) - index;
        } else {
          pageOffset = (_currentPage - index).toDouble();
        }

        final double absOffset = pageOffset.abs().clamp(0.0, 1.0);
        final double scale = 1.0 - (absOffset * 0.06);
        final double opacity = 1.0 - (absOffset * 0.16);

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: _BannerCard(
        banner: banner,
        isDark: isDark,
        primaryColor: primaryColor,
        onTap: () => _handleBannerTap(banner),
        onPointerDown: () => _userInteracting = true,
        onPointerUp: () => _userInteracting = false,
      ),
    );
  }
}

class _BannerCard extends StatefulWidget {
  final OfferBannerModel banner;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onPointerDown;
  final VoidCallback onPointerUp;

  const _BannerCard({
    required this.banner,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
    required this.onPointerDown,
    required this.onPointerUp,
  });

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final banner = widget.banner;
    final isDark = widget.isDark;
    final primaryColor = widget.primaryColor;

    final hasText = (banner.showTitle && banner.title.trim().isNotEmpty) ||
        (banner.showDescription && banner.description.trim().isNotEmpty);

    return Listener(
      onPointerDown: (_) => widget.onPointerDown(),
      onPointerUp: (_) => widget.onPointerUp(),
      onPointerCancel: (_) => widget.onPointerUp(),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155).withValues(alpha: 0.7)
                    : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : primaryColor.withValues(alpha: 0.10),
                  blurRadius: 16,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : const Color(0xFF64748B).withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.8),
              child: AspectRatio(
                aspectRatio: 16.0 / 9.0,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Full-Bleed 16:9 Artwork with high quality cover fit
                    CachedNetworkImage(
                      imageUrl: banner.imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      placeholder: (context, url) => Container(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.75),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_offer_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                              if (banner.title.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    banner.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Multi-stop Gradient Overlay for Readability
                    if (hasText)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.35),
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.3, 0.65, 1.0],
                            ),
                          ),
                        ),
                      ),

                    // Elevated Frosted Offer Tag Badge
                    if (banner.showOfferTag && banner.offerTag.trim().isNotEmpty)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                primaryColor.withValues(alpha: 0.88),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 0.9,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 3.5),
                              Text(
                                banner.offerTag.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Bottom Content Bar (Title and Description)
                    if (hasText)
                      Positioned(
                        bottom: 10,
                        left: 12,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (banner.showTitle && banner.title.trim().isNotEmpty)
                              Text(
                                banner.title,
                                style: const TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 5,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (banner.showDescription && banner.description.trim().isNotEmpty) ...[
                              if (banner.showTitle && banner.title.trim().isNotEmpty)
                                const SizedBox(height: 2),
                              Text(
                                banner.description,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  height: 1.15,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
