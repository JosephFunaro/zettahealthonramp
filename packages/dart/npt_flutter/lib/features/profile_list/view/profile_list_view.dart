import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:npt_flutter/app.dart';
import 'package:npt_flutter/features/back_up_key/cubit/backup_key_cubit.dart';
import 'package:npt_flutter/features/back_up_key/widgets/backup_key_alert_dialog.dart';
import 'package:npt_flutter/features/profile/profile.dart';
import 'package:npt_flutter/features/profile/view/profile_header_view.dart';
import 'package:npt_flutter/features/profile_list/profile_list.dart';
import 'package:npt_flutter/features/profile_list/widgets/profile_list_failed_load_content.dart';
import 'package:npt_flutter/styles/sizes.dart';
import 'package:npt_flutter/widgets/spinner.dart';
import '../../../widgets/custom_card.dart';
import '../cubit/sync_cubit.dart';

class ProfileListView extends StatefulWidget {
  const ProfileListView({super.key});

  @override
  State<ProfileListView> createState() => _ProfileListViewState();
}

class _ProfileListViewState extends State<ProfileListView> {
  final TextEditingController _searchController = TextEditingController();
  bool _isRefreshing = false; // Add a state variable to track refreshing status

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final shouldBackupKey = await App.navState.currentContext!
          .read<BackupKeyCubit>()
          .getBackupKeyStatus();

      if (shouldBackupKey == false && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.2),
          builder: (context) => const BackupKeyAlertDialog(),
        );
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final deviceSize = MediaQuery.of(context).size;
    final bodyMedium = Theme.of(context).textTheme.bodyMedium;
    SizeConfig().init();

    return Stack(
      children: [
        BlocBuilder<ProfileListBloc, ProfileListState>(
          builder: (context, state) {
            return switch (state) {
              ProfileListInitial() ||
              ProfileListLoading() =>
                const Center(child: Spinner()),
              ProfileListFailedLoad() => const ProfileListFailedLoadContent(),
              ProfileListLoaded() =>
                BlocBuilder<ProfileListBloc, ProfileListState>(
                    builder: (BuildContext context, ProfileListState state) {
                  if (state is! ProfileListLoaded) {
                    return gap0;
                  }

                  final profiles = state.profiles.toList();
                  final isFullProfile = profiles.isNotEmpty;

                  return Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            CustomCard.dashboardContent(
                              height: deviceSize.height *
                                  Sizes.dashboardCardHeightFactor,
                              width: SizeConfig.setDashboardWidth(),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  isFullProfile
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: TextField(
                                                controller: _searchController,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      strings.searchProfiles,
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                  ),
                                                  prefixIcon:
                                                      const Icon(Icons.search),
                                                ),
                                                onChanged: (value) {
                                                  context
                                                      .read<ProfileListBloc>()
                                                      .add(
                                                          ProfileListFilterEvent(
                                                              filterText:
                                                                  value));
                                                },
                                              ),
                                            ),
                                            gapW10,
                                            ProfileListImportButton(
                                              textController: _searchController,
                                              onStartRefresh: () {
                                                setState(() {
                                                  _isRefreshing = true;
                                                });
                                              },
                                              onEndRefresh: () {
                                                setState(() {
                                                  _isRefreshing = false;
                                                });
                                              },
                                            ),
                                            AutoProfileFetcher(
                                              textController: _searchController,
                                              onStartRefresh: () {
                                                setState(() {
                                                  _isRefreshing = true;
                                                });
                                              },
                                              onEndRefresh: () {
                                                setState(() {
                                                  _isRefreshing = false;
                                                });
                                              },
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: TextField(
                                                controller: _searchController,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      strings.searchProfiles,
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                  ),
                                                  prefixIcon:
                                                      const Icon(Icons.search),
                                                ),
                                                onChanged: (value) {
                                                  context
                                                      .read<ProfileListBloc>()
                                                      .add(
                                                          ProfileListFilterEvent(
                                                              filterText:
                                                                  value));
                                                },
                                              ),
                                            ),
                                            gapW10,
                                            ProfileListImportButton(
                                              textController: _searchController,
                                              onStartRefresh: () {
                                                setState(() {
                                                  _isRefreshing = true;
                                                });
                                              },
                                              onEndRefresh: () {
                                                setState(() {
                                                  _isRefreshing = false;
                                                });
                                              },
                                            ),
                                            AutoProfileFetcher(
                                              textController: _searchController,
                                              onStartRefresh: () {
                                                setState(() {
                                                  _isRefreshing = true;
                                                });
                                              },
                                              onEndRefresh: () {
                                                setState(() {
                                                  _isRefreshing = false;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                  gapH25,
                                  isFullProfile
                                      ? const ProfileHeaderView()
                                      : gap0,
                                  isFullProfile
                                      ? Expanded(
                                          child: ListView.builder(
                                            addAutomaticKeepAlives: false,
                                            addRepaintBoundaries: false,
                                            itemCount: state.profiles.length,
                                            itemBuilder: (context, index) {
                                              final cacheCubit = context
                                                  .read<ProfileCacheCubit>();
                                              final profileBloc =
                                                  cacheCubit.getProfileBloc(
                                                      profiles[index]);

                                              return CustomCard.profile(
                                                child: BlocProvider.value(
                                                  value: profileBloc,
                                                  child: const ProfileView(),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Align(
                                              alignment: Alignment.center,
                                              child: SvgPicture.asset(
                                                  'assets/empty_state_profile_bg.svg'),
                                            ),
                                            Align(
                                              alignment: Alignment.bottomCenter,
                                              child: Text(
                                                strings.emptyProfileMessage,
                                                style: bodyMedium?.copyWith(
                                                    fontSize: Sizes.p16),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                  BlocBuilder<SyncCubit, bool>(
                                      buildWhen: (previous, current) {
                                    return previous != current;
                                  }, builder: (context, state) {
                                    if (state is ProfileListLoading) {
                                      return Column(
                                        children: [
                                          isFullProfile ? gapH25 : gap0,
                                          Text(
                                            strings.syncInProgress,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      );
                                    }
                                    return gap0;
                                  }),
                                  gapH25,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
            };
          },
        ),
        if (_isRefreshing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      "Refreshing Profiles... Please wait...",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
