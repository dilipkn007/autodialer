import 'package:flutter/material.dart';
import 'overlay_survey_widget.dart';

void runOverlayApp() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayApp());
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
        fontFamily: 'Inter',
      ),
      home: const OverlaySurveyWidget(),
    );
  }
}
