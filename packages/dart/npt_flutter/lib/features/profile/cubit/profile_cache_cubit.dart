import 'package:npt_flutter/app.dart';
import 'package:npt_flutter/features/profile/profile.dart';

part 'profile_cache_state.dart';

class ProfileCacheCubit extends LoggingCubit<ProfileCacheState> {
  final ProfileRepository _repo;
  ProfileCacheCubit(this._repo) : super(const ProfileCacheState({}));

  ProfileBloc getProfileBloc(String uuid) {
    if (state.profileBlocs.containsKey(uuid)) {
      return state.profileBlocs[uuid]!;
    }

    var bloc = ProfileBloc(_repo, uuid);
    emit(state.withAdded(uuid, bloc));
    return bloc;
  }

  void disposeProfileBloc(String uuid) {
    if (state.profileBlocs.containsKey(uuid)) {
      state.profileBlocs[uuid]?.close(); // Dispose of the ProfileBloc
      emit(state.withRemoved(uuid)); // Remove it from the state
    }
  }

  void disposeProfileBlocs(List<String> uuids) {
    for (var uuid in uuids) {
      disposeProfileBloc(uuid); // Reuse the existing method to dispose of each bloc
    }
  }

  void clear() {
    for (var bloc in state.profileBlocs.values) {
      bloc.close(); // Dispose of all ProfileBloc instances
    }
    emit(const ProfileCacheState({}));
  }
}

