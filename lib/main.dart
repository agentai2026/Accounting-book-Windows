import 'dart:io';

import 'package:flutter/material.dart';

import 'package:ezbookkeeping_desktop/core/database/database_helper.dart';
import 'package:ezbookkeeping_desktop/desktop/services/window_service.dart';
import 'package:ezbookkeeping_desktop/desktop/widgets/bootstrap/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.initializeFfi();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await WindowService.initialize();
  }

  runApp(const AppBootstrap());
}
