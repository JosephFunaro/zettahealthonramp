import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:npt_flutter/features/profile/models/profile.dart';
import 'package:npt_flutter/features/profile/widgets/profile_run_button.dart';
//import 'package:npt_flutter/util/export.dart';
//import 'package:npt_flutter/widgets/multi_select_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
//import 'package:npt_flutter/features/profile/profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:npt_flutter/features/profile_list/bloc/profile_list_bloc.dart';
//import 'package:flutter_bloc/flutter_bloc.dart';
//import '../../../styles/sizes.dart';
import '../cubit/profiles_selected_cubit.dart';
import 'package:uuid/uuid.dart';
import 'package:encrypt/encrypt.dart' as crypt;
import 'package:npt_flutter/features/profile/bloc/profile_bloc.dart';
import 'package:npt_flutter/features/profile/cubit/profile_cache_cubit.dart';

class ProfileListImportButton extends StatefulWidget {
  final TextEditingController textController;
  final VoidCallback onStartRefresh; // Callback to notify when refresh starts
  final VoidCallback onEndRefresh; // Callback to notify when refresh ends

  const ProfileListImportButton({
    super.key,
    required this.textController,
    required this.onStartRefresh,
    required this.onEndRefresh,
  });

  @override
  State<ProfileListImportButton> createState() =>
      _ProfileListImportButtonState();
}

class _ProfileListImportButtonState extends State<ProfileListImportButton> {
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;

    return ElevatedButton.icon(
      onPressed: () async {
        widget.onStartRefresh(); // Notify parent that refresh has started

        // Clear the text field
        widget.textController.clear();

        // Capture dependencies at the start of the callback
        final profileCacheCubit = context.read<ProfileCacheCubit>();
        final profileListBloc = context.read<ProfileListBloc>();

        try {
          // Stop running profiles
          await ProfileImportService()
              .stopRunningProfiles(profileCacheCubit, profileListBloc);

          // Fetch and import new profiles
          final guids = await ProfileImportService().fetchProfileGuids(
            DateTime(1900, 1, 1, 0, 0, 0).toString(),
          );

          // Use context.mounted to ensure the widget is still in the tree
          if (context.mounted) {
            profileListBloc.add(const ProfileListDeleteEvent(toDelete: {}));
            profileListBloc.add(ProfileListAddEvent(guids));
          }
        } catch (e) {
          debugPrint('Error fetching profiles in button: $e');
          // Optionally show a snackbar or error UI
        } finally {
          widget.onEndRefresh(); // Notify parent that refresh has ended
        }
      },
      label: Text(strings.import),
      icon: PhosphorIcon(
        PhosphorIcons.arrowClockwise(),
      ),
    );
  }
}

class AutoProfileFetcher extends StatefulWidget {
  final TextEditingController textController;
  final VoidCallback onStartRefresh; // Callback to notify when refresh starts
  final VoidCallback onEndRefresh; // Callback to notify when refresh ends

  const AutoProfileFetcher({
    super.key,
    required this.textController,
    required this.onStartRefresh,
    required this.onEndRefresh,
  });

  @override
  State<AutoProfileFetcher> createState() => _AutoProfileFetcherState();
}

class _AutoProfileFetcherState extends State<AutoProfileFetcher> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start the timer when the widget is initialized
    _startAutoFetch();
  }

  void _startAutoFetch() async {
    // Capture dependencies at the start of the method
    final profileCacheCubit = context.read<ProfileCacheCubit>();
    final profileListBloc = context.read<ProfileListBloc>();
    final profilesSelectedCubit = context.read<ProfilesSelectedCubit>();

    String since = DateTime(1900, 1, 1, 0, 0, 0).toString();

    // Perform the first refresh immediately
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        widget.onStartRefresh(); // Notify parent that refresh has started
        debugPrint('AUTO FETCH STARTED IMMEDIATELY! TIME: $since');

        // Clear the text field
        widget.textController.clear();

        await ProfileImportService()
            .stopRunningProfiles(profileCacheCubit, profileListBloc);
        await _fetchProfiles(since, profileListBloc, profilesSelectedCubit);
      } catch (e) {
        debugPrint('Error during immediate refresh: $e');
      } finally {
        widget.onEndRefresh(); // Notify parent that refresh has ended
      }
    });

    // Update the "since" timestamp
    since = DateTime.now().toUtc().toString();

    // Start periodic fetching
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      bool isUpdateAvailable =
          await ProfileImportService().checkForUpdate(since);
      debugPrint('AUTO FETCH CHECK FOR UPDATE: $isUpdateAvailable $since');
      if (isUpdateAvailable) {
        widget.onStartRefresh(); // Notify parent that refresh has started
        debugPrint('AUTO FETCH STARTED! TIME: $since');
        try {
          // Clear the text field
          widget.textController.clear();

          await ProfileImportService()
              .stopRunningProfiles(profileCacheCubit, profileListBloc);
          await _fetchProfiles(since, profileListBloc, profilesSelectedCubit);
        } catch (e) {
          debugPrint('Error during automatic refresh: $e');
        } finally {
          widget.onEndRefresh(); // Notify parent that refresh has ended
        }
      }

      // Update the "since" timestamp
      since = DateTime.now().toUtc().toString();
    });
  }

  Future<void> _fetchProfiles(String since, ProfileListBloc profileListBloc,
      ProfilesSelectedCubit profilesSelectedCubit) async {
    try {
      final guids = await ProfileImportService().fetchProfileGuids(since);
      final selected = profilesSelectedCubit.state.selected;

      profileListBloc.add(ProfileListDeleteEvent(toDelete: selected));
      profileListBloc.add(ProfileListAddEvent(guids));
    } catch (e) {
      debugPrint('Error fetching profiles automatically: $e');
    }
  }

  @override
  void dispose() {
    // Cancel timer when widget is disposed
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(); // Or any placeholder UI
  }
}

class ProfileImportService {
  Future<bool> checkForUpdate(String since) async {
    // Read access data from the file
    final accessDataFile = File(r'C:\ZTN\FILES\accessdata.txt');
    final content = await accessDataFile.readAsString();
    final parts = content.trim().split(' ');

    if (parts.length != 2) {
      throw Exception('Invalid format in accessdata.txt');
    }
    final guid = parts[0];
    debugPrint('CALLING CHECK FOR UPDATE: $guid $since');
    final checkResponse = await http.get(
        Uri.parse(
            'https://imvirtusinc-dev.outsystemsenterprise.com/ZBMSCareNET360_API/rest/endpoint/check/v1?guid=$guid&since=$since'),
        headers: <String, String>{'Content-Type': 'text/plain'});
    if (checkResponse.statusCode == 200) {
      dynamic dataBody = jsonDecode(checkResponse.body);
      debugPrint('CHECK FOR UPDATE RESPONSE: $dataBody');
      if (dataBody == 1) {
        return true;
      } else {
        return false;
      }
    } else {
      throw Exception(
          'Failed to check for updates: ${checkResponse.statusCode}');
    }
  }

  Future<List<Profile>> fetchProfileGuids(String since) async {
    // Read access data from the file
    final accessDataFile = File(r'C:\ZTN\FILES\accessdata.txt');
    final content = await accessDataFile.readAsString();
    final parts = content.trim().split(' ');

    if (parts.length != 2) {
      throw Exception('Invalid format in accessdata.txt');
    }
    final guid = parts[0];
    final accessToken = parts[1];
    final getResponse = await http.post(
      Uri.parse(
          'https://imvirtusinc-dev.outsystemsenterprise.com/ZBMSCareNET360_API/rest/endpoint/conns/v1?action=get&guid=$guid'),
      headers: <String, String>{
        'access_token': decrypt(
            guid.substring(0, 16), crypt.Encrypted.fromBase16(accessToken)),
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: '{}',
    );
    if (getResponse.statusCode == 200) {
      final Map<String, dynamic> decoded = jsonDecode(getResponse.body);
      final connections = decoded['Connections'];

      if (connections == null || connections['AsClient'] == null) {
        throw Exception('No connections found');
      }

      final uuids = <Profile>[];
      final List<dynamic> clients = connections['AsClient'];
      final String startUpOption = decoded['Endpoint']['StartUpOption'];

      for (var entry in clients) {
        final newProfile = Profile(const Uuid().v4(),
            displayName: entry["ServiceName"],
            relayAtsign: "@rv_am",
            sshnpdAtsign: entry["ServerDataKey"],
            deviceName: entry["ServiceDeviceName"],
            friendlyName: entry["ServerEndpointFriendlyName"],
            startUpOption: startUpOption,
            remotePort: entry["ServicePort"],
            localPort: entry["ClientPort"],
            serverClientGUID: entry["ServerClientGUID"]);
        uuids.add(newProfile);
      }
      return uuids;
    } else {
      throw Exception('Failed to load connections: ${getResponse.statusCode}');
    }
  }

  Future<void> stopRunningProfiles(ProfileCacheCubit profileCacheCubit,
      ProfileListBloc profileListBloc) async {
    try {
      // Clear the payload data list
      ProfileUpdateService().clearPayloadData();

      // Read access data from the file
      final accessDataFile = File(r'C:\ZTN\FILES\accessdata.txt');
      final content = await accessDataFile.readAsString();
      final parts = content.trim().split(' ');

      if (parts.length != 2) {
        throw Exception('Invalid format in accessdata.txt');
      }
      final guid = parts[0];
      final accessToken = parts[1];

      if (profileListBloc.state is! ProfileListLoaded) return;

      final profiles = (profileListBloc.state as ProfileListLoaded).profiles;

      // Prepare the AsClient list for the payload
      final List<Map<String, dynamic>> asClientList = [];

      for (final uuid in profiles) {
        final profileBloc = profileCacheCubit.getProfileBloc(uuid);

        // Check the state of the ProfileBloc to retrieve the Profile object
        if (profileBloc.state is ProfileLoadedState) {
          final profile = (profileBloc.state as ProfileLoadedState).profile;

          // Get the serverClientGUID from the Profile object
          final serverClientGUID = profile.serverClientGUID;

          // Add the serverClientGUID to the AsClient list
          asClientList.add({
            "ServerClientGUID": serverClientGUID,
          });

          // Check if the profile is in the starting state
          if (profileBloc.state is ProfileStarting) {
            debugPrint(
                "$uuid is in the starting state. Waiting for it to start...");
            await Future.doWhile(() async {
              await Future.delayed(const Duration(seconds: 1));
              return profileBloc.state is ProfileStarting;
            });
            debugPrint("$uuid has transitioned out of the starting state.");
          }

          if (profileBloc.state is ProfileStarted) {
            profileBloc.add(const ProfileStopEvent());
            debugPrint("$uuid is being stopped!");
          } else {
            debugPrint(
                "$uuid is not running. Current state: ${profileBloc.state}");
          }
        } else {
          debugPrint("Profile not found or not loaded for UUID: $uuid");
        }
      }

      // Prepare the payload data
      Map payloadData = {
        "AsClient": asClientList,
        "AsServer": [{}]
      };

      final response = await http.post(
        Uri.parse(
            'https://imvirtusinc-dev.outsystemsenterprise.com/ZBMSCareNET360_API/rest/endpoint/conns/v1?action=update&guid=$guid'),
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
      debugPrint('Error stopping running profiles: $e');
    }
  }

  String decrypt(String keyString, crypt.Encrypted encryptedData) {
    final key = crypt.Key.fromUtf8(keyString);
    final encrypter = crypt.Encrypter(crypt.AES(key, mode: crypt.AESMode.cbc));
    final initVector = crypt.IV.fromUtf8(keyString.substring(0, 16));
    return encrypter.decrypt(encryptedData, iv: initVector);
  }
}
