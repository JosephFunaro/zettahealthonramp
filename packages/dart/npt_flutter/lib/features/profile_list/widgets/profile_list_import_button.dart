import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:npt_flutter/features/profile/models/profile.dart';
//import 'package:npt_flutter/util/export.dart';
//import 'package:npt_flutter/widgets/multi_select_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
//import 'package:npt_flutter/features/profile/profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:npt_flutter/features/profile_list/bloc/profile_list_bloc.dart';
//import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../styles/sizes.dart';
import '../cubit/profiles_selected_cubit.dart';
import 'package:uuid/uuid.dart';
import 'package:encrypt/encrypt.dart' as crypt;

class ProfileListImportButton extends StatelessWidget {
  const ProfileListImportButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return BlocSelector<ProfilesSelectedCubit, ProfilesSelectedState,
            Set<String>>(
        selector: (state) => state.selected,
        builder: (BuildContext context, Set<String> selected) {
          // Hide this button if something is selected
          if (selected.isNotEmpty) return gap0;
          return ElevatedButton.icon(
            onPressed: () async {
              try {
                final guids = await ProfileImportService().fetchProfileGuids(
                    DateTime(1900, 1, 1, 0, 0, 0).toString());
                if (context.mounted) {
                  context
                      .read<ProfileListBloc>()
                      .add(ProfileListDeleteEvent(toDelete: selected));
                  context
                      .read<ProfileListBloc>()
                      .add(ProfileListAddEvent(guids));
                }
              } catch (e) {
                debugPrint('Error fetching profiles: $e');
                // Optionally show a snackbar or error UI
              }
            },
            label: Text(strings.import),
            icon: PhosphorIcon(
              PhosphorIcons.downloadSimple(),
            ),
          );
        });
  }
}

class AutoProfileFetcher extends StatefulWidget {
  const AutoProfileFetcher({super.key});

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

  void _startAutoFetch() {
    String since = DateTime(1900, 1, 1, 0, 0, 0).toString();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        final guids = await ProfileImportService().fetchProfileGuids(since);
        since = DateTime.now().toUtc().toString(); // Update the since variable
        if (!mounted) return; // This checks the actual State context
        final selected = context.read<ProfilesSelectedCubit>().state.selected;
        context
            .read<ProfileListBloc>()
            .add(ProfileListDeleteEvent(toDelete: selected));
        context.read<ProfileListBloc>().add(ProfileListAddEvent(guids));
      } catch (e) {
        debugPrint('Error fetching profiles: $e');
      }
    });
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
    final checkResponse = await http.get(
        Uri.parse(
            'https://imvirtusinc-dev.outsystemsenterprise.com/ZBMSCareNET360_API/rest/endpoint/check/v1?guid=$guid&since=$since'),
        headers: <String, String>{'Content-Type': 'text/plain'});
    if (checkResponse.statusCode == 200) {
      dynamic dataBody = jsonDecode(checkResponse.body);
      if (dataBody == 1) {
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
          throw Exception(
              'Failed to load connections: ${getResponse.statusCode}');
        }
      } else {
        throw Exception('No new updates found since $since');
      }
    } else {
      throw Exception(
          'Failed to load connections: ${checkResponse.statusCode}');
    }
  }

  String decrypt(String keyString, crypt.Encrypted encryptedData) {
    final key = crypt.Key.fromUtf8(keyString);
    final encrypter = crypt.Encrypter(crypt.AES(key, mode: crypt.AESMode.cbc));
    final initVector = crypt.IV.fromUtf8(keyString.substring(0, 16));
    return encrypter.decrypt(encryptedData, iv: initVector);
  }
}
