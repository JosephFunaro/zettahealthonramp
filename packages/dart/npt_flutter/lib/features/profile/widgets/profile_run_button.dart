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
import 'package:uuid/uuid.dart';
import 'package:encrypt/encrypt.dart' as crypt;

class ProfileRunButton extends StatelessWidget {
  const ProfileRunButton({super.key});

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
        builder: (BuildContext context, ProfileLoadedState? state) =>
            switch (state) {
          null => gap0,
          ProfileLoaded() ||
          ProfileFailedSave() ||
          ProfileFailedStart() =>
            IconButton(
              icon: PhosphorIcon(PhosphorIcons.play()),
              onPressed: () {
                context.read<ProfileBloc>().add(const ProfileStartEvent());
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
        },
      ),
    );
  }
}

class ProfileUpdateService {
  Future<void> fetchProfileGuids(String since) async {
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
      // Make the API call
      final getResponse = await http.post(
        Uri.parse(
            'https://imvirtusinc-dev.outsystemsenterprise.com/ZBMSCareNET360_API/rest/endpoint/conns/v1?action=update&guid=$guid'),
        headers: <String, String>{
          'access_token': decrypt(
              guid.substring(0, 16), crypt.Encrypted.fromBase16(accessToken)),
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: '{}',
      );

      if (getResponse.statusCode == 200) {
        // Parse the response to determine success
        final responseBody = jsonDecode(getResponse.body);
        final isSuccess = responseBody['status'] ==
            'success'; // Adjust based on API response structure

        // Send the success or failure status
        await _sendConnectionStatus(guid, isSuccess);
      } else {
        // Handle failure
        await _sendConnectionStatus(guid, false);
        throw Exception(
            'Failed to load connections: ${getResponse.statusCode}');
      }
    } catch (e) {
      // Handle errors and send failure status
      await _sendConnectionStatus(guid, false);
      rethrow;
    }
  }

  Future<void> _sendConnectionStatus(String guid, bool isSuccess) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://imvirtusinc-dev.outsystemsenterprise.com/ZBMSCareNET360_API/rest/endpoint/status/v1'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'guid': guid,
          'status': isSuccess ? 'success' : 'failure',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to send connection status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending connection status: $e');
    }
  }

  String decrypt(String keyString, crypt.Encrypted encryptedData) {
    final key = crypt.Key.fromUtf8(keyString);
    final encrypter = crypt.Encrypter(crypt.AES(key, mode: crypt.AESMode.cbc));
    final initVector = crypt.IV.fromUtf8(keyString.substring(0, 16));
    return encrypter.decrypt(encryptedData, iv: initVector);
  }
}
