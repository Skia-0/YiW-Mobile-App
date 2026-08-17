import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:yiw_field_report/models/field_report.dart';
import 'package:yiw_field_report/services/auth_service.dart';
import 'package:yiw_field_report/services/email_service.dart';
import 'package:yiw_field_report/services/sheets_service.dart';
import 'package:yiw_field_report/services/offline_service.dart';

class ReportService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _authService = AuthService();
  final EmailService _emailService = EmailService();
  final SheetsService _sheetsService = SheetsService();
  final OfflineService _offlineService = OfflineService();
  
  List<FieldReport> _reports = [];
  bool _isLoading = false;
  String? _error;

  List<FieldReport> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<FieldReport> createReport({
    required FieldReport report,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final user = _authService.user;
      final appUser = _authService.appUser;
      
      if (user == null || appUser == null) {
        throw Exception('User not authenticated');
      }
      
      // Generate ID if not provided
      final reportId = report.id.isEmpty ? const Uuid().v4() : report.id;
      
      // Update report with user info
      final updatedReport = report.copyWith(
        id: reportId,
        userId: user.uid,
        userName: appUser.fullName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'submitted',
      );
      
      _lastSubmitWarnings.clear();
      _uploadErrors.clear();

      // Upload media files (Firebase Storage)
      final uploadedReport = await _uploadMediaFiles(updatedReport);

      final expectedFiles = updatedReport.photoPaths.length +
          updatedReport.videoPaths.length +
          updatedReport.attendanceSheetPaths.length +
          updatedReport.financialDocPaths.length +
          updatedReport.mouPaths.length +
          updatedReport.trackingSheetPaths.length;
      final actualFiles = uploadedReport.photoPaths.length +
          uploadedReport.videoPaths.length +
          uploadedReport.attendanceSheetPaths.length +
          uploadedReport.financialDocPaths.length +
          uploadedReport.mouPaths.length +
          uploadedReport.trackingSheetPaths.length;
      if (actualFiles < expectedFiles) {
        final failed = expectedFiles - actualFiles;
        _lastSubmitWarnings.add(
            '$failed of $expectedFiles file(s) did not upload to cloud storage');
        // Surface the actual reason(s), de-duplicated.
        for (final reason in _uploadErrors.toSet().take(3)) {
          _lastSubmitWarnings.add('   • $reason');
        }
        _lastSubmitWarnings.add(
            'Files were still attached to the email, so recipients have them.');
      }
      
      // Save to Firestore
      await _firestore.collection('reports').doc(reportId).set(uploadedReport.toJson());
      
      // Add to local list
      _reports.insert(0, uploadedReport);
      
      // Send emails.
      //
      // Attach from `updatedReport` (the LOCAL device paths), not
      // `uploadedReport` (Storage URLs). If Storage is unavailable the URL list
      // is empty and recipients would get zero attachments - the files are
      // sitting on the phone either way, so email them directly.
      // The body still shows Storage links when uploads did succeed.
      await _sendEmails(
        uploadedReport,
        attachmentSource: updatedReport,
      );
      
      // Update Google Sheet
      await _updateGoogleSheet(uploadedReport);
      
      // Remove from offline storage if exists
      await _offlineService.removeDraft(reportId);
      
      _isLoading = false;
      _error = null;
      notifyListeners();
      
      return uploadedReport;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<FieldReport> _uploadMediaFiles(FieldReport report) async {
    try {
      final List<String> photoUrls = [];
      final List<String> videoUrls = [];
      final List<String> documentUrls = [];
      final List<String> attendanceSheetUrls = [];
      final List<String> financialDocUrls = [];
      final List<String> mouUrls = [];
      final List<String> trackingSheetUrls = [];
      
      // Upload photos
      for (final path in report.photoPaths) {
        final url = await _uploadFile(path, 'photos/${report.id}');
        if (url.isNotEmpty) photoUrls.add(url);
      }
      
      // Upload videos
      for (final path in report.videoPaths) {
        final url = await _uploadFile(path, 'videos/${report.id}');
        if (url.isNotEmpty) videoUrls.add(url);
      }
      
      // Upload documents
      for (final path in report.documentPaths) {
        final url = await _uploadFile(path, 'documents/${report.id}');
        if (url.isNotEmpty) documentUrls.add(url);
      }
      
      // Upload attendance sheets
      for (final path in report.attendanceSheetPaths) {
        final url = await _uploadFile(path, 'attendance/${report.id}');
        if (url.isNotEmpty) attendanceSheetUrls.add(url);
      }
      
      // Upload financial documents
      for (final path in report.financialDocPaths) {
        final url = await _uploadFile(path, 'financial/${report.id}');
        if (url.isNotEmpty) financialDocUrls.add(url);
      }
      
      // Upload MoUs
      for (final path in report.mouPaths) {
        final url = await _uploadFile(path, 'mous/${report.id}');
        if (url.isNotEmpty) mouUrls.add(url);
      }
      
      // Upload tracking sheets
      for (final path in report.trackingSheetPaths) {
        final url = await _uploadFile(path, 'tracking/${report.id}');
        if (url.isNotEmpty) trackingSheetUrls.add(url);
      }
      
      return report.copyWith(
        photoPaths: photoUrls,
        videoPaths: videoUrls,
        documentPaths: documentUrls,
        attendanceSheetPaths: attendanceSheetUrls,
        financialDocPaths: financialDocUrls,
        mouPaths: mouUrls,
        trackingSheetPaths: trackingSheetUrls,
      );
    } catch (e) {
      debugPrint('Error uploading media files: $e');
      rethrow;
    }
  }

  /// Uploads a local file to Firebase Storage and returns its download URL.
  ///
  /// Previously this returned a fabricated URL without uploading anything.
  /// Human-readable reasons the last submit partially failed.
  final List<String> _uploadErrors = [];

  Future<String> _uploadFile(String filePath, String folder) async {
    try {
      // Already a remote URL (e.g. re-submitting an existing report).
      if (filePath.startsWith('http')) return filePath;

      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Upload skipped, file missing: $filePath');
        return '';
      }

      // Prefix with a timestamp so two files with the same name can coexist.
      final rawName = filePath.split(Platform.pathSeparator).last.split('/').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$rawName';

      final ref = _storage.ref().child('$folder/$fileName');
      final task = await ref.putFile(file);
      return await task.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading file ($filePath): $e');
      final name = filePath.split(Platform.pathSeparator).last.split('/').last;
      _uploadErrors.add('$name: ${_friendlyStorageError(e)}');
      // Never let one bad attachment sink the whole report.
      return '';
    }
  }

  /// Turns Firebase Storage jargon into something a field officer can act on.
  String _friendlyStorageError(Object e) {
    final msg = e.toString();
    if (msg.contains('object-not-found') || msg.contains('404')) {
      return 'Cloud storage not set up (bucket missing)';
    }
    if (msg.contains('unauthorized') || msg.contains('permission')) {
      return 'No permission to upload (storage rules)';
    }
    if (msg.contains('canceled') || msg.contains('cancelled')) {
      return 'Upload cancelled';
    }
    if (msg.contains('retry-limit') || msg.contains('timeout')) {
      return 'Network too slow / timed out';
    }
    if (msg.contains('quota')) return 'Storage quota exceeded';
    return msg.length > 90 ? '${msg.substring(0, 90)}...' : msg;
  }

  Future<void> _sendEmails(
    FieldReport report, {
    FieldReport? attachmentSource,
  }) async {
    try {
      // Send to CEO
      await _emailService.sendReportEmail(
        toEmail: 'execdir@seghana.net',
        report: report,
        recipientName: 'Executive Director',
        attachmentSource: attachmentSource,
      );
      
      // Send to YiW team
      await _emailService.sendReportEmail(
        toEmail: 'yiw@seghana.net',
        report: report,
        recipientName: 'YiW Team',
        attachmentSource: attachmentSource,
      );
      
      // Send confirmation to sender
      if (report.focalPerson.email != null && report.focalPerson.email!.isNotEmpty) {
        await _emailService.sendConfirmationEmail(
          toEmail: report.focalPerson.email!,
          report: report,
        );
      }
    } catch (e) {
      debugPrint('Error sending emails: $e');
      _lastSubmitWarnings.add('Email delivery failed: $e');
    }
  }

  /// Set after each submit so the UI can report partial failures honestly
  /// instead of always showing "Success".
  final List<String> _lastSubmitWarnings = [];
  List<String> get lastSubmitWarnings => List.unmodifiable(_lastSubmitWarnings);

  Future<void> _updateGoogleSheet(FieldReport report) async {
    try {
      debugPrint('REPORT_SERVICE: Updating Google Sheet for report ${report.id}');
      debugPrint('REPORT_SERVICE: Hub = "${report.trainingCentre.hub}"');
      debugPrint('REPORT_SERVICE: OtherHubName = "${report.trainingCentre.otherHubName}"');
      
      await _sheetsService.addReportToSheet(report);
      
      final tabs = _sheetsService.lastWrittenTabs;
      debugPrint('REPORT_SERVICE: Written to tabs: $tabs');
      
      if (tabs.length < 2 && (report.trainingCentre.hub).trim().isNotEmpty) {
        _lastSubmitWarnings
            .add('Recorded in ${tabs.join(", ")} only (no hub tab written)');
      }
    } catch (e) {
      debugPrint('Error updating Google Sheet: $e');
      _lastSubmitWarnings.add('Google Sheet was not updated: $e');
    }
  }

  Future<void> loadReports() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final user = _authService.user;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Load from Firestore
      final querySnapshot = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      _reports = querySnapshot.docs
          .map((doc) => FieldReport.fromJson(doc.data()))
          .toList();
      
      // Load offline drafts
      final drafts = await _offlineService.getDrafts();
      for (final draft in drafts) {
        if (!_reports.any((r) => r.id == draft.id)) {
          _reports.add(draft);
        }
      }
      
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> saveDraft(FieldReport report) async {
    try {
      final user = _authService.user;
      final appUser = _authService.appUser;
      
      if (user == null || appUser == null) {
        throw Exception('User not authenticated');
      }
      
      final draft = report.copyWith(
        userId: user.uid,
        userName: appUser.fullName,
        updatedAt: DateTime.now(),
        status: 'draft',
      );
      
      await _offlineService.saveDraft(draft);
      
      // Update local list
      final index = _reports.indexWhere((r) => r.id == draft.id);
      if (index >= 0) {
        _reports[index] = draft;
      } else {
        _reports.insert(0, draft);
      }
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('reports').doc(reportId).delete();
      
      // Delete from local list
      _reports.removeWhere((r) => r.id == reportId);
      
      // Delete from offline storage
      await _offlineService.removeDraft(reportId);
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<FieldReport?> getReportById(String reportId) async {
    try {
      // Check local list first
      final localReport = _reports.firstWhere(
        (r) => r.id == reportId,
        orElse: () => throw Exception('Report not found'),
      );
      return localReport;
    } catch (e) {
      // Try to load from Firestore
      try {
        final doc = await _firestore.collection('reports').doc(reportId).get();
        if (doc.exists) {
          return FieldReport.fromJson(doc.data()!);
        }
        return null;
      } catch (e) {
        debugPrint('Error getting report: $e');
        return null;
      }
    }
  }
}