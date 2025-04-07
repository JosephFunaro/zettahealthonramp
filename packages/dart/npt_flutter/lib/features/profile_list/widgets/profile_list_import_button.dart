import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import 'package:npt_flutter/util/export.dart';
//import 'package:npt_flutter/widgets/multi_select_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:npt_flutter/features/profile/profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:npt_flutter/features/profile_list/bloc/profile_list_bloc.dart';

import '../../../styles/sizes.dart';
import '../cubit/profiles_selected_cubit.dart';

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
  Future<List<String>> fetchProfileGuids() async {
    final response = await http.post(
        Uri.parse(
            'https://imvirtusinc-dev.outsystemsenterprise.com/ZBMSCareNET360_API/rest/endpoint/conns/v1?action=get&guid=d5e77876-d228-451f-a56c-4b989a85e9dc'),
        headers: <String, String>{
          'access_token': 'UXpLxesd8KchkD5CYkKwUf97v7Ip1KCA',
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: '{}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = jsonDecode(response.body);

      final connections = decoded['Connections'];
      if (connections == null || connections['AsClient'] == null) {
        throw Exception('No AsClient connections found');
      }

      final List<dynamic> clients = connections['AsClient'];
      final List<String> guids = clients
          .map((client) => client['ServerClientGUID']?.toString())
          .where((guid) => guid != null && guid.isNotEmpty)
          .cast<String>()
          .toList();

      return guids;
    } else {
      throw Exception('Failed to load connections');
    }
  }
}
