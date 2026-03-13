/// Web does not have access to a user documents directory.
///
/// These APIs exist so the rest of the app can build a service graph with the
/// same callsites; web-specific repositories/services simply ignore them.
Future<Object> getAppRootDir() async => Object();

Future<Object> getRecordingsDir() async => Object();

Future<Object> getNotesDir() async => Object();

Future<Object> getMeetingsDir() async => Object();

