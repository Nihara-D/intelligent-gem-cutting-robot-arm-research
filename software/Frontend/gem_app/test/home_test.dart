import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gem_app/screens/home_dashboard.dart';

void main() {
  testWidgets('HomeDashboard layout test', (WidgetTester tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      print('FLUTTER ERROR: ${details.exception}');
      throw details.exception;
    };
    
    // Simulate mobile screen
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(MaterialApp(
      routes: {
        '/': (context) => const HomeDashboard(),
        '/detection_input': (context) => Container(),
        '/history': (context) => Container(),
        '/profile': (context) => Container(),
      },
    ));
    
    await tester.pumpAndSettle();
    expect(find.byType(HomeDashboard), findsOneWidget);

    // clear overrides
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
