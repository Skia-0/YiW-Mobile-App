import 'dart:convert';
import 'package:flutter/material.dart';
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

  Future<void> addReportToSheet(FieldReport report) async {
    try {
      await _loadConfig();
      if (_spreadsheetId == null || _credentialsJson == null) {
        debugPrint('Sheets config not loaded');
        return;
      }

      debugPrint('Adding report ${report.id} to Google Sheet...');

      final credentials = ServiceAccountCredentials.fromJson(_credentialsJson!);
      final client = await clientViaServiceAccount(
        credentials,
        [sheets.SheetsApi.spreadsheetsScope],
      );

      final sheetsApi = sheets.SheetsApi(client);
      final row = _prepareRowData(report);

      final request = sheets.ValueRange(values: [row]);

      await sheetsApi.spreadsheets.values.append(
        request,
        _spreadsheetId!,
        'Field Reports!A:AQ',
        valueInputOption: 'USER_ENTERED',
      );

      client.close();
      debugPrint('Report added to Google Sheet successfully');
    } catch (e) {
      debugPrint('Error adding report to Google Sheet: $e');
    }
  }

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
