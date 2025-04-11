import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:npt_flutter/features/profile/profile.dart';
import 'package:npt_flutter/styles/sizes.dart';

class ProfileViewMinimal extends StatelessWidget {
  const ProfileViewMinimal({super.key});
  @override
  Widget build(BuildContext context) {
    // Access the Profile object from the ProfileBloc
    final profile = context.select((ProfileBloc bloc) {
      if (bloc.state is ProfileLoadedState) {
        return (bloc.state as ProfileLoadedState).profile;
      }
      return null;
    });

    // Check if the Profile object is available and if StartUpOption is "Automatic"
    final isAutoStart = profile?.startUpOption == "Automatic";

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      final width = SizeConfig.setProfileFieldWidth();
      return Row(mainAxisSize: MainAxisSize.min, children: [
        ProfileDeviceName(width: width),
        gapW10,
        ProfileDisplayName(width: width),
        gapW10,
        ProfileServiceView(width: width),
        gapW10,
        if (isAutoStart)
          AutoStartStatusMessage(width: width)
        else
          ProfileStatusIndicator(
              width: SizeConfig.setProfileFieldWidth(statusField: true)),
        gapW10,
        if (!isAutoStart) const Flexible(child: ProfileRunButton()),
      ]);
    });
  }
}
