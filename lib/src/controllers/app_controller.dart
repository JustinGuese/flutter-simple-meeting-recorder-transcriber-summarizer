import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../audio/audio_capture_service.dart';
import '../models/meeting.dart';
import '../repository/meeting_repository.dart';
import '../platform/fs_ops.dart';
import '../services/ai_consent_service.dart';
import '../services/app_mode_service.dart';
import '../services/auth_service.dart';
import '../services/backend_api_service.dart';
import '../services/usage_service.dart';
import '../transcription/fal_transcription_service.dart';
import '../transcription/managed_transcription_service.dart';
import '../transcription/transcription_service.dart';
import '../summary/managed_summary_service.dart';
import '../summary/openrouter_summary_service.dart';
import '../summary/summary_service.dart';
import '../ui/dialogs/ai_data_processing_dialog.dart';

enum MeetingSortOrder { recentlyModified, title }

class AppController extends ChangeNotifier {
  AppController({
    required AudioCaptureService audioService,
    required ManagedTranscriptionService managedTranscriptionService,
    required ManagedSummaryService managedSummaryService,
    required FalTranscriptionService falService,
    required OpenRouterSummaryService openRouterService,
    required MeetingRepository repository,
    required AiConsentService aiConsentService,
    required AppModeService appModeService,
    required BackendApiService backendApiService,
    required UsageService usageService,
    AuthService? authService,
  })  : _audioService = audioService,
        _managedTranscription = managedTranscriptionService,
        _managedSummary = managedSummaryService,
        _falService = falService,
        _openRouterService = openRouterService,
        repository = repository,
        _aiConsentService = aiConsentService,
        _appModeService = appModeService,
        _backendApiService = backendApiService,
        _usageService = usageService,
        _authService = authService;

  final AudioCaptureService _audioService;
  final ManagedTranscriptionService _managedTranscription;
  final ManagedSummaryService _managedSummary;
  final FalTranscriptionService _falService;
  final OpenRouterSummaryService _openRouterService;
  final MeetingRepository repository;
  final AiConsentService _aiConsentService;
  final AppModeService _appModeService;
  final BackendApiService _backendApiService;
  final UsageService _usageService;
  final AuthService? _authService;

  TranscriptionService get _transcriptionService =>
      isManagedMode ? _managedTranscription : _falService;
  SummaryService get _summaryService =>
      isManagedMode ? _managedSummary : _openRouterService;

  List<Meeting> _allMeetings = [];
  List<Meeting> get allMeetings => List.unmodifiable(_allMeetings);

  Meeting? _selectedMeeting;
  Meeting? get selectedMeeting => _selectedMeeting;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  MeetingSortOrder _sortOrder = MeetingSortOrder.recentlyModified;
  MeetingSortOrder get sortOrder => _sortOrder;

  void setSortOrder(MeetingSortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  List<Meeting> get filteredMeetings {
    final meetings = _searchQuery.isEmpty
        ? List<Meeting>.from(_allMeetings)
        : _allMeetings.where((m) => m.matchesQuery(_searchQuery)).toList();
    switch (_sortOrder) {
      case MeetingSortOrder.recentlyModified:
        meetings.sort((a, b) =>
            (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt));
      case MeetingSortOrder.title:
        meetings.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    return meetings;
  }

  RecordingState get recordingState => _audioService.state;

  Duration _elapsedRecording = Duration.zero;
  Duration get elapsedRecording => _elapsedRecording;

  double _audioLevel = 0.0;
  double get audioLevel => _audioLevel;

  Meeting? _activeMeeting;
  Meeting? get activeMeeting => _activeMeeting;

  bool _isTranscribing = false;
  bool get isTranscribing => _isTranscribing;

  bool _isSummarizing = false;
  bool get isSummarizing => _isSummarizing;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  FreeTierLimitException? _pendingPaywall;
  FreeTierLimitException? get pendingPaywall => _pendingPaywall;

  Timer? _elapsedTimer;
  Timer? _notesDebounce;
  StreamSubscription<double>? _audioLevelSub;

  // Getters for mode awareness
  bool get isManagedMode => _appModeService.currentMode == AppMode.managed;
  AppModeService get appModeService => _appModeService;
  UsageService get usageService => _usageService;
  BackendApiService get backendApiService => _backendApiService;
  AuthService? get authService => _authService;
  bool get isSignedIn => _authService?.currentUser != null;

  // Always available — needed for API key configuration regardless of current mode
  FalTranscriptionService get falService => _falService;
  OpenRouterSummaryService get openRouterService => _openRouterService;

  Future<void> init() async {
    _allMeetings = await repository.loadAll();
    notifyListeners();
  }

  Future<void> startRecording() async {
    try {
      _errorMessage = null;

      final meeting = Meeting.create();
      _allMeetings.insert(0, meeting);
      _activeMeeting = meeting;
      _selectedMeeting = meeting;
      await repository.save(meeting);
      notifyListeners();

      _audioService.onHourElapsed = (elapsed) async {
        _handleHourlyCheck(elapsed);
      };

      await _audioService.startRecording();
      _startElapsedTimer();

      _audioLevelSub = _audioService.audioLevelStream?.listen((level) {
        _audioLevel = level;
        notifyListeners();
      });

      notifyListeners();
    } catch (e) {
      if (_activeMeeting != null) {
        _allMeetings.removeWhere((m) => m.id == _activeMeeting!.id);
        _activeMeeting = null;
        _selectedMeeting = null;
      }
      _stopElapsedTimer();
      _errorMessage = 'Failed to start recording: $e';
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    try {
      if (_activeMeeting == null) return;

      _stopElapsedTimer();
      await _audioLevelSub?.cancel();
      _audioLevelSub = null;
      _audioLevel = 0.0;

      final files = await _audioService.stopAndSave();

      if (files.isNotEmpty) {
        final micFile = files.firstWhere(
          (f) =>
              f.name.contains('-mixed.') ||
              f.name.contains('-mic.') ||
              f.path.contains('-mixed.') ||
              f.path.contains('-mic.'),
          orElse: () => files.first,
        );
        final pth = micFile.path;
        _activeMeeting!.audioFilePath =
            (pth.trim().isNotEmpty) ? pth : 'web://${micFile.name}';
      }

      await repository.save(_activeMeeting!);
      _activeMeeting = null;
      notifyListeners();

      if (files.isNotEmpty) {
        _runTranscription(_selectedMeeting!, files.first);
      }
    } catch (e) {
      _errorMessage = 'Failed to stop recording: $e';
      notifyListeners();
    }
  }

  Future<void> stopRecordingWithAiConsent(BuildContext context) async {
    final isIosOrAndroid = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;

    if (isManagedMode) {
      try {
        final usage = await _usageService.fetchUsage();
        if (usage.isLimitReached) {
          final reason = (usage.meetingsLimit != null &&
                  usage.meetingsUsed >= usage.meetingsLimit!)
              ? 'meetings'
              : 'minutes';
          _pendingPaywall = FreeTierLimitException(
            meetingsUsed: usage.meetingsUsed,
            minutesUsed: usage.minutesUsed,
            reason: reason,
          );
          notifyListeners();
          return;
        }
      } catch (_) {}
    }

    if (isIosOrAndroid && !_aiConsentService.hasAcceptedAiConsent()) {
      final accepted = await AiDataProcessingDialog.show(context);
      if (accepted) {
        await _aiConsentService.acceptAiConsent();
        await stopRecording();
      }
    } else {
      await stopRecording();
    }
  }

  void clearPendingPaywall() {
    _pendingPaywall = null;
    notifyListeners();
  }

  void onUserSignedIn(String uid, String idToken) {
    _backendApiService.setFirebaseIdToken(idToken);
    _linkDeviceAsync(idToken);
    notifyListeners();
  }

  void onUserSignedOut() {
    _backendApiService.setFirebaseIdToken(null);
    notifyListeners();
  }

  void _linkDeviceAsync(String idToken) {
    _backendApiService.linkDevice(firebaseIdToken: idToken).catchError((_) {});
  }

  Future<void> onModeChanged() async {
    notifyListeners();
  }

  Future<void> _handleHourlyCheck(Duration elapsed) async {}

  void updateNotes(String notes) {
    if (_activeMeeting == null) return;

    _activeMeeting!.notes = notes;

    _notesDebounce?.cancel();
    _notesDebounce = Timer(const Duration(milliseconds: 500), () async {
      await repository.save(_activeMeeting!);
    });

    notifyListeners();
  }

  void selectMeeting(Meeting meeting) {
    _selectedMeeting = meeting;
    notifyListeners();
  }

  Future<void> renameMeeting(Meeting meeting, String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isNotEmpty) {
      meeting.title = trimmed;
      meeting.updatedAt = DateTime.now();
      await repository.save(meeting);
      notifyListeners();
    }
  }

  Future<void> deleteMeeting(Meeting meeting) async {
    await repository.delete(meeting);
    _allMeetings.removeWhere((m) => m.id == meeting.id);
    if (_selectedMeeting?.id == meeting.id) _selectedMeeting = null;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> openMeetingsFolder() async {
    try {
      final meetingsDir = repository.meetingsDirPath;
      await openFolder(meetingsDir);
    } catch (e) {
      _errorMessage = 'Could not open folder: $e';
      notifyListeners();
    }
  }

  void _startElapsedTimer() {
    _elapsedRecording = Duration.zero;
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedRecording += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _elapsedRecording = Duration.zero;
  }

  Future<void> _runTranscription(Meeting meeting, XFile micFile) async {
    meeting.transcriptionStatus = TranscriptionStatus.inProgress;
    meeting.summaryStatus = SummaryStatus.none;
    meeting.summary = null;
    meeting.summaryErrorMessage = null;
    _isTranscribing = true;
    notifyListeners();

    try {
      final result = await _transcriptionService.transcribeBlocking(micFile);
      meeting.transcription = result.text;
      meeting.chunks = result.chunks
          .map((c) => WhisperChunkRecord(
                text: c.text,
                start: c.timestamp?.first.toDouble(),
                end: c.timestamp?.last.toDouble(),
              ))
          .toList();
      meeting.languages = result.languages ?? [];
      meeting.transcriptionStatus = TranscriptionStatus.completed;

      if (meeting.transcription.isEmpty) return;

      try {
        meeting.summaryStatus = SummaryStatus.inProgress;
        _isSummarizing = true;
        notifyListeners();

        final summaryResult = await _summaryService.summarizeWithTitle(
          transcript: meeting.transcription,
          title: meeting.title,
          notes: meeting.notes,
        );

        meeting.summary = summaryResult.summary;
        meeting.summaryStatus = SummaryStatus.completed;
        meeting.summaryModel = 'google/gemini-2.5-flash';
        meeting.summaryGeneratedAt = DateTime.now();

        final aiTitle = summaryResult.title.trim();
        if (aiTitle.isNotEmpty) {
          meeting.title = _titleWithDatetime(aiTitle, meeting.createdAt);
          await _renameAudioFileToMatchMeetingTitle(meeting);
        }
      } on OpenRouterMissingKeyException catch (e) {
        meeting.summaryStatus = SummaryStatus.failed;
        meeting.summaryErrorMessage = e.toString();
      } on OpenRouterApiException catch (e) {
        meeting.summaryStatus = SummaryStatus.failed;
        meeting.summaryErrorMessage = e.toString();
      } catch (e) {
        meeting.summaryStatus = SummaryStatus.failed;
        meeting.summaryErrorMessage = 'Summary failed: $e';
      } finally {
        _isSummarizing = false;
      }
    } on FreeTierLimitException catch (e) {
      meeting.transcriptionStatus = TranscriptionStatus.failed;
      meeting.errorMessage = 'Free tier limit reached';
      _pendingPaywall = e;
      _errorMessage = 'Reached free tier limit';
    } catch (e) {
      meeting.transcriptionStatus = TranscriptionStatus.failed;
      meeting.errorMessage = e.toString();
      _errorMessage = 'Transcription failed: $e';
    } finally {
      _isTranscribing = false;
      meeting.updatedAt = DateTime.now();
      await repository.save(meeting);
      notifyListeners();
    }
  }

  String _titleWithDatetime(String baseTitle, DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$baseTitle $y-$m-$d $h:$min';
  }

  Future<void> _renameAudioFileToMatchMeetingTitle(Meeting meeting) async {
    final currentPath = meeting.audioFilePath;
    if (currentPath == null || currentPath.trim().isEmpty) return;
    if (!await fileExists(currentPath)) return;

    final dir = p.dirname(currentPath);
    final ext = p.extension(currentPath);
    final base = '${meeting.safeFilename}_${meeting.id}';
    var targetPath = p.join(dir, '$base$ext');
    if (p.equals(currentPath, targetPath)) return;

    if (await fileExists(targetPath)) {
      var i = 1;
      while (await fileExists(targetPath)) {
        targetPath = p.join(dir, '$base-$i$ext');
        i++;
      }
    }

    final renamedPath = await renameFile(currentPath, targetPath);
    if (renamedPath != null) {
      meeting.audioFilePath = renamedPath;
    }
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _notesDebounce?.cancel();
    _audioLevelSub?.cancel();
    super.dispose();
  }
}
