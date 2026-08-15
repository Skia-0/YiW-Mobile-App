import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Persists an in-progress report form so field officers never lose work.
///
/// Deliberately does NOT reuse [FieldReport]: that model's `toJson()` is lossy
/// (it drops overallRating, qualityIndicators, issuesFlagged, challenges,
/// recommendations, finalNotes and more), so a draft round-tripped through it
/// would silently discard most of what the user typed. This stores the flat
/// form state exactly as entered.
class DraftService {
  static const String _boxName = 'drafts';
  static const String _activeDraftKey = 'active_form_draft';

  Box<String> get _box => Hive.box<String>(_boxName);

  /// True when an unfinished form is waiting to be resumed.
  bool get hasDraft => _box.containsKey(_activeDraftKey);

  Future<void> save(Map<String, dynamic> data) async {
    try {
      final payload = <String, dynamic>{
        ...data,
        'savedAt': DateTime.now().toIso8601String(),
      };
      await _box.put(_activeDraftKey, jsonEncode(payload));
    } catch (e) {
      debugPrint('DraftService: failed to save draft: $e');
    }
  }

  Map<String, dynamic>? load() {
    try {
      final raw = _box.get(_activeDraftKey);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('DraftService: failed to read draft: $e');
      return null;
    }
  }

  /// When the draft was last written, or null if there is none.
  DateTime? get savedAt {
    final raw = load()?['savedAt'];
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> clear() async {
    try {
      await _box.delete(_activeDraftKey);
    } catch (e) {
      debugPrint('DraftService: failed to clear draft: $e');
    }
  }
}
