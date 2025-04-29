import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:npt_flutter/features/profile/profile.dart';
import 'package:npt_flutter/widgets/spinner.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../styles/sizes.dart';

import 'dart:async';
import 'dart:io';
//import 'package:npt_flutter/util/export.dart';
//import 'package:npt_flutter/widgets/multi_select_dialog.dart';
//import 'package:npt_flutter/features/profile/profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
//import 'package:flutter_bloc/flutter_bloc.dart';
//import 'package:uuid/uuid.dart';
import 'package:encrypt/encrypt.dart' as crypt;

class ProfileRunButton extends StatefulWidget {
  const ProfileRunButton({super.key});

  @override
  State<ProfileRunButton> createState() => _ProfileRunButtonState();
}

class _ProfileRunButtonState extends State<ProfileRunButton> {
  StreamSubscription<ProfileState>? _blocSubscription;

  Future<void> _updateConnectionStatus(
      bool isSuccess, String serverClientGUID) async {
    final profileUpdateService = ProfileUpdateService();
    try {
      await profileUpdateService.updateProfileStatus(
          isSuccess, serverClientGUID);
      debugPrint(
          'Connection status updated: ${isSuccess ? "Success" : "Failure"} for GUID: $serverClientGUID');
    } catch (e) {
      debugPrint('Failed to update connection status: $e');
    }
  }

  void _handleStateChange(
      ProfileState newState, String serverClientGUID) async {
    if (!mounted) return; // Ensure the widget is still mounted
    if (newState is ProfileStarted) {
      // Profile successfully started
      await _updateConnectionStatus(true, serverClientGUID);
    } else if (newState is ProfileFailedStart) {
      // Profile failed to start
      await _updateConnectionStatus(false, serverClientGUID);
    }
  }

  @override
  void dispose() {
    // Cancel the subscription when the widget is disposed
    //_blocSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Sizes.p40,
      child: BlocSelector<ProfileBloc, ProfileState, ProfileLoadedState?>(
        selector: (ProfileState state) {
          if (state is ProfileLoadedState) {
            return state;
          }
          return null;
        },
        builder: (BuildContext context, ProfileLoadedState? state) {
          if (state == null) {
            return gap0;
          }

          final profile = state.profile; // Access the selected profile
          final serverClientGUID = profile.serverClientGUID;

          return switch (state) {
            ProfileLoaded() ||
            ProfileFailedSave() ||
            ProfileFailedStart() =>
              IconButton(
                icon: PhosphorIcon(PhosphorIcons.play()),
                onPressed: () {
                  // Cancel any existing subscription to avoid duplicates
                  _blocSubscription?.cancel();

                  // Check if the widget is still mounted and the Bloc is active
                  if (!mounted) return;

                  final profileBloc = context.read<ProfileBloc>();
                  if (profileBloc.isClosed) {
                    debugPrint('ProfileBloc is closed. Cannot add new events.');
                    return;
                  }

                  // Dispatch the start event
                  profileBloc.add(const ProfileStartEvent());

                  // Listen for state changes
                  _blocSubscription = profileBloc.stream.listen(
                    (newState) =>
                        _handleStateChange(newState, serverClientGUID),
                  );
                },
              ),
            ProfileStarting() => const Spinner(),
            ProfileStarted() => IconButton(
                icon: PhosphorIcon(PhosphorIcons.stop()),
                onPressed: () {
                  context.read<ProfileBloc>().add(const ProfileStopEvent());
                },
              ),
            ProfileStopping() => const Spinner(),
          };
        },
      ),
    );
  }
}

class ProfileUpdateService {
  Future<void> updateProfileStatus(
      bool isSuccess, String serverClientGUID) async {
    // Read access data from the file
    final accessDataFile = File(r'C:\ZTN\FILES\accessdata.txt');
    final content = await accessDataFile.readAsString();
    final parts = content.trim().split(' ');

    if (parts.length != 2) {
      throw Exception('Invalid format in accessdata.txt');
    }
    final guid = parts[0];
    final accessToken = parts[1];

    try {
      Map payloadData = {
        "AsClient": [
          {
            "ServerClientGUID": serverClientGUID,
            "Success": isSuccess,
            "Message": isSuccess
                ? "Client successfully started!"
                : "Issue occurred when starting client."
          }
        ],
        "AsServer": [{}]
      };

      final response = await http.post(
        Uri.parse(
            'https://portal.zettahealth.co/ZBMSCareNET360_API/rest/endpoint/conns/v1?action=update&guid=$guid'),
        headers: <String, String>{
          'access_token': decrypt(
              guid.substring(0, 16), crypt.Encrypted.fromBase16(accessToken)),
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: json.encode(payloadData),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to send connection status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  String decrypt(String keyString, crypt.Encrypted encryptedData) {
    final key = crypt.Key.fromUtf8(keyString);
    final encrypter = crypt.Encrypter(crypt.AES(key, mode: crypt.AESMode.cbc));
    final initVector = crypt.IV.fromUtf8(keyString.substring(0, 16));
    return encrypter.decrypt(encryptedData, iv: initVector);
  }
}
