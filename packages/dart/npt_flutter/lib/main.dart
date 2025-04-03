import 'package:flutter/material.dart';
import 'package:npt_flutter/constants.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var windowOptions = const WindowOptions(
    title: "CareNET360 Manual Manager",
    minimumSize: Constants.kWindowsMinWindowSize,
    skipTaskbar: false,
  );
  windowManager.ensureInitialized();
  windowManager.waitUntilReadyToShow(windowOptions);
  runApp(const App());
}
