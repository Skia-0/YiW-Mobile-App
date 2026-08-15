import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import 'package:yiw_field_report/models/field_report.dart';

class SheetsService {
  String? _spreadsheetId;
  String? _credentialsJson;

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

  static const String _sheetName = 'Field Reports';

  Future<void> addReportToSheet(FieldReport report) async {
    AutoRefreshingAuthClient? client;
    try {
      await _loadConfig();
      if (_spreadsheetId == null || _credentialsJson == null) {
        throw StateError(
            'Sheets config missing - check spreadsheet_id and private_key in secrets.json');
      }

      debugPrint('Adding report ${report.id} to Google Sheet...');

      final credentials = ServiceAccountCredentials.fromJson(_credentialsJson!);
      client = await clientViaServiceAccount(
        credentials,
        [sheets.SheetsApi.spreadsheetsScope],
      );

      final sheetsApi = sheets.SheetsApi(client);
      final row = _prepareRowData(report);

      // 1. The master log - every report from every hub.
      await _appendToTab(sheetsApi, _sheetName, row);

      // 2. The hub's own tab, so each hub has its own running sheet
      //    alongside the general one.
      final hubTab = hubTabName(report.trainingCentre.hub);
      if (hubTab != null && hubTab != _sheetName) {
        try {
          await _appendToTab(sheetsApi, hubTab, row);
        } catch (e) {
          // The master log already has the report; don't fail the submit
          // just because the per-hub copy didn't write.
          debugPrint('Could not write hub tab "$hubTab": $e');
        }
      } else if (hubTab == null) {
        debugPrint(
            'No hub on report ${report.id}; logged to "$_sheetName" only');
      }
    } catch (e) {
      // Surfaced so a silent sheet failure doesn't look like success.
      debugPrint('Error adding report to Google Sheet: $e');
      rethrow;
    } finally {
      client?.close();
    }
  }


  /// Appends one row to [tabName], creating and heading the tab if needed.
  Future<void> _appendToTab(
    sheets.SheetsApi api,
    String tabName,
    List<dynamic> row,
  ) async {
    // Make sure the tab exists and is headed, otherwise append throws
    // "Unable to parse range" and the report silently never lands.
    await _ensureSheetReady(api, tabName);

    // append() writes after the last populated row, so the newest report
    // always appears at the bottom of that tab.
    final response = await api.spreadsheets.values.append(
      sheets.ValueRange(values: [row]),
      _spreadsheetId!,
      "'$tabName'!A:AV",
      valueInputOption: 'USER_ENTERED',
      insertDataOption: 'INSERT_ROWS',
    );
    debugPrint(
        'Appended to "$tabName" at ${response.updates?.updatedRange ?? "(unknown row)"}');
  }

  /// The tab a report belongs to, derived from its hub.
  ///
  /// Returns null when no hub was recorded. Google Sheets tab titles cannot
  /// contain : \\ / ? * [ ] and are capped at 100 characters, so the hub name
  /// is sanitised rather than used raw.
  static String? hubTabName(String? hub) {
    final name = hub?.trim() ?? '';
    if (name.isEmpty) return null;
    var clean = name.replaceAll(RegExp(r"[:\\/?*\[\]]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.length > 100) clean = clean.substring(0, 100).trim();
    return clean.isEmpty ? null : clean;
  }

  /// Creates a tab and its header row if they are absent.
  ///
  /// Without this, a renamed/missing tab or an empty sheet made every append
  /// fail with an unhelpful parse error.
  Future<void> _ensureSheetReady(sheets.SheetsApi api,
      [String tabName = _sheetName]) async {
    final spreadsheet = await api.spreadsheets.get(_spreadsheetId!);
    final existing = spreadsheet.sheets
            ?.map((s) => s.properties?.title)
            .whereType<String>()
            .toList() ??
        <String>[];

    if (!existing.contains(tabName)) {
      debugPrint('Creating "$tabName" tab (found: ${existing.join(", ")})');
      await api.spreadsheets.batchUpdate(
        sheets.BatchUpdateSpreadsheetRequest(requests: [
          sheets.Request(
            addSheet: sheets.AddSheetRequest(
              properties: sheets.SheetProperties(title: tabName),
            ),
          ),
        ]),
        _spreadsheetId!,
      );
    }

    // Header row: only write it when row 1 is empty, so an existing sheet
    // with the team's own headers is left untouched.
    final firstRow = await api.spreadsheets.values.get(
      _spreadsheetId!,
      "'$tabName'!A1:AV1",
    );
    final isEmpty = firstRow.values == null ||
        firstRow.values!.isEmpty ||
        firstRow.values!.first.every((c) => c.toString().trim().isEmpty);

    if (isEmpty) {
      debugPrint('Writing header row to "$tabName"');
      await api.spreadsheets.values.update(
        sheets.ValueRange(values: [_headerRow]),
        _spreadsheetId!,
        "'$tabName'!A1:AV1",
        valueInputOption: 'RAW',
      );

      // Freeze the header so it stays visible as the log grows.
      final sheetId = (await api.spreadsheets.get(_spreadsheetId!))
          .sheets
          ?.firstWhere((s) => s.properties?.title == _sheetName)
          .properties
          ?.sheetId;
      if (sheetId != null) {
        await api.spreadsheets.batchUpdate(
          sheets.BatchUpdateSpreadsheetRequest(requests: [
            sheets.Request(
              updateSheetProperties: sheets.UpdateSheetPropertiesRequest(
                properties: sheets.SheetProperties(
                  sheetId: sheetId,
                  gridProperties:
                      sheets.GridProperties(frozenRowCount: 1),
                ),
                fields: 'gridProperties.frozenRowCount',
              ),
            ),
          ]),
          _spreadsheetId!,
        );
      }
    }
  }

  /// Test hooks - keep the row and header widths verifiably in sync.
  @visibleForTesting
  static List<String> get headerRowForTest => _headerRow;
  @visibleForTesting
  static List<dynamic> rowForTest(FieldReport r) =>
      SheetsService()._prepareRowData(r);

  static const List<String> _headerRow = [
    'Submitted At', // A
    'Field Personnel Name', // B
    'Phone', // C
    'Zone', // D
    'Visit Date', // E
    'Visit Type', // F
    'Hub / TSP', // G
    'Community', // H
    'Training Centre', // I
    'Time Arrived', // J
    'Time Departed', // K
    'Male', // L
    'Female', // M
    'PWD', // N
    'Staff', // O
    'Trainers', // P
    'Total Youth', // Q
    'Formal Jobs', // R
    'Internships', // S
    'Cooperatives', // T
    'Further Training', // U
    'Total Activations', // V
    'Enrolments (M)', // W
    'Enrolments (F)', // X
    'Course', // Y
    'Employer', // Z
    'Sector', // AA
    'Hub Rating', // AB
    'Quality Indicators', // AC
    'Issues Flagged', // AD
    'Facilities', // AE
    'Challenges', // AF
    'Partners Count', // AG
    'Total Files', // AH
    'Attendance Docs', // AI
    'Financial Docs', // AJ
    'MoUs', // AK
    'Tracking Sheets', // AL
    'Photos', // AM
    'Videos', // AN
    'Safeguarding Items', // AO
    'Safeguarding Details', // AP
    'Concern Raised', // AQ
    'Concern Detail', // AR
    'Final Notes', // AS
    'Document Links', // AT
    'Media Links', // AU
    'Report ID', // AV
  ];

  // This method matches the exact column order of the existing spreadsheet
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
      // P: Number of Trainers
      report.attendance.trainersPresent,
      // Q: Total Youth
      report.attendance.totalYouth,
      // R: Number of Formal Jobs
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
      // AF: Challenges
      report.challengesObserved ?? '',
      // AG: Partners Count
      report.partnerCompanies.length,
      // AH: Total Files
      report.photoPaths.length + report.videoPaths.length + report.documentPaths.length,
      // AI: Attendance Docs
      report.attendanceSheetPaths.length,
      // AJ: Financial Docs
      report.financialDocPaths.length,
      // AK: MoUs
      report.mouPaths.length,
      // AL: Tracking Sheets
      report.trackingSheetPaths.length,
      // AM: Photos
      report.photoPaths.length,
      // AN: Videos
      report.videoPaths.length,
      // AO: Safeguarding Items
      _getSafeguardingCount(report.safeguarding),
      // AP: Safeguarding Details
      _getSafeguardingDetails(report.safeguarding),
      // AQ: Concern Raised
      report.safeguarding.concernIdentified ? 'Yes' : 'No',
      // AR: Concern Detail
      report.safeguarding.concernDescription ?? '',
      // AS: Final Notes
      report.finalNotes ?? '',
      // AT: Attendance / Financial / MoU / Tracking file links
      _linkList([
        ...report.attendanceSheetPaths,
        ...report.financialDocPaths,
        ...report.mouPaths,
        ...report.trackingSheetPaths,
      ]),
      // AU: Photo & video links
      _linkList([...report.photoPaths, ...report.videoPaths]),
      // AV: Report ID (for cross-referencing Firestore)
      report.id,
    ];
  }

  /// Newline-separated URLs, so the cell stays readable in Sheets.
  String _linkList(List<String> paths) {
    final urls = paths.where((p) => p.startsWith('http')).toList();
    return urls.join('\n');
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
