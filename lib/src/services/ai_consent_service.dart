import 'package:shared_preferences/shared_preferences.dart';

class AiConsentService {
  static const String _aiConsentKey = 'ai_consent_accepted';

  final SharedPreferences _prefs;

  AiConsentService({required SharedPreferences prefs}) : _prefs = prefs;

  /// Check if user has accepted AI processing consent
  bool hasAcceptedAiConsent() {
    return _prefs.getBool(_aiConsentKey) ?? false;
  }

  /// Mark AI consent as accepted
  Future<void> acceptAiConsent() async {
    await _prefs.setBool(_aiConsentKey, true);
  }

  /// Reset AI consent (for testing/debugging)
  Future<void> resetAiConsent() async {
    await _prefs.remove(_aiConsentKey);
  }
}
