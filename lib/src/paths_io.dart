import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Returns the root application directory under the user's documents folder.
Future<Directory> getAppRootDir() async {
  final docsDir = await getApplicationDocumentsDirectory();
  final appDir = Directory(p.join(docsDir.path, 'MeetingRecorderTranscriber'));
  if (!await appDir.exists()) {
    await appDir.create(recursive: true);
  }
  return appDir;
}

/// Returns (and creates if necessary) the recordings subdirectory.
Future<Directory> getRecordingsDir() async {
  final appDir = await getAppRootDir();
  final recordingsDir = Directory(p.join(appDir.path, 'recordings'));
  if (!await recordingsDir.exists()) {
    await recordingsDir.create(recursive: true);
  }
  return recordingsDir;
}

/// Returns (and creates if necessary) the notes subdirectory.
Future<Directory> getNotesDir() async {
  final appDir = await getAppRootDir();
  final notesDir = Directory(p.join(appDir.path, 'notes'));
  if (!await notesDir.exists()) {
    await notesDir.create(recursive: true);
  }
  return notesDir;
}

/// Returns (and creates if necessary) the meetings metadata subdirectory.
Future<Directory> getMeetingsDir() async {
  final appDir = await getAppRootDir();
  final meetingsDir = Directory(p.join(appDir.path, 'meetings'));
  if (!await meetingsDir.exists()) {
    await meetingsDir.create(recursive: true);
  }
  return meetingsDir;
}

