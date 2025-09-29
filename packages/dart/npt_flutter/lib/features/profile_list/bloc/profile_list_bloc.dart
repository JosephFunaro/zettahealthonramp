import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:npt_flutter/app.dart';
//import 'package:npt_flutter/features/favorite/favorite.dart';
import 'package:npt_flutter/features/profile/profile.dart';

part 'profile_list_event.dart';
part 'profile_list_state.dart';

class ProfileListBloc extends LoggingBloc<ProfileListEvent, ProfileListState> {
  final ProfileRepository _repo;
  final List<Profile> _allProfiles = []; // Store all profiles here

  ProfileListBloc(this._repo) : super(const ProfileListInitial()) {
    on<ProfileListLoadEvent>(_onLoad);
    on<ProfileListUpdateEvent>(_onUpdate);
    on<ProfileListDeleteEvent>(_onDelete);
    on<ProfileListAddEvent>(_onAdd);
    on<ProfileListFilterEvent>(_onFilter);
  }

  void clearAll() => emit(const ProfileListInitial());

  Future<void> _onLoad(
    ProfileListLoadEvent event,
    Emitter<ProfileListState> emit,
  ) async {
    emit(const ProfileListLoading());

    // Fetch the full profile objects
    final profileList = await _fetchProfiles();

    _allProfiles.clear();
    _allProfiles.addAll(profileList);

    // Emit the loaded state with all profiles
    emit(
      ProfileListLoaded(profiles: _allProfiles.map((profile) => profile.uuid)),
    );
  }

  Future<void> _onUpdate(
    ProfileListUpdateEvent event,
    Emitter<ProfileListState> emit,
  ) async {
    emit(ProfileListLoaded(profiles: event.profiles));
  }

  Future<void> _onDelete(
    ProfileListDeleteEvent event,
    Emitter<ProfileListState> emit,
  ) async {
    if (state is! ProfileListLoaded) return;
    final profiles = (state as ProfileListLoaded).profiles;

    for (final profile in profiles) {
      unawaited(
        _repo.deleteProfile(profile),
      ); // or just profile if your method accepts full object
    }

    emit(const ProfileListLoaded(profiles: [])); // Clear the list
  }

  Future<void> _onAdd(
    ProfileListAddEvent event,
    Emitter<ProfileListState> emit,
  ) async {
    // Clear the existing profiles
    _allProfiles.clear();

    // Add the new profiles to the repository and _allProfiles
    for (var profile in event.toAdd) {
      App.log('ProfileListAdd  | putProfile($profile)'.loggable);
      unawaited(_repo.putProfile(profile));
      _allProfiles.add(profile);
    }

    // Emit the updated state with all profiles
    emit(
      ProfileListLoaded(profiles: _allProfiles.map((profile) => profile.uuid)),
    );
  }

  void _onFilter(ProfileListFilterEvent event, Emitter<ProfileListState> emit) {
    final filterText = event.filterText.toLowerCase();

    // If the filter text is empty, show all profiles
    if (filterText.isEmpty) {
      emit(
        ProfileListLoaded(
          profiles: _allProfiles.map((profile) => profile.uuid),
        ),
      );
      return;
    }

    // Filter profiles based on friendlyName or displayName
    final filteredProfiles = _allProfiles.where((profile) {
      return profile.friendlyName.toLowerCase().contains(filterText) ||
          profile.displayName.toLowerCase().contains(filterText);
    }).toList();

    emit(
      ProfileListLoaded(
        profiles: filteredProfiles.map((profile) => profile.uuid),
      ),
    );
  }

  Future<List<Profile>> _fetchProfiles() async {
    try {
      // Fetch the UUIDs of all profiles
      final profileUuids = await _repo.getProfileUuids();

      if (profileUuids == null) {
        debugPrint('No profile UUIDs found.');
        return [];
      }

      // Fetch the full profile objects using the UUIDs
      final profiles = await _repo.getProfiles(profileUuids);

      return profiles.toList();
    } catch (e) {
      debugPrint('Error fetching profiles: $e');
      return [];
    }
  }
}
