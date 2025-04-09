import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:npt_flutter/app.dart';
//import 'package:npt_flutter/features/favorite/favorite.dart';
import 'package:npt_flutter/features/profile/profile.dart';

part 'profile_list_event.dart';
part 'profile_list_state.dart';

class ProfileListBloc extends LoggingBloc<ProfileListEvent, ProfileListState> {
  final ProfileRepository _repo;
  ProfileListBloc(this._repo) : super(const ProfileListInitial()) {
    on<ProfileListLoadEvent>(_onLoad);
    on<ProfileListUpdateEvent>(_onUpdate);
    on<ProfileListDeleteEvent>(_onDelete);
    on<ProfileListAddEvent>(_onAdd);
  }

  void clearAll() => emit(const ProfileListInitial());

  Future<void> _onLoad(
      ProfileListLoadEvent event, Emitter<ProfileListState> emit) async {
    emit(const ProfileListLoading());

    Iterable<String>? profiles;
    try {
      profiles = await _repo.getProfileUuids();
    } catch (_) {
      profiles = null;
    }

    if (profiles == null) {
      emit(const ProfileListFailedLoad());
      return;
    }

    emit(ProfileListLoaded(profiles: profiles));
  }

  Future<void> _onUpdate(
      ProfileListUpdateEvent event, Emitter<ProfileListState> emit) async {
    emit(ProfileListLoaded(profiles: event.profiles));
  }

  Future<void> _onDelete(
      ProfileListDeleteEvent event, Emitter<ProfileListState> emit) async {
    if (state is! ProfileListLoaded) return;

    final profiles = (state as ProfileListLoaded).profiles;

    for (final profile in profiles) {
      unawaited(_repo.deleteProfile(
          profile)); // or just profile if your method accepts full object
    }

    emit(const ProfileListLoaded(profiles: [])); // Clear the list
  }

  Future<void> _onAdd(
      ProfileListAddEvent event, Emitter<ProfileListState> emit) async {
    // Don't allow async bulk adds unless listed is loaded - this reduces the number of edge cases significantly
    if (state is! ProfileListLoaded) {
      return;
    }

    var profiles = (state as ProfileListLoaded).profiles.toList();
    for (var profile in event.toAdd) {
      App.log('ProfileListAdd  | putProfile($profile)'.loggable);
      unawaited(_repo.putProfile(profile));
      profiles.add(profile.uuid);
    }

    emit(ProfileListLoaded(profiles: profiles));
  }
}
