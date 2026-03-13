import 'dart:io';

Future<void> openFolder(String path) async {
  if (Platform.isWindows) {
    await Process.run('explorer', [path]);
  } else if (Platform.isMacOS) {
    await Process.run('open', [path]);
  } else if (Platform.isLinux) {
    await Process.run('xdg-open', [path]);
  }
}

Future<bool> fileExists(String path) async => File(path).exists();

Future<String?> renameFile(String from, String to) async {
  try {
    final renamed = await File(from).rename(to);
    return renamed.path;
  } catch (_) {
    return null;
  }
}

