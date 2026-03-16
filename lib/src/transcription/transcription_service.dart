import 'package:cross_file/cross_file.dart';

import 'models.dart';

abstract class TranscriptionService {
  Future<TranscriptionResult> transcribeBlocking(XFile audioFile);
}
