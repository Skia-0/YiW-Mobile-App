import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';
import 'package:yiw_field_report/models/field_report.dart';
import 'package:yiw_field_report/config/app_config.dart';

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

  /// Tabs written by the most recent submit, for reporting back to the user.
  final List<String> lastWrittenTabs = [];

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
      lastWrittenTabs.clear();

      // 1. The master log - every report from every hub.
      await _appendToTab(sheetsApi, _sheetName, row);

      // 2. The hub's own tab
      final rawHub = report.trainingCentre.hub;
      final hubTab = hubTabName(rawHub, knownHubs: AppConfig.allHubs);
      debugPrint('SHEETS: hub on report = "$rawHub" -> tab "$hubTab"');
      
      if (hubTab != null && hubTab != _sheetName) {
        try {
          await _appendToTab(sheetsApi, hubTab, row);
          debugPrint('Successfully wrote to hub tab: $hubTab');
        } catch (e) {
          debugPrint('ERROR writing to hub tab "$hubTab": $e');
          // Try to create the tab manually if it doesn't exist
          try {
            await _createTabManually(sheetsApi, hubTab);
            await _appendToTab(sheetsApi, hubTab, row);
            debugPrint('Created and wrote to new hub tab: $hubTab');
          } catch (e2) {
            debugPrint('Failed to create/write to hub tab: $e2');
          }
        }
      } else if (hubTab == null) {
        debugPrint('No hub on report ${report.id}; logged to "$_sheetName" only');
      }
    } catch (e) {
      debugPrint('Error adding report to Google Sheet: $e');
      rethrow;
    } finally {
      client?.close();
    }
  }

  Future<void> _createTabManually(sheets.SheetsApi api, String tabName) async {
    try {
      debugPrint('Manually creating tab: $tabName');
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
      
      // Add headers
      await api.spreadsheets.values.update(
        sheets.ValueRange(values: [_headerRow]),
        _spreadsheetId!,
        "'$tabName'!A1:AV1",
        valueInputOption: 'RAW',
      );
      debugPrint('Tab "$tabName" created with headers');
    } catch (e) {
      debugPrint('Error creating tab "$tabName": $e');
      rethrow;
    }
  }


  /// Reads row 1 of [tabName] so values can be matched to the sheet's own
  /// column order instead of assuming ours.
  Future<List<String>> _readHeader(sheets.SheetsApi api, String tabName) async {
    try {
      final res = await api.spreadsheets.values.get(
        _spreadsheetId!,
        "'$tabName'!A1:BZ1",
      );
      final first = res.values?.isNotEmpty == true ? res.values!.first : [];
      return first.map((c) => c.toString().trim()).toList();
    } catch (e) {
      debugPrint('Could not read header of "$tabName": $e');
      return [];
    }
  }

  /// Reorders our row to match the sheet's existing header.
  ///
  /// The previous version appended a fixed 48-column row and only wrote its own
  /// header when row 1 was empty. On a sheet that already had the team's own
  /// headers in a different order, every value landed under the wrong title.
  /// Matching by header text keeps data under the right column whatever the
  /// order, and leaves unrecognised columns untouched.
  List<dynamic> _alignToHeader(
    List<String> sheetHeader,
    List<dynamic> row,
  ) {
    if (sheetHeader.isEmpty) return row;

    String norm(String h) =>
        h.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    // Our own header -> value, so we can look up by name.
    final ours = <String, dynamic>{};
    for (var i = 0; i < _headerRow.length && i < row.length; i++) {
      ours[norm(_headerRow[i])] = row[i];
    }

    // A few tolerated spellings for the same column.
    const aliases = <String, List<String>>{
      'fieldpersonnelname': ['name', 'fieldofficer', 'officer', 'fullname',
          'personnelname', 'submittedby'],
      'submittedat': ['timestamp', 'date', 'datesubmitted', 'submissiondate'],
      'phone': ['phonenumber', 'contact', 'contactnumber', 'mobile'],
      'zone': ['region', 'zoneregion'],
      'hubtsp': ['hub', 'tsp', 'hubname', 'trainingserviceprovider'],
      'trainingcentre': ['centre', 'center', 'trainingcenter', 'centrename'],
      'visitdate': ['dateofvisit'],
      'visittype': ['typeofvisit', 'visittypes'],
      'male': ['youngmen', 'men', 'malecount'],
      'female': ['youngwomen', 'women', 'femalecount'],
      'pwd': ['personswithdisability', 'disability'],
      'documentlinks': ['documents', 'doclinks', 'files'],
      'medialinks': ['media', 'photolinks', 'photosvideos'],
      'reportid': ['id', 'reportreference'],
    };

    dynamic lookup(String sheetColumn) {
      final key = norm(sheetColumn);
      if (ours.containsKey(key)) return ours[key];
      for (final entry in aliases.entries) {
        final matches = key == entry.key || entry.value.contains(key);
        if (matches && ours.containsKey(entry.key)) return ours[entry.key];
      }
      return null; // unknown column - leave it alone
    }

    return sheetHeader.map<dynamic>((h) => lookup(h) ?? '').toList();
  }

  /// Appends one row to [tabName], creating and heading the tab if needed.
  Future<void> _appendToTab(
    sheets.SheetsApi api,
    String tabName,
    List<dynamic> row,
  ) async {
    // Make sure the tab exists and is headed, otherwise append throws
    // "Unable to parse range" and the report silently never lands.
    // Resolves to the team's existing tab when one matches case-insensitively.
    tabName = await _ensureSheetReady(api, tabName);

    // Match the sheet's own column order rather than assuming ours.
    final sheetHeader = await _readHeader(api, tabName);
    final aligned = _alignToHeader(sheetHeader, row);

    // append() writes after the last populated row, so the newest report
    // always appears at the bottom of that tab.
    final response = await api.spreadsheets.values.append(
      sheets.ValueRange(values: [aligned]),
      _spreadsheetId!,
      "'$tabName'!A:AV",
      valueInputOption: 'USER_ENTERED',
      insertDataOption: 'INSERT_ROWS',
    );
    lastWrittenTabs.add(tabName);
    debugPrint(
        'Appended to "$tabName" at ${response.updates?.updatedRange ?? "(unknown row)"}');
  }

  /// The tab a report belongs to, derived from its hub.
  ///
  /// Returns null when no hub was recorded. Google Sheets tab titles cannot
  /// contain : \\ / ? * [ ] and are capped at 100 characters, so the hub name
  /// is sanitised rather than used raw.
  /// Tab used for hubs typed via "Other" rather than picked from the list.
  static const String unknownHubsTab = 'Unknown Hub';

  static String? hubTabName(String? hub, {List<String>? knownHubs}) {
    final name = hub?.trim() ?? '';
    if (name.isEmpty) return null;

    // "Other" should never become a tab title in its own right.
    if (name.toLowerCase() == 'other') {
      debugPrint('SHEETS: hub is "Other" -> routing to "$unknownHubsTab"');
      return unknownHubsTab;
    }

    // Check if the hub is in the known list
    if (knownHubs != null &&
        !knownHubs.any((h) => h.toLowerCase() == name.toLowerCase())) {
      debugPrint('SHEETS: hub "$name" not in known list -> routing to "$unknownHubsTab"');
      return unknownHubsTab;
    }
    
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
  /// Finds an existing tab whose name matches [wanted] ignoring case, spacing
  /// and punctuation, so "Unknown hubs", "UNKNOWN HUBS" and "Unknown-Hubs" all
  /// resolve to the team's existing tab instead of creating a duplicate.
  String? _matchExistingTab(List<String> existing, String wanted) {
    String norm(String v) =>
        v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    // Also fold a trailing plural, so "Unknown Hub" and "Unknown Hubs" are
    // treated as the same tab rather than creating a duplicate.
    String singular(String v) =>
        v.endsWith('s') ? v.substring(0, v.length - 1) : v;

    final target = norm(wanted);
    for (final title in existing) {
      if (norm(title) == target) return title;
    }
    for (final title in existing) {
      if (singular(norm(title)) == singular(target)) return title;
    }
    return null;
  }

  Future<String> _ensureSheetReady(sheets.SheetsApi api,
      [String tabName = _sheetName]) async {
    try {
      final spreadsheet = await api.spreadsheets.get(_spreadsheetId!);
      final existing = spreadsheet.sheets
              ?.map((s) => s.properties?.title)
              .whereType<String>()
              .toList() ??
          <String>[];

      // Reuse the team's tab if it already exists under a different casing.
      final match = _matchExistingTab(existing, tabName);
      debugPrint('SHEETS: existing tabs = ${existing.join(" | ")}');
      debugPrint('SHEETS: wanted "$tabName" -> matched ${match ?? "(none, will create)"}');
      if (match != null) tabName = match;

      if (!existing.contains(tabName)) {
        debugPrint('Creating "$tabName" tab (found: ${existing.join(", ")})');
        try {
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
          debugPrint('Tab "$tabName" created successfully');
        } catch (e) {
          debugPrint('Error creating tab "$tabName": $e');
          // Tab might already exist with different casing
          final existingMatch = _matchExistingTab(existing, tabName);
          if (existingMatch != null) {
            tabName = existingMatch;
            debugPrint('Using existing tab: $tabName');
          } else {
            rethrow;
          }
        }
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
      }

      return tabName;
    } catch (e) {
      debugPrint('Error in _ensureSheetReady for "$tabName": $e');
      rethrow;
    }
  }

  /// Test hooks - keep the row and header widths verifiably in sync.
  @visibleForTesting
  static List<String> get headerRowForTest => _headerRow;
  @visibleForTesting
  static String? matchTabForTest(List<String> existing, String wanted) =>
      SheetsService()._matchExistingTab(existing, wanted);
  @visibleForTesting
  static List<dynamic> alignForTest(List<String> header, List<dynamic> row) =>
      SheetsService()._alignToHeader(header, row);
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
      // G: Hub / TSP - use the actual typed name, not "Other"
      report.trainingCentre.otherHubName ?? report.trainingCentre.hub,
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
