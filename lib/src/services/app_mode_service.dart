import 'package:shared_preferences/shared_preferences.dart';

enum AppMode { managed, openSource }

class AppModeService {
  static const _modeKey = 'app_mode';
  static const _onboardingShownKey = 'onboarding_shown';

  final SharedPreferences _prefs;

  AppModeService({required SharedPreferences prefs}) : _prefs = prefs;

  AppMode get currentMode {
    final val = _prefs.getString(_modeKey);
    return val == 'openSource' ? AppMode.openSource : AppMode.managed;
  }

  Future<void> setMode(AppMode mode) async {
    await _prefs.setString(_modeKey, mode.name);
  }

  bool get hasShownOnboarding => _prefs.getBool(_onboardingShownKey) ?? false;

  Future<void> markOnboardingShown() async {
    await _prefs.setBool(_onboardingShownKey, true);
  }
}
