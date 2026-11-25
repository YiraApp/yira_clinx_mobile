import 'dart:async';

import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/constants/clinx_storage_keys.dart';
import 'package:yiraclinics/core/global_scaffold_key/global_scaffold_key.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/local/shared_preferences.dart';
import 'package:yiraclinics/core/navigation_services/navigation_services.dart';
import 'package:yiraclinics/core/services/share_into_yira/shared_report.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/presentation/patient/documents/patient_documents_screen.dart';

/// Whether a shared report can open now.
enum ShareReadiness {
  /// The app is starting, or still on a screen before home (onboarding, updates).
  wait,

  /// Nobody is signed in.
  signIn,

  /// Signed in to a doctor workspace, which has no My Documents.
  notPatient,

  /// A signed-in patient past the start-up screens.
  ready,
}

/// Takes PDFs and photos shared into Yira from other apps (Android share list,
/// iOS Share Extension) to My Documents, with the upload sheet open and the
/// files attached. A share that arrives before anyone is signed in waits until
/// a patient is, then opens.
class ShareIntoYira {
  ShareIntoYira({
    ShareReadiness Function()? readiness,
    Future<void> Function(SharedReport report)? open,
    void Function(String message)? tell,
    this.settle = const Duration(milliseconds: 400),
  })  : _readiness = readiness ?? currentReadiness,
        _open = open ?? openUploadFlow,
        _tell = tell ?? _snack;

  static final ShareIntoYira instance = ShareIntoYira();

  final ShareReadiness Function() _readiness;
  final Future<void> Function(SharedReport report) _open;
  final void Function(String message) _tell;

  /// How long a new screen gets to settle before the upload opens over it.
  final Duration settle;

  SharedReport? _pending;
  ShareReadiness? _told;
  bool _opening = false;
  bool _started = false;
  Timer? _timer;
  StreamSubscription<List<SharedMediaFile>>? _subscription;

  /// The share waiting for sign-in, if any.
  SharedReport? get pending => _pending;

  /// Starts listening for shares: the one that started the app, and any that
  /// arrive while it runs.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final plugin = ReceiveSharingIntent.instance;
      _subscription = plugin.getMediaStream().listen(
            receive,
            onError: (Object e) => debugPrint('[ShareIntoYira] Share failed: $e'),
          );
      final initial = await plugin.getInitialMedia();
      if (initial.isNotEmpty) receive(initial);
    } catch (e) {
      debugPrint('[ShareIntoYira] Sharing into the app is unavailable: $e');
    }
  }

  void receive(List<SharedMediaFile> media) {
    // So the same share isn't handed over again.
    unawaited(Future(() => ReceiveSharingIntent.instance.reset()).catchError((Object _) => null));
    final files = [
      for (final m in media)
        if (m.type != SharedMediaType.text && m.type != SharedMediaType.url && m.path.trim().isNotEmpty)
          SharedReportFile(path: m.path, mimeType: m.mimeType),
    ];
    if (files.isEmpty) return;
    final report = SharedReport(files);
    // Android can restore the app with a share it already handled.
    if (report.isGone) return;
    final older = _pending;
    _pending = report;
    _told = null;
    if (older != null) unawaited(older.discard());
    check();
  }

  /// Opens the waiting share if the app is ready for it. Runs when a share
  /// arrives and on every new screen (see the navigator observer in AppGateway).
  void check() {
    if (_pending == null) return;
    _timer?.cancel();
    _timer = Timer(settle, _checkNow);
  }

  void _checkNow() {
    final report = _pending;
    if (report == null || _opening) return;
    final readiness = _readiness();
    switch (readiness) {
      case ShareReadiness.ready:
        _pending = null;
        _told = null;
        _opening = true;
        _open(report).catchError((Object e) {
          debugPrint('[ShareIntoYira] Could not open the upload: $e');
        }).whenComplete(() {
          _opening = false;
          check();
        });
      case ShareReadiness.signIn:
        _hint(readiness, 'Sign in to upload ${_what(report)} to your records.');
      case ShareReadiness.notPatient:
        _hint(readiness, 'Switch to your patient profile to upload ${_what(report)}.');
      case ShareReadiness.wait:
        break;
    }
  }

  void _hint(ShareReadiness readiness, String message) {
    if (_told == readiness) return;
    _told = readiness;
    _tell(message);
  }

  static String _what(SharedReport report) {
    final usable = report.usable;
    if (usable.length == 1) return '"${usable.single.name}"';
    if (usable.isEmpty && report.files.length == 1) return '"${report.files.single.name}"';
    return 'the shared files';
  }

  static void _snack(String message) {
    Globals.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 6)),
    );
  }

  /// Screens a share must not open over: start-up, sign-in, onboarding and
  /// the app's blocking notices.
  static const Set<String> _beforeHome = {
    AppRoutes.initial,
    AppRoutes.signIn,
    AppRoutes.signup,
    AppRoutes.verifyOtp,
    AppRoutes.forgotPassword,
    AppRoutes.weightScale,
    AppRoutes.heightScale,
    AppRoutes.genderSelection,
    AppRoutes.userConfiguration,
    AppRoutes.selectRoleScreen,
    AppRoutes.workSpaceScreen,
    AppRoutes.organizationSwitch,
    AppRoutes.permissionScreen,
    AppRoutes.forceUpdateScreen,
    AppRoutes.softUpdateScreen,
    AppRoutes.maintenanceScreen,
    AppRoutes.sessionExpired,
    AppRoutes.serverDown,
    AppRoutes.unsupportedRole,
    AppRoutes.logOutScreen,
    AppRoutes.onSuccessChangePassword,
  };

  static ShareReadiness currentReadiness() {
    // Before the first frame, or while the splash screen decides where to go.
    // It clears the screen stack when it moves on, so wait for it.
    if (NavigationService.navigatorKey.currentState == null) return ShareReadiness.wait;
    final route = NavigationService.currentRoute;
    if (route == AppRoutes.initial) return ShareReadiness.wait;

    final loggedIn = sl.isRegistered<SharedPrefsService>() &&
        (sl<SharedPrefsService>().getValue<bool>(ClinxStorageKeys.isUserLoggedIn) ?? false);
    final user = GlobalSession.instance.userNotifier.value?.data;
    if (!loggedIn || (user?.id ?? '').trim().isEmpty) return ShareReadiness.signIn;
    if (_beforeHome.contains(route)) return ShareReadiness.wait;

    final navId = user?.navigationId?.toString().trim();
    final role = (user?.latestUserRole ?? '').toLowerCase();
    final isDoctor = role.contains('doctor') || role.contains('provider') || navId == '2';
    return isDoctor ? ShareReadiness.notPatient : ShareReadiness.ready;
  }

  /// My Documents with the upload sheet open and the shared files attached.
  /// When nothing in the share can be uploaded, says why instead.
  static Future<void> openUploadFlow(SharedReport report) async {
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) return;
    if (!report.hasUsable) {
      await showDialog<void>(
        context: navigator.context,
        builder: (ctx) => AlertDialog(
          title: const Text("Can't upload this"),
          content: Text(report.problem ?? "This file can't be uploaded. Yira takes PDFs and photos (JPG, PNG, HEIC)."),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
      await report.discard();
      return;
    }
    // Not awaited: a second share can open over this one.
    unawaited(navigator.push(MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.patientDocuments),
      builder: (_) => PatientDocumentsScreen(startUpload: true, shared: report),
    )));
  }

  @visibleForTesting
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
  }
}
