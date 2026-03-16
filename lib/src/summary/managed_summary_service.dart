import '../services/backend_api_service.dart';
import 'openrouter_summary_service.dart' show MeetingSummaryResult;
import 'summary_service.dart';

class ManagedSummaryService implements SummaryService {
  final BackendApiService _backendApi;

  ManagedSummaryService({required BackendApiService backendApi})
      : _backendApi = backendApi;

  @override
  Future<MeetingSummaryResult> summarizeWithTitle({
    required String transcript,
    String? title,
    String? notes,
  }) async {
    if (transcript.trim().isEmpty) {
      throw ArgumentError.value(transcript, 'transcript', 'Must not be empty');
    }

    final result = await _backendApi.summarize(
      transcript: transcript,
      title: title,
      notes: notes,
    );

    return MeetingSummaryResult(
      title: (result['title'] as String?) ?? '',
      summary: (result['summary'] as String?) ?? '',
    );
  }
}
