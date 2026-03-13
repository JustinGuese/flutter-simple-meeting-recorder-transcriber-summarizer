import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

Future<void> setupWindow() async {
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1000, 700),
    minimumSize: Size(900, 600),
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.normal,
  );

  unawaited(windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  }));
}

