import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class SurveyStateFile {
  SurveyStateFile._();

  static SurveyStateFile? _instance;
  static SurveyStateFile get instance => _instance ??= SurveyStateFile._();

  String? _path;

  Future<String> get path async {
    if (_path != null) return _path!;
    final dir = await getApplicationDocumentsDirectory();
    _path = '${dir.path}/survey_state.json';
    return _path!;
  }

  Future<void> write(Map<String, dynamic> data) async {
    try {
      final p = await path;
      await File(p).writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint("SurveyStateFile.write error: $e");
    }
  }

  Future<Map<String, dynamic>?> read() async {
    try {
      final p = await path;
      final file = File(p);
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("SurveyStateFile.read error: $e");
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final p = await path;
      final file = File(p);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("SurveyStateFile.clear error: $e");
    }
  }
}
