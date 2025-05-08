import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:npt_flutter/features/profile/profile.dart';
import 'dart:convert';
import 'package:npt_flutter/features/profile_list/bloc/profile_list_bloc.dart';
import '../cubit/profiles_selected_cubit.dart';
import 'package:uuid/uuid.dart';
import 'package:encrypt/encrypt.dart' as crypt;

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
        final autoFetcherState =
            context.findAncestorStateOfType<_AutoProfileFetcherState>();

        try {
          // Fetch new profiles
          final newProfiles = await ProfileImportService().fetchProfileGuids(
            DateTime(1900, 1, 1, 0, 0, 0).toString(),
          );

          // Sync profiles
          await ProfileImportService()
              .syncProfiles(newProfiles, profileCacheCubit, profileListBloc);

          // Update the "since" variable in the automatic fetcher
          if (autoFetcherState != null) {
            autoFetcherState.updateSince(DateTime.now().toUtc().toString());
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
  String since = DateTime(1900, 1, 1, 0, 0, 0).toString();

  @override
  void initState() {
    super.initState();
    // Start the timer when the widget is initialized
    _startAutoFetch();
  }

  void _startAutoFetch() async {
    // Capture dependencies at the start of the method
    context.read<ProfileCacheCubit>();
    final profileListBloc = context.read<ProfileListBloc>();
    final profilesSelectedCubit = context.read<ProfilesSelectedCubit>();

    // Perform the first refresh immediately
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        widget.onStartRefresh(); // Notify parent that refresh has started
        debugPrint('AUTO FETCH STARTED IMMEDIATELY! TIME: $since');

        // Clear the text field
        widget.textController.clear();

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
    final profileCacheCubit = context.read<ProfileCacheCubit>();

    try {
      // Fetch new profiles
      final newProfiles = await ProfileImportService().fetchProfileGuids(since);

      // Sync profiles
      await ProfileImportService()
          .syncProfiles(newProfiles, profileCacheCubit, profileListBloc);
    } catch (e) {
      debugPrint('Error fetching profiles automatically: $e');
    }
  }

  void updateSince(String newSince) {
    since = newSince;
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
    final accessToken = parts[1];
    final accessTokenDecrypt =
        decrypt(guid.substring(0, 16), crypt.Encrypted.fromBase16(accessToken));
    debugPrint('CALLING CHECK FOR UPDATE: $guid $since');
    await httpCall(
        "check;$guid;$since;$accessTokenDecrypt", Connections.empty());
    if (updateResponse[0] == "true") {
      return true;
    } else {
      return false;
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
    final accessTokenDecrypt =
        decrypt(guid.substring(0, 16), crypt.Encrypted.fromBase16(accessToken));
    await httpCall("get;$guid;0;$accessTokenDecrypt", Connections.empty());
    // check if the data key name is not null, or if it matches the one already
    // saved
    if (responseBody == "ERROR" || responseBody == null) {
      throw "ERROR: Did not receive a message to update policy ports.";
    }
    responseBody = json.decode(responseBody);

    dynamic clientSideData = responseBody["Connections"]["AsClient"];

    final uuids = <Profile>[];
    final String startUpOption = responseBody['Endpoint']['StartUpOption'];

    for (var entry in clientSideData) {
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
  }

  String decrypt(String keyString, crypt.Encrypted encryptedData) {
    final key = crypt.Key.fromUtf8(keyString);
    final encrypter = crypt.Encrypter(crypt.AES(key, mode: crypt.AESMode.cbc));
    final initVector = crypt.IV.fromUtf8(keyString.substring(0, 16));
    return encrypter.decrypt(encryptedData, iv: initVector);
  }

  Future<void> syncProfiles(
      List<Profile> newProfiles,
      ProfileCacheCubit profileCacheCubit,
      ProfileListBloc profileListBloc) async {
    debugPrint("Starting syncProfiles...");

    if (profileListBloc.state is! ProfileListLoaded) {
      debugPrint(
          "ProfileListBloc state is not ProfileListLoaded. Exiting syncProfiles.");
      return;
    }

    // Retrieve the list of existing profile UUIDs
    final existingProfileUUIDs =
        (profileListBloc.state as ProfileListLoaded).profiles;
    debugPrint("Existing profile UUIDs: $existingProfileUUIDs");

    // Retrieve the actual Profile objects for the existing UUIDs
    final existingProfiles = existingProfileUUIDs
        .map((uuid) {
          final profileBloc = profileCacheCubit.getProfileBloc(uuid);
          if (profileBloc.state is ProfileLoadedState) {
            debugPrint("Loaded profile for UUID: $uuid");
            return (profileBloc.state as ProfileLoadedState).profile;
          }
          debugPrint("Profile for UUID $uuid is not in ProfileLoadedState.");
          return null;
        })
        .whereType<Profile>() // Filter out null values
        .toList();
    debugPrint("Existing profiles: $existingProfiles");

    // Prepare lists for profiles to add and delete
    final List<Profile> profilesToAdd = [];
    final List<Profile> profilesToKeep = [];
    final List<Profile> profilesToDelete = [];

    // Step 1: Compare new profiles with existing profiles
    for (final newProfile in newProfiles) {
      final matchingProfile = existingProfiles.firstWhere(
          (existingProfile) =>
              _areProfilesEqualIgnoringGUID(newProfile, existingProfile),
          orElse: () => Profile.empty());

      if (matchingProfile.isNotEmpty) {
        debugPrint(
            "Duplicate profile found: ${newProfile.serverClientGUID}. Skipping.");
        profilesToKeep.add(matchingProfile); // Keep the existing profile
        continue; // Do nothing for duplicates
      }

      // If not a duplicate, add to the list of profiles to add
      debugPrint("New profile to add: ${newProfile.serverClientGUID}");
      profilesToAdd.add(newProfile);
    }

    // Step 2: Compare existing profiles with new profiles
    for (final existingProfile in existingProfiles) {
      final isInNewList = newProfiles.any((newProfile) =>
          _areProfilesEqualIgnoringGUID(newProfile, existingProfile));

      if (!isInNewList) {
        debugPrint("Profile to delete: ${existingProfile.serverClientGUID}");
        profilesToDelete.add(existingProfile);
      } else {
        profilesToKeep.add(existingProfile); // Mark as a profile to keep
      }
    }

    // Step 3: Delete profiles that are no longer in the new list
    for (final profileToDelete in profilesToDelete) {
      final profileBloc =
          profileCacheCubit.getProfileBloc(profileToDelete.uuid);

      if (profileBloc.state is ProfileStarted) {
        debugPrint("Stopping profile: ${profileToDelete.uuid}");
        profileBloc.add(const ProfileStopEvent());
      }

      debugPrint("Deleting profile: ${profileToDelete.uuid}");
      profileListBloc.add(ProfileListDeleteEvent(toDelete: {
        profileToDelete.uuid,
      }));

      // Remove the corresponding entry from the payload data list
      final profileUpdateService = ProfileUpdateService();
      profileUpdateService.removePayloadData(profileToDelete.serverClientGUID);

      // Send an update API call with the updated payload data
      try {
        await profileUpdateService.sendUpdatedPayload();
        debugPrint(
            "Successfully sent updated payload after deleting profile: ${profileToDelete.serverClientGUID}");
      } catch (e) {
        debugPrint("Error sending updated payload after deleting profile: $e");
      }
    }

    // Step 4: Add new profiles to the list
    if (profilesToAdd.isNotEmpty) {
      debugPrint(
          "Adding new profiles: ${profilesToAdd.map((p) => p.serverClientGUID).toList()}");
      profileListBloc.add(ProfileListAddEvent(profilesToAdd));
    }

    // Step 5: Ensure the state is updated with a deduplicated list of profiles
    // ignore: prefer_collection_literals
    final updatedProfiles = [
      ...profilesToKeep,
      ...profilesToAdd,
    ].toSet().toList(); // Deduplicate the list
    debugPrint(
        "Final profile list: ${updatedProfiles.map((p) => p.serverClientGUID).toList()}");
    profileListBloc.add(ProfileListUpdateEvent(
        updatedProfiles.map((profile) => profile.uuid).toList()));

    debugPrint("syncProfiles completed.");
  }

  bool _areProfilesEqualIgnoringGUID(Profile p1, Profile p2) {
    final isEqual = p1.displayName == p2.displayName &&
        p1.relayAtsign == p2.relayAtsign &&
        p1.sshnpdAtsign == p2.sshnpdAtsign &&
        p1.deviceName == p2.deviceName &&
        p1.friendlyName == p2.friendlyName &&
        p1.startUpOption == p2.startUpOption &&
        p1.remotePort == p2.remotePort &&
        p1.localPort == p2.localPort;

    debugPrint(
        "Comparing profiles (ignoring GUID):\nProfile 1: $p1\nProfile 2: $p2\nAre equal: $isEqual");
    return isEqual;
  }
}
