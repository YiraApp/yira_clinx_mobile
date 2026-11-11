// The doctor picture falls back to the black-fill doctor icon when there's no photo.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/core/widgets/doctor_avatar_widget.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('no photo shows the doctor icon (${dark ? 'dark' : 'light'})', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        home: const Scaffold(body: Center(child: DoctorAvatarWidget(doctorName: 'Dr Rao', size: 50))),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
