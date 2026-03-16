import 'backend_api_service.dart';

class UsageInfo {
  final String tier;
  final int meetingsUsed;
  final int minutesUsed;
  final int? meetingsLimit;
  final int? minutesLimit;
  final int? meetingsRemaining;
  final int? minutesRemaining;
  final bool isLimitReached;

  const UsageInfo({
    required this.tier,
    required this.meetingsUsed,
    required this.minutesUsed,
    this.meetingsLimit,
    this.minutesLimit,
    this.meetingsRemaining,
    this.minutesRemaining,
    required this.isLimitReached,
  });

  factory UsageInfo.fromJson(Map<String, dynamic> json) => UsageInfo(
    tier: json['tier'] as String,
    meetingsUsed: json['meetings_used'] as int,
    minutesUsed: json['minutes_used'] as int,
    meetingsLimit: json['meetings_limit'] as int?,
    minutesLimit: json['minutes_limit'] as int?,
    meetingsRemaining: json['meetings_remaining'] as int?,
    minutesRemaining: json['minutes_remaining'] as int?,
    isLimitReached: json['is_limit_reached'] as bool,
  );

  factory UsageInfo.fromFreeTierException(FreeTierLimitException e) => UsageInfo(
    tier: 'free',
    meetingsUsed: e.meetingsUsed,
    minutesUsed: e.minutesUsed,
    meetingsLimit: 3,
    minutesLimit: 120,
    meetingsRemaining: (3 - e.meetingsUsed).clamp(0, 3),
    minutesRemaining: (120 - e.minutesUsed).clamp(0, 120),
    isLimitReached: true,
  );

  String get displayString {
    if (tier == 'free') {
      return '$meetingsUsed/${meetingsLimit ?? "?"} meetings · $minutesUsed/${minutesLimit ?? "?"} min used';
    } else if (tier == 'm') {
      return '$minutesUsed/${minutesLimit ?? "?"} min used this month';
    }
    return 'Unlimited';
  }
}

class UsageService {
  final BackendApiService _backendApi;
  UsageInfo? _cached;
  DateTime? _lastFetch;

  UsageService({required BackendApiService backendApi})
      : _backendApi = backendApi;

  UsageInfo? get cachedUsage => _cached;

  Future<UsageInfo> fetchUsage({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cached != null &&
        _lastFetch != null &&
        now.difference(_lastFetch!) < const Duration(minutes: 5)) {
      return _cached!;
    }
    final data = await _backendApi.getUsage();
    _cached = UsageInfo.fromJson(data);
    _lastFetch = now;
    return _cached!;
  }

  void invalidate() {
    _cached = null;
    _lastFetch = null;
  }
}
