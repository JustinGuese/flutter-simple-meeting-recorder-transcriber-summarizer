import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/meeting.dart';

class MeetingRepository {
  MeetingRepository({required Object meetingsDir});

  static const String _storageKey = 'meetings_v1';

  String get meetingsDirPath => 'web://localstorage';

  Future<List<Meeting>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return <Meeting>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Meeting>[];
      final meetings = decoded
          .whereType<Map<String, dynamic>>()
          .map(Meeting.fromJson)
          .toList(growable: false);
      final sorted = [...meetings]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sorted;
    } catch (_) {
      return <Meeting>[];
    }
  }

  Future<void> save(Meeting meeting) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    final idx = all.indexWhere((m) => m.id == meeting.id);
    final updated = [...all];
    if (idx >= 0) {
      updated[idx] = meeting;
    } else {
      updated.insert(0, meeting);
    }
    await _writeAll(prefs, updated);
  }

  Future<void> delete(Meeting meeting) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    final updated = all.where((m) => m.id != meeting.id).toList(growable: false);
    await _writeAll(prefs, updated);
  }

  Future<void> _writeAll(SharedPreferences prefs, List<Meeting> meetings) async {
    final encoded = jsonEncode(meetings.map((m) => m.toJson()).toList(growable: false));
    await prefs.setString(_storageKey, encoded);
  }
}

