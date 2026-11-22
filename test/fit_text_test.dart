import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/core/common_widgets/common_text.dart';
import 'package:yiraclinics/core/widgets/fit_text.dart';

const _long = 'Sri Venkateswara Institute of Medical Sciences Super Speciality Hospital';

Widget _host(Widget child, {double width = 200, double? height}) => MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: width, height: height, child: child))),
    );

void main() {
  testWidgets('FitText shows every word, never "…"', (tester) async {
    await tester.pumpWidget(_host(const FitText(_long, style: TextStyle(fontSize: 16), maxLines: 2)));
    final text = tester.widget<Text>(find.text(_long));
    expect(text.overflow, TextOverflow.visible);
    expect(text.maxLines, isNull);
    expect(text.softWrap, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FitText shrinks the font to fit the lines it is given', (tester) async {
    await tester.pumpWidget(_host(const FitText(_long, style: TextStyle(fontSize: 16), maxLines: 2)));
    final size = tester.widget<Text>(find.text(_long)).style!.fontSize!;
    expect(size, lessThan(16));
    expect(size, greaterThanOrEqualTo(9));
  });

  testWidgets('FitText keeps the font when the text already fits', (tester) async {
    await tester.pumpWidget(_host(const FitText('Vitals', style: TextStyle(fontSize: 16), maxLines: 1)));
    expect(tester.widget<Text>(find.text('Vitals')).style!.fontSize, 16);
  });

  testWidgets('FitText in an app bar is not cut by the app bar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(appBar: AppBar(title: const FitText(_long, maxLines: 2)), body: const SizedBox()),
    ));
    final text = tester.widget<Text>(find.text(_long));
    expect(text.overflow, TextOverflow.visible);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CommonText wraps in full by default', (tester) async {
    await tester.pumpWidget(_host(const CommonText(_long)));
    final text = tester.widget<Text>(find.text(_long));
    expect(text.maxLines, isNull);
    expect(text.softWrap, isTrue);
    expect(text.overflow, TextOverflow.visible);
  });
}
