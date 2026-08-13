import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Stores a raw snapshot of the in-progress report form.
///
/// Deliberately does NOT use [FieldReport]: that model's `toJson()` is lossy
/// (it drops ratings, quality indicators, challenges, notes, etc.), so a draft
/// round-tripped through it would silently lose most of the user's typing.
/// Here we persist the flat form state exactly as entered.
class DraftService {
  static const String _boxName = 'drafts';
  static const String _activeDraftKey = 'active_form_draft';

  Box<String> get _box => Hive.box<String>(_boxName);

  /// True when there is an unfinished form waiting to be resumed.
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

  /// When the draft was last written, or null if there is no draft.
  DateTime? get savedAt {
    final data = load();
    final raw = data?['savedAt'];
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
