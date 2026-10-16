// Renders the app icon artwork from the Pip mascot painter.
// Run: flutter test tool/render_icons_test.dart --update-goldens
// Output goes to tool/icons/, then tool/make_icons.py resizes it for Android, web and Play.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguapath/ui/mascot.dart';
import 'package:linguapath/ui/palette.dart';

Widget _canvas(Widget child) => MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(textDirection: TextDirection.ltr, child: Center(child: RepaintBoundary(child: child))),
    );

void main() {
  const size = 1024.0;

  Future<void> render(WidgetTester t, String name, Widget w) async {
    t.view.physicalSize = const Size(size, size);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(_canvas(SizedBox.square(dimension: size, child: w)));
    await expectLater(find.byType(RepaintBoundary).first, matchesGoldenFile('icons/$name.png'));
  }

  testWidgets('full icon', (t) => render(
        t,
        'icon-full',
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFD45C), Palette.sun, Color(0xFFFFB300)],
            ),
          ),
          alignment: const Alignment(0, 0.15),
          child: const Mascot(size: size * 0.8, animate: false, mood: MascotMood.happy),
        ),
      ));

  testWidgets('adaptive foreground', (t) => render(
        t,
        'icon-foreground',
        const Align(
          alignment: Alignment(0, 0.12),
          child: Mascot(size: size * 0.6, animate: false, mood: MascotMood.happy),
        ),
      ));
}
