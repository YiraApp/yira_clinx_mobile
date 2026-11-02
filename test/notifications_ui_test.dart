// Notifications: where a tap goes, paging, filters and the list look.
// Run with DIET_SHOTS=<dir> and --update-goldens to also save screenshots.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/services/notification_services/notification_target.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/notifications/app_notification_entity.dart';
import 'package:yiraclinics/features/domain/repositories/notifications/notifications_repo.dart';
import 'package:yiraclinics/features/presentation/notifications/bloc/notifications_bloc.dart';
import 'package:yiraclinics/features/presentation/notifications/bloc/notifications_event.dart';
import 'package:yiraclinics/features/presentation/notifications/bloc/notifications_state.dart';
import 'package:yiraclinics/features/presentation/notifications/recent_notifications_screen.dart';
import 'package:yiraclinics/features/use_cases/notifications/clear_all_notifications_use_case.dart';
import 'package:yiraclinics/features/use_cases/notifications/delete_notification_use_case.dart';
import 'package:yiraclinics/features/use_cases/notifications/get_notifications_use_case.dart';
import 'package:yiraclinics/features/use_cases/notifications/mark_notification_read_use_case.dart';

Future<void> _loadFonts() async {
  final poppins = FontLoader('Poppins');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    poppins.addFont(rootBundle.load('assets/fonts/Poppins-$w.ttf'));
  }
  await poppins.load();
  for (final style in ['Bold', 'Fill', 'Duotone']) {
    await (FontLoader('Phosphor$style')..addFont(rootBundle.load('assets/fonts/phosphor/Phosphor-$style.ttf'))).load();
  }
}

final String? _shotsDir = Platform.environment['DIET_SHOTS'];

AppNotificationEntity _n(String id, String type, String title, String body, {bool read = false, int hoursAgo = 1, String? route}) =>
    AppNotificationEntity(
      id: id,
      userId: 'u',
      title: title,
      body: body,
      type: type,
      route: route,
      isRead: read,
      createdAt: DateTime.now().subtract(Duration(hours: hoursAgo)),
    );

/// 45 notifications on the server, served 30 a page.
class _FakeRepo implements NotificationsRepository {
  final pages = <int>[];
  late final all = [
    _n('1', 'APPOINTMENT_STATUS', 'Appointment Confirmed', 'Your appointment with Dr. Santhosh on 02 Nov at 11:15 AM is confirmed.'),
    _n('2', 'SYSTEM_ALERT', '💊 Time for your Tab Metazine MR!', 'Please take your scheduled dose (1 Dose - 1-0-1) - After Food.'),
    _n('3', 'HEALTH_TIPS', 'Daily Health Tip', 'Stay hydrated, eat balanced meals, and include physical activity in your daily routine. Small healthy habits can make a big difference over weeks and months!', read: true, hoursAgo: 3),
    _n('4', 'APPOINTMENT_STATUS', 'Appointment Cancelled', 'Your appointment with Dr. Santhosh on 02 Nov has been marked as Cancelled.', hoursAgo: 26),
    _n('5', 'MEDICAL_RECORD_ADDED', 'New lab report', 'Your thyroid profile report from Vijaya Diagnostics is ready.', read: true, hoursAgo: 30),
    _n('6', 'DOCTOR_SUGGESTION', 'Advice from Dr. Asha', 'Drink 3 litres of water a day and add buttermilk with a pinch of salt.', hoursAgo: 50),
    for (var i = 7; i <= 45; i++) _n('$i', 'OFFER_PROMOTION', 'Offer $i', 'Save on health checks', read: true, hoursAgo: 60 + i),
  ];

  @override
  Future<NotificationsPayloadEntity?> getNotifications({int page = 1, int limit = 30}) async {
    pages.add(page);
    final start = (page - 1) * limit;
    return NotificationsPayloadEntity(
      notifications: all.skip(start).take(limit).toList(),
      total: all.length,
      unreadCount: all.where((n) => !n.isRead).length,
    );
  }

  @override
  Future<bool> markAsRead(String notificationId) async => true;
  @override
  Future<bool> markAllAsRead() async => true;
  @override
  Future<bool> clearAllNotifications() async => true;
  @override
  Future<bool> deleteNotification(String notificationId) async => true;
}

NotificationsBloc _bloc(_FakeRepo repo) => NotificationsBloc(
      getNotificationsUseCase: GetNotificationsUseCase(repository: repo),
      markNotificationReadUseCase: MarkNotificationReadUseCase(repository: repo),
      clearAllNotificationsUseCase: ClearAllNotificationsUseCase(repository: repo),
      deleteNotificationUseCase: DeleteNotificationUseCase(repository: repo),
    );

void main() {
  setUpAll(_loadFonts);

  group('notificationTargetFor', () {
    NotificationTarget? patient(String type, [String? route, String title = '']) =>
        notificationTargetFor(type: type, route: route, title: title, isDoctor: false);

    test('patient notifications open the screen they are about', () {
      expect(patient('APPOINTMENT_STATUS')?.route, AppRoutes.patientAppointments);
      expect(patient('APPOINTMENT_REMINDER_10MIN')?.actionLabel, 'View appointment');
      expect(patient('TELECONSULT_START')?.actionLabel, 'Join consultation');
      expect(patient('PRESCRIPTION_ADDED')?.route, AppRoutes.userPrescriptionManagement);
      expect(patient('MEDICATION_REMINDER')?.route, AppRoutes.userPrescriptionManagement);
      expect(patient('MEDICAL_RECORD_ADDED')?.route, AppRoutes.patientDocuments);
      expect(patient('DOCTOR_SUGGESTION')?.route, AppRoutes.patientDoctorSuggestions);
      expect(patient('DIET_PLAN')?.route, AppRoutes.patientDietPlan);
      expect(patient('CONSENT_REQUIRED')?.route, AppRoutes.patientConsentsScreen);
    });

    test('doctor appointment notifications open the appointments tab', () {
      expect(notificationTargetFor(type: 'APPOINTMENT_BOOKED', isDoctor: true)?.route, AppRoutes.appointmentDashboardScreen);
      expect(notificationTargetFor(type: 'PRESCRIPTION_ADDED', isDoctor: true), isNull);
    });

    test('server routes are mapped or ignored', () {
      expect(patient('SYSTEM', '/diet-plan')?.route, AppRoutes.patientDietPlan);
      expect(patient('SYSTEM', '/prescriptions')?.route, AppRoutes.userPrescriptionManagement);
      expect(patient('SYSTEM', '/patientDashboard'), isNull);
      expect(patient('SYSTEM', '/somethingUnknown'), isNull);
      expect(patient('HEALTH_TIPS'), isNull);
      expect(patient('OFFER_PROMOTION', 'www.yira.ai/offer')?.url, 'https://www.yira.ai/offer');
    });
  });

  test('the list loads the next page and stops at the end', () async {
    final repo = _FakeRepo();
    final bloc = _bloc(repo)..add(const FetchNotificationsEvent());
    await bloc.stream.firstWhere((s) => s is NotificationsLoadedState);
    var s = bloc.state as NotificationsLoadedState;
    expect(s.notifications.length, 30);
    expect(s.hasMore, isTrue);
    bloc.add(const LoadMoreNotificationsEvent());
    await bloc.stream.firstWhere((s) => s is NotificationsLoadedState && !s.isLoadingMore && s.page == 2);
    s = bloc.state as NotificationsLoadedState;
    expect(s.notifications.length, 45);
    expect(s.hasMore, isFalse);
    bloc.add(const LoadMoreNotificationsEvent());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(repo.pages, [1, 2]);
    await bloc.close();
  });

  group('screen', () {
    late _FakeRepo repo;
    final opened = <String>[];

    setUp(() {
      repo = _FakeRepo();
      opened.clear();
      if (sl.isRegistered<NotificationsBloc>()) sl.unregister<NotificationsBloc>();
      sl.registerFactory<NotificationsBloc>(() => _bloc(repo));
    });

    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Poppins', primaryColor: const Color(0xFF2563EB)),
        home: const RepaintBoundary(child: RecentNotificationsScreen()),
        onGenerateRoute: (settings) {
          opened.add(settings.name ?? '');
          return MaterialPageRoute(builder: (_) => Scaffold(body: Text('opened ${settings.name}')));
        },
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('counts match the server and actions are shown', (tester) async {
      await pump(tester);
      expect(find.text('45'), findsOneWidget); // All = everything on the server, not just the first page
      expect(find.text('View appointment'), findsNWidgets(2));
      expect(find.text('Open my medicines'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (_shotsDir != null) {
        await expectLater(find.byType(RepaintBoundary).first, matchesGoldenFile('$_shotsDir/notifications.png'));
      }
    });

    testWidgets('tapping an appointment notification opens appointments', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Appointment Confirmed'));
      await tester.pumpAndSettle();
      expect(opened, [AppRoutes.patientAppointments]);
    });

    testWidgets('a tip has nowhere to go, so a tap shows all of its text', (tester) async {
      await pump(tester);
      final tip = find.textContaining('Stay hydrated');
      expect(tester.widget<Text>(tip).maxLines, 3);
      await tester.tap(find.text('Daily Health Tip'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(tip).maxLines, isNull);
      expect(opened, isEmpty);
    });

    testWidgets('kind filter shows only appointments', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Appointments'));
      await tester.pumpAndSettle();
      expect(find.text('Appointment Cancelled'), findsOneWidget);
      expect(find.text('Daily Health Tip'), findsNothing);
    });

    testWidgets('scrolling down loads the next page', (tester) async {
      await pump(tester);
      await tester.fling(find.byType(ListView).last, const Offset(0, -6000), 3000);
      await tester.pumpAndSettle();
      await tester.fling(find.byType(ListView).last, const Offset(0, -6000), 3000);
      await tester.pumpAndSettle();
      expect(repo.pages, containsAllInOrder([1, 2]));
    });
  });
}
