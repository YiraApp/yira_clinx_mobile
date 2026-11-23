// The launch splash always finishes, whether or not the story video can play.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/presentation/splash/yira_story_splash.dart';

void main() {
  testWidgets('scene only: shows the tagline and reports completion', (tester) async {
    var done = 0;
    await tester.pumpWidget(MaterialApp(home: YiraStorySplash(playStory: false, onComplete: () => done++)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(done, 0);
    await tester.pump(YiraStorySplash.sceneLength);
    await tester.pump(const Duration(milliseconds: 100));
    expect(done, 1);
    expect(find.text('Your complete health, in one app.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('story: five captioned slides, then the scene, then completion', (tester) async {
    var done = 0;
    await tester.pumpWidget(MaterialApp(home: YiraStorySplash(onComplete: () => done++)));
    var sawVideoConsult = false, sawHeart = false;
    for (var i = 0; i < 200 && done == 0; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      sawVideoConsult |= find.text('Video Consult').evaluate().isNotEmpty;
      sawHeart |= find.text('Heart & Vitals').evaluate().isNotEmpty;
    }
    expect(sawVideoConsult, isTrue);
    expect(sawHeart, isTrue);
    expect(done, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tapping the story skips to the scene', (tester) async {
    var done = 0;
    await tester.pumpWidget(MaterialApp(home: YiraStorySplash(onComplete: () => done++)));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Skip'));
    for (var i = 0; i < 40 && done == 0; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(done, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
