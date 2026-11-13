/// Lets API calls that are refused as "unauthorized" at the same moment share one token renewal.
///
/// Screens send their calls together, so when the access token expires several calls fail at
/// once. The first starts the renewal; the others wait for it instead of giving up, and a call
/// that fails after the token was already renewed just uses the new one.
class TokenRefreshGate {
  Future<String?>? _running;

  /// A token to retry with, for a call that was refused with [sentToken]: [currentToken] when
  /// another call has renewed it since, else the result of the one shared [renew] (null when the
  /// renewal failed). [renew] should return null rather than throw.
  Future<String?> freshToken({
    required String? sentToken,
    required String? currentToken,
    required Future<String?> Function() renew,
  }) {
    final running = _running;
    if (running != null) return running;
    if (currentToken != null && currentToken.isNotEmpty && currentToken != sentToken) {
      return Future.value(currentToken);
    }
    final started = _safely(renew).whenComplete(() => _running = null);
    _running = started;
    return started;
  }

  static Future<String?> _safely(Future<String?> Function() renew) async {
    try {
      return await renew();
    } catch (_) {
      return null;
    }
  }
}
