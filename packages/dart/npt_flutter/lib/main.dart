import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:npt_flutter/constants.dart';
import 'package:npt_flutter/features/profile/profile.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var windowOptions = const WindowOptions(
    title: "Connection Manager",
    minimumSize: Constants.kWindowsMinWindowSize,
    skipTaskbar: false,
  );
  windowManager.ensureInitialized();
  windowManager.waitUntilReadyToShow(windowOptions);

  runApp(
    BlocProvider(
      create: (context) => ProfileCacheCubit(ProfileRepository()),
      child: const App(),
    ),
  );
}
