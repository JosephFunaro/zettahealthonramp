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
                final guids = await ProfileImportService().fetchProfileGuids();
                if (context.mounted) {
                  context
                      .read<ProfileListBloc>()
                      .add(ProfileListImported(guids));
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

class ProfileImportService {
  Future<List<Profile>> fetchProfileGuids() async {
    final response = await http.post(
        Uri.parse(
            'https://imvirtusinc-dev.outsystemsenterprise.com/ZBMSCareNET360_API/rest/endpoint/conns/v1?action=get&guid=7718465f-82c9-4059-baa4-dae130936c21'),
        headers: <String, String>{
          'access_token': 'zBsVgULhpFyt6AUaKuZsRm8CdyLAyBM8',
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: '{}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = jsonDecode(response.body);

      final connections = decoded['Connections'];
      if (connections == null ||
          connections['AsClient'] == null ||
          connections['AsServer'] == null) {
        throw Exception('No connections found');
      }
      final uuids = <Profile>[];
      final List<dynamic> clients = connections['AsClient'];
      for (var entry in clients) {
        final newProfile = Profile(const Uuid().v4(),
            displayName: entry["ServiceName"],
            relayAtsign: "@rv_am",
            sshnpdAtsign: entry["ServerDataKey"],
            deviceName: entry["ServiceDeviceName"],
            friendlyName: entry["ServerEndpointFriendlyName"],
            remotePort: entry["ServicePort"],
            localPort: entry["ClientPort"]);
        uuids.add(newProfile);
      }
      return uuids;
    } else {
      throw Exception('Failed to load connections');
    }
  }
}
