import 'openrouter_summary_service.dart' show MeetingSummaryResult;

abstract class SummaryService {
  Future<MeetingSummaryResult> summarizeWithTitle({
    required String transcript,
    String? title,
    String? notes,
  });
}
