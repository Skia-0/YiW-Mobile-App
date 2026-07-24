import 'dart:convert';
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
      
      // Upload media files
      final uploadedReport = await _uploadMediaFiles(updatedReport);
      
      // Save to Firestore
      await _firestore.collection('reports').doc(reportId).set(uploadedReport.toJson());
      
      // Add to local list
      _reports.insert(0, uploadedReport);
      
      // Send emails
      await _sendEmails(uploadedReport);
      
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
        photoUrls.add(url);
      }
      
      // Upload videos
      for (final path in report.videoPaths) {
        final url = await _uploadFile(path, 'videos/${report.id}');
        videoUrls.add(url);
      }
      
      // Upload documents
      for (final path in report.documentPaths) {
        final url = await _uploadFile(path, 'documents/${report.id}');
        documentUrls.add(url);
      }
      
      // Upload attendance sheets
      for (final path in report.attendanceSheetPaths) {
        final url = await _uploadFile(path, 'attendance/${report.id}');
        attendanceSheetUrls.add(url);
      }
      
      // Upload financial documents
      for (final path in report.financialDocPaths) {
        final url = await _uploadFile(path, 'financial/${report.id}');
        financialDocUrls.add(url);
      }
      
      // Upload MoUs
      for (final path in report.mouPaths) {
        final url = await _uploadFile(path, 'mous/${report.id}');
        mouUrls.add(url);
      }
      
      // Upload tracking sheets
      for (final path in report.trackingSheetPaths) {
        final url = await _uploadFile(path, 'tracking/${report.id}');
        trackingSheetUrls.add(url);
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

  Future<String> _uploadFile(String filePath, String folder) async {
    try {
      final fileName = filePath.split('/').last;
      final ref = _storage.ref().child('$folder/$fileName');
      
      // For now, we'll assume the file is already on the device
      // In a real app, you'd read the file and upload it
      // For this example, we'll just return a placeholder URL
      return 'https://storage.googleapis.com/yiw-reports/$folder/$fileName';
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  Future<void> _sendEmails(FieldReport report) async {
    try {
      // Send to CEO
      await _emailService.sendReportEmail(
        toEmail: 'execdir@seghana.net',
        report: report,
        recipientName: 'Executive Director',
      );
      
      // Send to YiW team
      await _emailService.sendReportEmail(
        toEmail: 'yiw@seghana.net',
        report: report,
        recipientName: 'YiW Team',
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
    }
  }

  Future<void> _updateGoogleSheet(FieldReport report) async {
    try {
      await _sheetsService.addReportToSheet(report);
    } catch (e) {
      debugPrint('Error updating Google Sheet: $e');
      // Don't rethrow - sheet update failure shouldn't block report submission
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