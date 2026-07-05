import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayBridge {
  OverlayBridge._() {
    _listenToOverlay();
  }

  static final OverlayBridge instance = OverlayBridge._();

  final StreamController<Map<String, dynamic>> _surveyController =
      StreamController<Map<String, dynamic>>.broadcast();
  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _listenToOverlay() {
    try {
      debugPrint("OverlayBridge: registering overlayListener...");
      FlutterOverlayWindow.overlayListener.listen(
        (event) {
          debugPrint("OverlayBridge: RAW event received: $event");
          try {
            final decoded = jsonDecode(event as String) as Map<String, dynamic>;
            debugPrint("OverlayBridge: decoded event type=${decoded['type']}");
            if (!_surveyController.isClosed) {
              _surveyController.add(decoded);
              debugPrint("OverlayBridge: event added to _surveyController");
            }
          } catch (e) {
            debugPrint("OverlayBridge: error decoding event: $e event=$event");
          }
        },
        onError: (e) => debugPrint("OverlayBridge listener error: $e"),
        onDone: () => debugPrint("OverlayBridge listener done"),
      );
      debugPrint("OverlayBridge: listener registered");
    } catch (e) {
      debugPrint("OverlayBridge: error listening to overlay: $e");
    }
  }

  Stream<Map<String, dynamic>> get onSurveyResult {
    if (!_isAndroid) return const Stream.empty();
    return _surveyController.stream;
  }

  Future<bool> get isPermissionGranted async {
    if (!_isAndroid) return false;
    return FlutterOverlayWindow.isPermissionGranted();
  }

  Future<bool> requestPermission() async {
    if (!_isAndroid) return false;
    final result = await FlutterOverlayWindow.requestPermission();
    return result ?? false;
  }

  Future<bool> get isOverlayRunning async {
    if (!_isAndroid) return false;
    return FlutterOverlayWindow.isActive();
  }

  Future<void> showSurveyOverlay({
    required String contactName,
    required String contactPhone,
    required List<Map<String, dynamic>> surveyQuestions,
    required Map<String, String> currentAnswers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!_isAndroid) return;

    final dispatcher = ui.PlatformDispatcher.instance;
    final physicalSize = dispatcher.views.first.physicalSize;
    final pixelRatio = dispatcher.views.first.devicePixelRatio;
    final screenHeight = physicalSize.height / pixelRatio;

    final overlayHeight = (screenHeight - 32.0).clamp(1.0, screenHeight);

    final data = jsonEncode({
      'type': 'show_survey',
      'contactName': contactName,
      'contactPhone': contactPhone,
      'surveyQuestions': surveyQuestions,
      'currentAnswers': currentAnswers,
    });
    debugPrint("showSurveyOverlay: calling showOverlay (height=${overlayHeight.toInt()})");
    await FlutterOverlayWindow.showOverlay(
      height: overlayHeight.toInt(),
      width: WindowSize.matchParent,
      alignment: OverlayAlignment.center,
      enableDrag: false,
      flag: OverlayFlag.focusPointer,
      overlayTitle: 'FOLK Auto Dialer',
      overlayContent: 'Survey overlay active',
      startPosition: const OverlayPosition(0, 0),
    ).timeout(timeout, onTimeout: () => debugPrint("showSurveyOverlay: showOverlay timed out"));
    debugPrint("showSurveyOverlay: showOverlay completed, calling shareData");
    await FlutterOverlayWindow.shareData(data).timeout(timeout, onTimeout: () {
      debugPrint("showSurveyOverlay: shareData timed out");
      return null;
    });
    debugPrint("showSurveyOverlay: shareData completed");
  }

  Future<void> updateSurveyData({
    required String contactName,
    required String contactPhone,
    required List<Map<String, dynamic>> surveyQuestions,
    required Map<String, String> currentAnswers,
  }) async {
    if (!_isAndroid) return;
    final data = jsonEncode({
      'type': 'show_survey',
      'contactName': contactName,
      'contactPhone': contactPhone,
      'surveyQuestions': surveyQuestions,
      'currentAnswers': currentAnswers,
    });
    await FlutterOverlayWindow.shareData(data);
  }

  Future<void> notifySaveFailed(String message) async {
    if (!_isAndroid) return;
    await FlutterOverlayWindow.shareData(jsonEncode({
      'type': 'save_failed',
      'message': message,
    }));
  }

  Future<void> closeOverlay() async {
    if (!_isAndroid) return;
    try {
      await FlutterOverlayWindow.shareData(jsonEncode({'type': 'close_overlay'}))
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (_) {}
    try {
      await FlutterOverlayWindow.closeOverlay()
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
    } catch (_) {}
  }
}
