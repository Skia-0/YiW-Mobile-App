import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:yiw_field_report/models/field_report.dart';

class OfflineService extends ChangeNotifier {
  static const String _draftsBoxName = 'drafts';
  static const String _reportsBoxName = 'reports';
  static const String _settingsBoxName = 'settings';
  
  Box<String>? _draftsBox;
  Box<String>? _reportsBox;
  Box<String>? _settingsBox;
  
  bool _isInitialized = false;
  bool _isOffline = false;

  bool get isInitialized => _isInitialized;
  bool get isOffline => _isOffline;

  Future<void> initialize() async {
    try {
      _draftsBox = await Hive.openBox<String>(_draftsBoxName);
      _reportsBox = await Hive.openBox<String>(_reportsBoxName);
      _settingsBox = await Hive.openBox<String>(_settingsBoxName);
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing offline service: $e');
      rethrow;
    }
  }

  Future<void> saveDraft(FieldReport report) async {
    try {
      if (!_isInitialized) await initialize();
      
      final json = jsonEncode(report.toJson());
      await _draftsBox?.put(report.id, json);
      
      debugPrint('Draft saved: ${report.id}');
    } catch (e) {
      debugPrint('Error saving draft: $e');
      rethrow;
    }
  }

  Future<FieldReport?> getDraft(String reportId) async {
    try {
      if (!_isInitialized) await initialize();
      
      final json = _draftsBox?.get(reportId);
      if (json == null) return null;
      
      final map = jsonDecode(json) as Map<String, dynamic>;
      return FieldReport.fromJson(map);
    } catch (e) {
      debugPrint('Error getting draft: $e');
      return null;
    }
  }

  Future<List<FieldReport>> getDrafts() async {
    try {
      if (!_isInitialized) await initialize();
      
      final drafts = <FieldReport>[];
      final keys = _draftsBox?.keys ?? [];
      
      for (final key in keys) {
        final json = _draftsBox?.get(key);
        if (json != null) {
          final map = jsonDecode(json) as Map<String, dynamic>;
          drafts.add(FieldReport.fromJson(map));
        }
      }
      
      // Sort by updated date (newest first)
      drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return drafts;
    } catch (e) {
      debugPrint('Error getting drafts: $e');
      return [];
    }
  }

  Future<void> removeDraft(String reportId) async {
    try {
      if (!_isInitialized) await initialize();
      
      await _draftsBox?.delete(reportId);
      debugPrint('Draft removed: $reportId');
    } catch (e) {
      debugPrint('Error removing draft: $e');
      rethrow;
    }
  }

  Future<void> saveReport(FieldReport report) async {
    try {
      if (!_isInitialized) await initialize();
      
      final json = jsonEncode(report.toJson());
      await _reportsBox?.put(report.id, json);
      
      debugPrint('Report saved: ${report.id}');
    } catch (e) {
      debugPrint('Error saving report: $e');
      rethrow;
    }
  }

  Future<FieldReport?> getReport(String reportId) async {
    try {
      if (!_isInitialized) await initialize();
      
      final json = _reportsBox?.get(reportId);
      if (json == null) return null;
      
      final map = jsonDecode(json) as Map<String, dynamic>;
      return FieldReport.fromJson(map);
    } catch (e) {
      debugPrint('Error getting report: $e');
      return null;
    }
  }

  Future<List<FieldReport>> getReports() async {
    try {
      if (!_isInitialized) await initialize();
      
      final reports = <FieldReport>[];
      final keys = _reportsBox?.keys ?? [];
      
      for (final key in keys) {
        final json = _reportsBox?.get(key);
        if (json != null) {
          final map = jsonDecode(json) as Map<String, dynamic>;
          reports.add(FieldReport.fromJson(map));
        }
      }
      
      // Sort by created date (newest first)
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return reports;
    } catch (e) {
      debugPrint('Error getting reports: $e');
      return [];
    }
  }

  Future<void> removeReport(String reportId) async {
    try {
      if (!_isInitialized) await initialize();
      
      await _reportsBox?.delete(reportId);
      debugPrint('Report removed: $reportId');
    } catch (e) {
      debugPrint('Error removing report: $e');
      rethrow;
    }
  }

  Future<void> saveSetting(String key, dynamic value) async {
    try {
      if (!_isInitialized) await initialize();
      
      final json = jsonEncode(value);
      await _settingsBox?.put(key, json);
    } catch (e) {
      debugPrint('Error saving setting: $e');
      rethrow;
    }
  }

  Future<dynamic> getSetting(String key) async {
    try {
      if (!_isInitialized) await initialize();
      
      final json = _settingsBox?.get(key);
      if (json == null) return null;
      
      return jsonDecode(json);
    } catch (e) {
      debugPrint('Error getting setting: $e');
      return null;
    }
  }

  Future<void> removeSetting(String key) async {
    try {
      if (!_isInitialized) await initialize();
      
      await _settingsBox?.delete(key);
    } catch (e) {
      debugPrint('Error removing setting: $e');
      rethrow;
    }
  }

  Future<void> clearAllData() async {
    try {
      if (!_isInitialized) await initialize();
      
      await _draftsBox?.clear();
      await _reportsBox?.clear();
      await _settingsBox?.clear();
      
      debugPrint('All offline data cleared');
    } catch (e) {
      debugPrint('Error clearing data: $e');
      rethrow;
    }
  }

  Future<int> getDraftCount() async {
    try {
      if (!_isInitialized) await initialize();
      return _draftsBox?.length ?? 0;
    } catch (e) {
      debugPrint('Error getting draft count: $e');
      return 0;
    }
  }

  Future<int> getReportCount() async {
    try {
      if (!_isInitialized) await initialize();
      return _reportsBox?.length ?? 0;
    } catch (e) {
      debugPrint('Error getting report count: $e');
      return 0;
    }
  }

  void setOfflineStatus(bool isOffline) {
    _isOffline = isOffline;
    notifyListeners();
  }

  Future<void> syncOfflineData() async {
    try {
      // This method would sync offline data when connection is restored
      // Implementation depends on your sync strategy
      debugPrint('Syncing offline data...');
      
      // Get all drafts and reports
      final drafts = await getDrafts();
      final reports = await getReports();
      
      // TODO: Implement actual sync logic with backend
      // For now, just log the counts
      debugPrint('Found ${drafts.length} drafts and ${reports.length} reports to sync');
      
    } catch (e) {
      debugPrint('Error syncing offline data: $e');
      rethrow;
    }
  }
}