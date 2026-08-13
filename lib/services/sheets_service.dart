import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import 'package:yiw_field_report/models/field_report.dart';

class SheetsService {
  String? _spreadsheetId;
  String? _credentialsJson;
  List<String>? _existingSheets;

  Future<void> _loadConfig() async {
    if (_spreadsheetId != null) return;
    try {
      final jsonStr = await rootBundle.loadString('lib/config/secrets.json');
      final config = jsonDecode(jsonStr);
      _spreadsheetId = config['spreadsheet_id'];
      _credentialsJson = jsonEncode({
        'type': 'service_account',
        'project_id': 'yiw-app',
        'private_key_id': '7676df19613adfe5131e9c8da6f7fbcd62c13855',
        'private_key': config['private_key'],
        'client_email': config['service_account_email'],
        'client_id': '113240302773439968823',
        'auth_uri': 'https://accounts.google.com/o/oauth2/auth',
        'token_uri': 'https://oauth2.googleapis.com/token',
        'auth_provider_x509_cert_url': 'https://www.googleapis.com/oauth2/v1/certs',
        'client_x509_cert_url': 'https://www.googleapis.com/robot/v1/metadata/x509/yiw-sheets%40yiw-app.iam.gserviceaccount.com',
        'universe_domain': 'googleapis.com',
      });
    } catch (e) {
      debugPrint('Error loading sheets config: $e');
    }
  }

  Future<sheets.SheetsApi> _getSheetsApi() async {
    final credentials = ServiceAccountCredentials.fromJson(_credentialsJson!);
    final client = await clientViaServiceAccount(
      credentials,
      [sheets.SheetsApi.spreadsheetsScope],
    );
    return sheets.SheetsApi(client);
  }

  // Get all existing sheet/tab names
  Future<List<String>> _getExistingSheets(sheets.SheetsApi sheetsApi) async {
    if (_existingSheets != null) return _existingSheets!;
    
    try {
      final spreadsheet = await sheetsApi.spreadsheets.get(_spreadsheetId!);
      _existingSheets = spreadsheet.sheets!
          .map((sheet) => sheet.properties!.title!)
          .toList();
      debugPrint('Existing sheets: $_existingSheets');
      return _existingSheets!;
    } catch (e) {
      debugPrint('Error getting existing sheets: $e');
      return [];
    }
  }

  // Find matching sheet name (case-insensitive)
  String? _findMatchingSheet(String targetName, List<String> existingSheets) {
    final normalizedTarget = targetName.toLowerCase().trim();
    
    for (final sheet in existingSheets) {
      if (sheet.toLowerCase().trim() == normalizedTarget) {
        return sheet; // Return the existing sheet name (preserves original casing)
      }
    }
    return null;
  }

  // Create a new sheet/tab if it doesn't exist
  Future<String?> _createSheetIfNotExists(sheets.SheetsApi sheetsApi, String sheetName) async {
    try {
      final existingSheets = await _getExistingSheets(sheetsApi);
      
      // Check if sheet already exists (case-insensitive)
      final existingMatch = _findMatchingSheet(sheetName, existingSheets);
      if (existingMatch != null) {
        debugPrint('Sheet "$sheetName" already exists as "$existingMatch"');
        return existingMatch;
      }
      
      // Create new sheet
      debugPrint('Creating new sheet: $sheetName');
      
      final request = sheets.BatchUpdateSpreadsheetRequest(
        requests: [
          sheets.Request(
            addSheet: sheets.AddSheetRequest(
              properties: sheets.SheetProperties(
                title: sheetName,
              ),
            ),
          ),
        ],
      );
      
      await sheetsApi.spreadsheets.batchUpdate(request, _spreadsheetId!);
      
      // Add headers to new sheet
      await _addSheetHeaders(sheetsApi, sheetName);
      
      // Update cached list
      _existingSheets?.add(sheetName);
      
      debugPrint('Created sheet: $sheetName');
      return sheetName;
    } catch (e) {
      debugPrint('Error creating sheet "$sheetName": $e');
      return null;
    }
  }

  // Add headers to a sheet
  Future<void> _addSheetHeaders(sheets.SheetsApi sheetsApi, String sheetName) async {
    try {
      final headers = [
        'Submitted At',
        'Field Personnel Name',
        'Phone',
        'Zone',
        'Visit Date',
        'Visit Type',
        'Hub / TSP',
        'Community',
        'Training Centre',
        'Time Arrived',
        'Time Departed',
        'Male',
        'Female',
        'PWD',
        'Staff',
        'Trainers',
        'Total Youth',
        'Formal Jobs',
        'Internships',
        'Cooperatives',
        'Further Training',
        'Total Activations',
        'Enrolments (M)',
        'Enrolments (F)',
        'Course',
        'Employer',
        'Sector',
        'Hub Rating',
        'Quality Indicators',
        'Issues Flagged',
        'Facilities',
        'Activities',
        'Challenges',
        'Recommendations',
        'Urgency',
        'Follow-up By',
        'Partners Count',
        'Partner Notes',
        'Safeguarding Items',
        'Safeguarding Details',
        'Concern Raised',
        'Concern Detail',
        'Final Notes',
        'Status',
      ];

      final request = sheets.ValueRange(values: [headers]);

      await sheetsApi.spreadsheets.values.update(
        request,
        _spreadsheetId!,
        '$sheetName!A1',
        valueInputOption: 'RAW',
      );
      
      debugPrint('Added headers to sheet: $sheetName');
    } catch (e) {
      debugPrint('Error adding headers to sheet "$sheetName": $e');
    }
  }

  Future<void> addReportToSheet(FieldReport report) async {
    try {
      await _loadConfig();
      if (_spreadsheetId == null || _credentialsJson == null) {
        debugPrint('Sheets config not loaded');
        return;
      }

      debugPrint('Adding report ${report.id} to Google Sheet...');

      final sheetsApi = await _getSheetsApi();
      final row = _prepareRowData(report);

      // 1. Add to main "Field Reports" tab
      await _addToSheet(sheetsApi, 'Field Reports', row);
      
      // 2. Add to zone-specific tab
      final zone = report.focalPerson.zone;
      if (zone.isNotEmpty) {
        final zoneSheet = await _createSheetIfNotExists(sheetsApi, zone);
        if (zoneSheet != null) {
          await _addToSheet(sheetsApi, zoneSheet, row);
        }
      }
      
      // 3. Add to hub-specific tab (optional)
      final hub = report.trainingCentre.hub;
      if (hub.isNotEmpty && hub != 'Other') {
        final hubSheet = await _createSheetIfNotExists(sheetsApi, 'Hub - $hub');
        if (hubSheet != null) {
          await _addToSheet(sheetsApi, hubSheet, row);
        }
      }

      debugPrint('Report added to Google Sheet successfully');
    } catch (e) {
      debugPrint('Error adding report to Google Sheet: $e');
    }
  }

  Future<void> _addToSheet(sheets.SheetsApi sheetsApi, String sheetName, List<dynamic> row) async {
    try {
      final request = sheets.ValueRange(values: [row]);

      await sheetsApi.spreadsheets.values.append(
        request,
        _spreadsheetId!,
        '$sheetName!A:AZ',
        valueInputOption: 'USER_ENTERED',
      );
      
      debugPrint('Added row to sheet: $sheetName');
    } catch (e) {
      debugPrint('Error adding row to sheet "$sheetName": $e');
    }
  }

  List<dynamic> _prepareRowData(FieldReport report) {
    return [
      // A: Submitted At
      report.createdAt.toIso8601String(),
      // B: Field Personnel Name
      report.focalPerson.fullName,
      // C: Phone
      report.focalPerson.phoneNumber,
      // D: Zone
      report.focalPerson.zone,
      // E: Visit Date
      report.focalPerson.visitDate.toIso8601String(),
      // F: Visit Type
      report.focalPerson.visitTypes.join(', '),
      // G: Hub / TSP
      report.trainingCentre.hub,
      // H: Community
      report.trainingCentre.community,
      // I: Training Centre
      report.trainingCentre.centreName,
      // J: Time Arrived
      report.trainingCentre.timeArrived?.toIso8601String() ?? '',
      // K: Time Departed
      report.trainingCentre.timeDeparted?.toIso8601String() ?? '',
      // L: Male
      report.attendance.youngMenPresent,
      // M: Female
      report.attendance.youngWomenPresent,
      // N: PWD
      report.attendance.personsWithDisability,
      // O: Staff
      report.attendance.hubStaffOnDuty,
      // P: Trainers
      report.attendance.trainersPresent,
      // Q: Total Youth
      report.attendance.totalYouth,
      // R: Formal Jobs
      report.employmentOutcome.placedInFormalEmployment,
      // S: Internships
      report.employmentOutcome.placedInInternships,
      // T: Cooperatives
      report.employmentOutcome.joinedCooperatives,
      // U: Further Training
      report.employmentOutcome.referredForFurtherTraining,
      // V: Total Activations
      report.employmentOutcome.youthActivatedToday,
      // W: Enrolments (M)
      report.newEnrolmentsMale.length,
      // X: Enrolments (F)
      report.newEnrolmentsFemale.length,
      // Y: Course
      report.courseEnrolledIn ?? '',
      // Z: Employer
      report.employmentOutcome.employerNames.join(', '),
      // AA: Sector
      report.employmentOutcome.sectorOfPlacement ?? '',
      // AB: Hub Rating
      report.overallRating ?? '',
      // AC: Quality Indicators
      report.qualityIndicators.join('; '),
      // AD: Issues Flagged
      report.issuesFlagged.join('; '),
      // AE: Facilities
      report.facilitiesAvailable.join('; '),
      // AF: Activities
      report.activitiesObserved.join('; '),
      // AG: Challenges
      report.challengesObserved ?? '',
      // AH: Recommendations
      report.recommendations ?? '',
      // AI: Urgency
      report.urgencyOfAction ?? '',
      // AJ: Follow-up By
      report.followUpBy ?? '',
      // AK: Partners Count
      report.partnerCompanies.length,
      // AL: Partner Notes
      report.partnerEngagementNotes ?? '',
      // AM: Safeguarding Items
      _getSafeguardingCount(report.safeguarding),
      // AN: Safeguarding Details
      _getSafeguardingDetails(report.safeguarding),
      // AO: Concern Raised
      report.safeguarding.concernIdentified ? 'Yes' : 'No',
      // AP: Concern Detail
      report.safeguarding.concernDescription ?? '',
      // AQ: Final Notes
      report.finalNotes ?? '',
      // AR: Status
      report.status,
    ];
  }

  int _getSafeguardingCount(dynamic safeguarding) {
    int count = 0;
    if (safeguarding.consentObtained) count++;
    if (safeguarding.twoAdultRule) count++;
    if (safeguarding.policyVisible) count++;
    if (safeguarding.noDiscrimination) count++;
    if (safeguarding.reportingMechanismCommunicated) count++;
    if (safeguarding.idBadgeWorn) count++;
    if (safeguarding.noPersonalContacts) count++;
    if (safeguarding.giftsFollowGuidelines) count++;
    return count;
  }

  String _getSafeguardingDetails(dynamic safeguarding) {
    List<String> items = [];
    if (safeguarding.consentObtained) items.add('Consent obtained');
    if (safeguarding.twoAdultRule) items.add('Two-adult rule');
    if (safeguarding.policyVisible) items.add('Policy visible');
    if (safeguarding.noDiscrimination) items.add('No discrimination');
    if (safeguarding.reportingMechanismCommunicated) items.add('Reporting mechanism');
    if (safeguarding.idBadgeWorn) items.add('ID badge worn');
    if (safeguarding.noPersonalContacts) items.add('No personal contacts');
    if (safeguarding.giftsFollowGuidelines) items.add('Gifts guidelines');
    return items.join('; ');
  }
}
