import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'src/audio/audio_capture_service.dart';
import 'src/controllers/app_controller.dart';
import 'src/paths.dart';
import 'src/platform/window_setup.dart';
import 'src/repository/meeting_repository.dart';
import 'src/services/ai_consent_service.dart';
import 'src/services/app_mode_service.dart';
import 'src/services/auth_service.dart';
import 'src/services/backend_api_service.dart';
import 'src/services/device_id_service.dart';
import 'src/services/firebase_auth_service.dart';
import 'src/services/rest_auth_service.dart';
import 'src/services/usage_service.dart';
import 'src/transcription/fal_transcription_service.dart';
import 'src/transcription/managed_transcription_service.dart';
import 'src/summary/openrouter_summary_service.dart';
import 'src/summary/managed_summary_service.dart';
import 'src/ui/app_shell.dart';
import 'src/ui/pages/login_page.dart';
import 'src/ui/pages/register_page.dart';
import 'src/ui/theme/app_theme.dart';

/// Firebase native SDK is only available on Android, iOS, macOS, and Web.
/// Windows and Linux use the REST API implementation instead.
bool get _firebaseSupported {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_firebaseSupported) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }
  await setupWindow();

  final recordingsDir = await getRecordingsDir();
  final meetingsDir = await getMeetingsDir();
  final prefs = await SharedPreferences.getInstance();
  final audioService = AudioCaptureService(recordingsDir: recordingsDir);
  final repository = MeetingRepository(meetingsDir: meetingsDir);
  final aiConsentService = AiConsentService(prefs: prefs);
  final appModeService = AppModeService(prefs: prefs);
  final deviceIdService = DeviceIdService();

  // Auth service: native firebase_auth on supported platforms, REST API elsewhere
  final AuthService authService = _firebaseSupported
      ? FirebaseAuthService()
      : RestAuthService(apiKey: DefaultFirebaseOptions.web.apiKey);

  // Always create both service pairs so mode can be switched at runtime.
  final backendApiService = BackendApiService(deviceIdService: deviceIdService);
  final usageService = UsageService(backendApi: backendApiService);
  final managedTranscription = ManagedTranscriptionService(
    backendApi: backendApiService,
    usageService: usageService,
  );
  final managedSummary = ManagedSummaryService(backendApi: backendApiService);
  final falService = FalTranscriptionService();
  final openRouterService = OpenRouterSummaryService(
    appUrl:
        'https://github.com/guessedpencil/flutter-simple-meeting-recorder-transcriber-summarizer',
    appTitle: 'Meeting Recorder & Transcriber',
  );

  final appController = AppController(
    audioService: audioService,
    managedTranscriptionService: managedTranscription,
    managedSummaryService: managedSummary,
    falService: falService,
    openRouterService: openRouterService,
    repository: repository,
    aiConsentService: aiConsentService,
    appModeService: appModeService,
    backendApiService: backendApiService,
    usageService: usageService,
    authService: authService,
  );
  await appController.init();

  runApp(MeetingRecorderApp(controller: appController));
}

class MeetingRecorderApp extends StatefulWidget {
  const MeetingRecorderApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<MeetingRecorderApp> createState() => _MeetingRecorderAppState();
}

class _MeetingRecorderAppState extends State<MeetingRecorderApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authService = widget.controller.authService!;
    _router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              AppShell(controller: widget.controller),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginPage(authService: authService),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => RegisterPage(authService: authService),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AuthBridgeWidget(
      controller: widget.controller,
      child: MaterialApp.router(
        title: 'Meeting Recorder & Transcriber',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}

/// Listens to auth state changes and forwards sign-in/sign-out to AppController.
class _AuthBridgeWidget extends StatefulWidget {
  final AppController controller;
  final Widget child;

  const _AuthBridgeWidget({required this.controller, required this.child});

  @override
  State<_AuthBridgeWidget> createState() => _AuthBridgeWidgetState();
}

class _AuthBridgeWidgetState extends State<_AuthBridgeWidget> {
  StreamSubscription<AuthUser?>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.controller.authService?.authStateChanges.listen((user) async {
      if (user != null) {
        try {
          final token = await user.getIdToken();
          if (token != null) {
            widget.controller.onUserSignedIn(user.uid, token);
          }
        } catch (_) {
          // Non-fatal
        }
      } else {
        widget.controller.onUserSignedOut();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
