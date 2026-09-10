import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/offer_banner_model.dart';
import '../services/offer_banner_service.dart';
import '../services/offer_redirection_helper.dart';

class OfferPopupAdDialog extends StatelessWidget {
  final OfferBannerModel ad;

  const OfferPopupAdDialog({super.key, required this.ad});

  // Track shown ad IDs per session to prevent repeated annoying popups on every tab switch
  static final Set<int> _shownBannerIdsThisSession = {};

  /// Static helper to fetch and display the popup ad on app/dashboard launch
  static Future<void> showIfAvailable(
    BuildContext context, {
    String? organizationId,
    bool force = false,
  }) async {
    try {
      final service = OfferBannerService();
      final ad = await service.fetchActivePopupAd(organizationId: organizationId);

      if (ad == null || !ad.isActive || ad.imageUrl.trim().isEmpty) {
        return;
      }

      // 1. Scheduled Date Range Check
      final now = DateTime.now();
      if (ad.startDate != null && now.isBefore(ad.startDate!)) {
        debugPrint('[POPUP_AD] Ad #${ad.id} starts in future (${ad.startDate}). Skipping.');
        return;
      }
      if (ad.endDate != null && now.isAfter(ad.endDate!)) {
        debugPrint('[POPUP_AD] Ad #${ad.id} ended on ${ad.endDate}. Skipping.');
        return;
      }

      // 2. Session Deduplication (don't show again in current app session on tab switch)
      if (!force && _shownBannerIdsThisSession.contains(ad.id)) {
        debugPrint('[POPUP_AD] Ad #${ad.id} already shown this session. Skipping.');
        return;
      }

      // 3. Per-Mobile Impression Cap (e.g., 1, 2, 5, 6 times or continuous = 0)
      final prefs = await SharedPreferences.getInstance();
      final impressionKey = 'popup_ad_device_impressions_${ad.id}';
      final currentImpressions = prefs.getInt(impressionKey) ?? 0;

      if (!force && ad.maxDisplayCount > 0 && currentImpressions >= ad.maxDisplayCount) {
        debugPrint('[POPUP_AD] Ad #${ad.id} reached per-device impression cap ($currentImpressions >= ${ad.maxDisplayCount}). Skipping.');
        return;
      }

      if (!context.mounted) return;

      // Register session display and increment device impression count
      _shownBannerIdsThisSession.add(ad.id);
      await prefs.setInt(impressionKey, currentImpressions + 1);
      debugPrint('[POPUP_AD] Displaying ad #${ad.id} on device (count: ${currentImpressions + 1}, limit: ${ad.maxDisplayCount > 0 ? ad.maxDisplayCount : "continuous"})');

      if (!context.mounted) return;

      // Start fetching image bytes immediately
      precacheImage(CachedNetworkImageProvider(ad.imageUrl), context).catchError((_) {});

      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss Popup Ad',
        barrierColor: Colors.black.withValues(alpha: 0.72),
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return Center(
            child: OfferPopupAdDialog(ad: ad),
          );
        },
        transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
          final curvedValue = Curves.easeOutBack.transform(animation.value);
          return Transform.scale(
            scale: 0.85 + (curvedValue * 0.15),
            child: Opacity(
              opacity: animation.value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('[POPUP_AD] Error showing popup ad dialog: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxDialogWidth = (mediaQuery.size.width * 0.90).clamp(290.0, 440.0);
    final maxDialogHeight = mediaQuery.size.height * 0.78;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: maxDialogWidth,
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close Button Bar (Floating sleek pill above the card)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GestureDetector(
                  onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            // Main Popup Ad Image Card
            // No white screen box during load: shows a sleek round loader directly in the black fade
            Flexible(
              child: GestureDetector(
                onTap: () {
                  // Dismiss the dialog first, then trigger redirection
                  Navigator.of(context, rootNavigator: true).pop();
                  OfferRedirectionHelper.handleRedirection(context, ad);
                },
                child: CachedNetworkImage(
                  imageUrl: ad.imageUrl,
                  fit: BoxFit.contain,
                  fadeInDuration: const Duration(milliseconds: 320),
                  placeholder: (context, url) => SizedBox(
                    height: (mediaQuery.size.height * 0.45).clamp(240.0, 360.0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.zero,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRect(
                      child: Image(
                        image: imageProvider,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
