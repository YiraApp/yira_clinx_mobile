// Renders the login and OTP verification screens at phone sizes.
// Any layout overflow fails the test. Run with DIET_SHOTS=<dir> and
// --update-goldens to also save screenshots.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/config/app_theme/app_theme.dart';
import 'package:yiraclinics/core/local/shared_preferences.dart';
import 'package:yiraclinics/features/domain/entities/send_otp/send_otp_entity.dart';
import 'package:yiraclinics/features/presentation/auth/login_bloc/login_bloc.dart';
import 'package:yiraclinics/features/presentation/auth/login_screen.dart';
import 'package:yiraclinics/features/presentation/auth/signup_screen.dart';
import 'package:yiraclinics/features/presentation/auth/verify_otp_screen.dart';
import 'package:yiraclinics/features/use_cases/login_email_use_case.dart';
import 'package:yiraclinics/features/use_cases/login_mobile_use_case.dart';
import 'package:yiraclinics/features/use_cases/register_patient_use_case.dart';
import 'package:yiraclinics/features/use_cases/send_otp_use_case.dart';
import 'package:yiraclinics/features/use_cases/send_signup_otp_use_case.dart';
import 'package:yiraclinics/features/use_cases/update_fcm_token_use_case.dart';

class _LoginMobile implements LoginMobileUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LoginEmail implements LoginEmailUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SendOtp implements SendOtpUseCase {
  @override
  Future<SendOtpEntity?> call({required String mobileNumber, required String countryCode, required bool isReSend}) async =>
      SendOtpEntity(
        status: true,
        data: SendOtpDataEntity(otpSent: true, sessionId: isReSend ? 'session-2' : 'session-1', contact: mobileNumber),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SendSignupOtp implements SendSignupOtpUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RegisterPatient implements RegisterPatientUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UpdateFcm implements UpdateFcmTokenUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _loadFonts() async {
  final poppins = FontLoader('Poppins');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    poppins.addFont(rootBundle.load('assets/fonts/Poppins-$w.ttf'));
  }
  await poppins.load();
  final root = Platform.environment['FLUTTER_ROOT'];
  final icons = root == null ? null : File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons != null && icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await loader.load();
  }
}

final String? _shotsDir = Platform.environment['DIET_SHOTS'];

late SharedPreferences _prefs;

LoginBloc _bloc() {
  return LoginBloc(
    loginMobileUseCase: _LoginMobile(),
    loginEmailUseCase: _LoginEmail(),
    sharedPrefsService: SharedPrefsService(_prefs),
    sendOtpUseCase: _SendOtp(),
    sendSignupOtpUseCase: _SendSignupOtp(),
    registerPatientUseCase: _RegisterPatient(),
    updateFcmTokenUseCase: _UpdateFcm(),
  );
}

Widget _app(LoginBloc bloc, Widget child) => BlocProvider<LoginBloc>.value(
      value: bloc,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        supportedLocales: const [Locale('en')],
        home: child,
      ),
    );

// Lets the first frame and entry animations finish. The country picker's
// localizations delegate is left out: it loads from assets with real async
// work that never completes inside the fake test clock.
Future<void> _settleLocalizations(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
}

// Error messages fade and grow in. Animations start on the frame after the
// state change, so render that frame first, then let them finish.
Future<void> _settleAnimations(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

void main() {
  setUpAll(() async {
    await _loadFonts();
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  for (final size in [const Size(393, 852), const Size(320, 640), const Size(1024, 768)]) {
    final tag = size.width > 1000 ? 'tablet' : size.width > 350 ? 'phone' : 'small';

    Future<void> sized(WidgetTester tester) async {
      tester.view.physicalSize = Size(size.width * 3, size.height * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    testWidgets('login screen renders both tabs ($tag)', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await sized(tester);
      final bloc = _bloc();
      await tester.pumpWidget(_app(bloc, const LoginScreen()));
      await _settleLocalizations(tester);

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Send OTP'), findsOneWidget);
      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/login_mobile_$tag.png')));
      }

      await tester.tap(find.text('Email Login'));
      await tester.pumpAndSettle();
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/login_email_$tag.png')));
      }
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('verify OTP screen renders ($tag)', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await sized(tester);
      final bloc = _bloc();
      await tester.pumpWidget(_app(
        bloc,
        const VerifyOtpScreen(
          sendOtpEntity: SendOtpEntity(
            status: true,
            data: SendOtpDataEntity(otpSent: true, sessionId: 's1', contact: '9876543210'),
          ),
        ),
      ));
      await _settleLocalizations(tester);
      expect(find.text('Verification Code'), findsOneWidget);
      expect(find.text('Verify & Continue'), findsOneWidget);
      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/verify_otp_$tag.png')));
      }
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('signup screen renders with password feedback ($tag)', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      // Tall view so the whole form is in one capture.
      tester.view.physicalSize = Size(size.width * 3, 1500 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final bloc = _bloc();
      await tester.pumpWidget(_app(bloc, const SignupScreen()));
      await _settleLocalizations(tester);
      expect(find.text('Create Account'), findsWidgets);
      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/signup_$tag.png')));
      }
      await tester.enterText(find.byType(TextFormField).at(4), 'Secret1');
      await tester.enterText(find.byType(TextFormField).at(5), 'Secret');
      await _settleAnimations(tester);
      expect(find.text('Passwords do not match'), findsOneWidget);
      await tester.tap(find.text('Create Account').last);
      await _settleAnimations(tester);
      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/signup_filled_$tag.png')));
      }
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('login screen shows field errors ($tag)', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await sized(tester);
      final bloc = _bloc();
      await tester.pumpWidget(_app(bloc, const LoginScreen()));
      await _settleLocalizations(tester);

      await tester.tap(find.text('Send OTP'));
      await _settleAnimations(tester);
      expect(find.text('Please enter a phone number'), findsOneWidget);
      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/login_mobile_error_$tag.png')));
      }

      await tester.tap(find.text('Email Login'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign In'));
      await _settleAnimations(tester);
      expect(find.text('Please enter your email or username'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/login_email_error_$tag.png')));
      }
      // Form validation announces errors on a short timer; let it fire.
      await tester.pump(const Duration(seconds: 1));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('verify OTP screen counts down after a resend and flags a short code ($tag)', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await sized(tester);
      final bloc = _bloc();
      await tester.pumpWidget(_app(
        bloc,
        const VerifyOtpScreen(
          sendOtpEntity: SendOtpEntity(
            status: true,
            data: SendOtpDataEntity(otpSent: true, sessionId: 'session-1', contact: '9876543210'),
          ),
        ),
      ));
      await _settleLocalizations(tester);

      bloc.add(const OnReSendOtp('9876543210', '+91'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('OTP resent successfully!'), findsOneWidget);
      // The confirmation snackbar floats over the bottom button; wait it out
      // frame by frame so its exit animation runs.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.text('OTP resent successfully!'), findsNothing);
      expect(find.textContaining('00:2'), findsOneWidget);

      await tester.tap(find.text('Verify & Continue'));
      await _settleAnimations(tester);
      expect(find.text('Please enter a valid 6-digit OTP'), findsOneWidget);
      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/verify_otp_error_$tag.png')));
      }

      // Let the resend countdown finish so no timer outlives the test.
      await tester.pump(const Duration(seconds: 31));
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
