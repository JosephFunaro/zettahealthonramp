import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:npt_flutter/features/profile/profile.dart';
//import 'package:npt_flutter/styles/sizes.dart';
import 'package:npt_flutter/features/profile/helpers/profile_layout_helper.dart';

class ProfileViewSshStyle extends StatelessWidget {
  const ProfileViewSshStyle({super.key});

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
      final columnWidth =
          ProfileLayoutHelper.calculateColumnWidth(constraints.maxWidth);

      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // First column (aligned center)
          SizedBox(
            width: columnWidth,
            child: Center(
              child: ProfileDeviceName(width: columnWidth),
            ),
          ),
          const SizedBox(width: ProfileLayoutHelper.gapWidth),
          // Second column (aligned center)
          SizedBox(
            width: columnWidth,
            child: Center(
              child: ProfileDisplayName(width: columnWidth),
            ),
          ),
          const SizedBox(width: ProfileLayoutHelper.gapWidth),
          // Third column (aligned center)
          SizedBox(
            width: columnWidth,
            child: Center(
              child: ProfileServiceView(width: columnWidth),
            ),
          ),
          const SizedBox(width: ProfileLayoutHelper.gapWidth),
          // Fourth column (aligned center)
          SizedBox(
            width: columnWidth,
            child: Center(
              child: isAutoStart
                  ? AutoStartStatusMessage(width: columnWidth)
                  : ProfileStatusIndicator(
                      width: columnWidth, // Ensure consistent width
                    ),
            ),
          ),
          const SizedBox(width: ProfileLayoutHelper.gapWidth),
          // Fifth column (aligned center)
          if (!isAutoStart)
            SizedBox(
              width: columnWidth,
              child: const Center(
                child: ProfileRunButton(), // Ensure the button is centered
              ),
            ),
        ],
      );
    });
  }
}

class AutoStartStatusMessage extends StatelessWidget {
  const AutoStartStatusMessage({required this.width, super.key});
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width, // Use the same column width as other status messages
      child: const Padding(
        padding: EdgeInsets.symmetric(
            vertical: 8.0), // Add consistent vertical padding
        child: StatusMessage(
          tooltip:
              "Endpoint set to automatically start. If you wish to control this Endpoint manually, please change the setting in the Endpoint Details.",
          status: "Auto-Start Endpoint.",
          color: Colors.blue,
          icon: Icons.info,
        ),
      ),
    );
  }
}
