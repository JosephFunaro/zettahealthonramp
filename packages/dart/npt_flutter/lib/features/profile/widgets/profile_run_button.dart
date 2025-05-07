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

    final profileUpdateService = ProfileUpdateService();

    try {
      if (newState is ProfileStarted) {
        // Profile successfully started
        await _updateConnectionStatus(true, serverClientGUID);
        debugPrint("Profile started successfully for GUID: $serverClientGUID");
      } else if (newState is ProfileFailedStart) {
        // Profile failed to start
        await _updateConnectionStatus(false, serverClientGUID);
        debugPrint("Profile failed to start for GUID: $serverClientGUID");
      }

      // Send the updated payload data to the API
      await profileUpdateService.sendUpdatedPayload();
      debugPrint(
          "Updated payload sent after state change for GUID: $serverClientGUID");
    } catch (e) {
      debugPrint("Error handling state change for GUID $serverClientGUID: $e");
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
  static final List<Map<String, dynamic>> _payloadDataList = [];

  // Method to clear the payload data list
  void clearPayloadData() {
    _payloadDataList.clear();
    debugPrint("Payload data list cleared.");
  }

  // Method to remove the Message and Success variables from an entry
  void removePayloadData(String serverClientGUID) {
    final entry = _payloadDataList.firstWhere(
      (entry) => entry['ServerClientGUID'] == serverClientGUID,
      orElse: () => <String, dynamic>{}, // Return an empty map instead of null
    );

    if (entry.isNotEmpty) {
      // Check if the entry is not empty
      entry.remove('Message');
      entry.remove('Success');
      debugPrint("Removed 'Message' and 'Success' for GUID: $serverClientGUID");
    } else {
      debugPrint("No entry found for GUID: $serverClientGUID");
    }
  }

  // Method to send the updated payload data to the API
  Future<void> sendUpdatedPayload() async {
    // Read access data from the file
    final accessDataFile = File(r'C:\ZTN\FILES\accessdata.txt');
    final content = await accessDataFile.readAsString();
    final parts = content.trim().split(' ');

    if (parts.length != 2) {
      throw Exception('Invalid format in accessdata.txt');
    }
    final guid = parts[0];
    final accessToken = parts[1];

    // Prepare the payload data
    Map payloadData = {
      "AsClient": _payloadDataList,
      "AsServer": [{}]
    };

    // Send the updated payload data to the API
    final response = await http.post(
      Uri.parse(
          'https://imvirtusinc-dev.outsystemsenterprise.com//ZBMSCareNET360_API/rest/endpoint/conns/v1?action=update&guid=$guid'),
      headers: <String, String>{
        'access_token': decrypt(
            guid.substring(0, 16), crypt.Encrypted.fromBase16(accessToken)),
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: json.encode(payloadData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send updated payload: ${response.statusCode}');
    }

    debugPrint("Updated payload sent successfully: $payloadData");
  }

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
      // Check if the ServerClientGUID already exists in the list
      final existingEntry = _payloadDataList.firstWhere(
        (entry) => entry['ServerClientGUID'] == serverClientGUID,
        orElse: () => {},
      );

      if (existingEntry.isNotEmpty) {
        // Update the existing entry
        existingEntry['Success'] = isSuccess;
        existingEntry['Message'] = isSuccess
            ? "Client successfully started!"
            : "Issue occurred when starting client.";
      } else {
        // Add a new entry
        _payloadDataList.add({
          "ServerClientGUID": serverClientGUID,
          "Success": isSuccess,
          "Message": isSuccess
              ? "Client successfully started!"
              : "Issue occurred when starting client."
        });
      }

      // Prepare the payload data
      Map payloadData = {
        "AsClient": _payloadDataList,
        "AsServer": [{}]
      };

      final response = await http.post(
        Uri.parse(
            'https://imvirtusinc-dev.outsystemsenterprise.com//ZBMSCareNET360_API/rest/endpoint/conns/v1?action=update&guid=$guid'),
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
