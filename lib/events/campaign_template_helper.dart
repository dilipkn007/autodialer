import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CampaignTemplateHelper {
  /// Generates and shares/downloads a reference CSV template containing sample
  /// contacts (validated by FOLK ID and Mobile), an optional enabler FOLK ID column,
  /// and sample survey questions.
  static Future<void> downloadSampleCsvTemplate(BuildContext context) async {
    try {
      final List<List<dynamic>> csvData = [
        [
          'FOLK ID',
          'Name',
          'Mobile',
          'Enabler FOLK ID',
          'Will you attend? (Yes, No)',
          'Need Transportation? (Own Vehicle, Need Pickup, Not Needed)',
          'Preferred Service',
          'Comments',
        ],
        [
          'FOLK-1001',
          'Rohit Sharma',
          '9876543210',
          'ENB-101',
          'Yes',
          'Need Pickup',
          'Prasadam Distribution',
          'Looking forward to attending!',
        ],
        [
          'FOLK-1002',
          'Sneha Patil',
          '9876543211',
          'ENB-102',
          'Yes',
          'Own Vehicle',
          'Decoration',
          'Will join along with friends',
        ],
        [
          'FOLK-1003',
          'Amit Kumar',
          '9876543212',
          '',
          'Maybe',
          'Not Needed',
          'Registration',
          'Will confirm by Friday',
        ],
      ];

      final csvString = Csv().encoder.convert(csvData);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/campaign_import_template.csv';
      final file = File(path);
      await file.writeAsString(csvString);

      await Share.shareXFiles(
        [XFile(path)],
        text: 'Campaign Creation CSV Template (Reference)',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
