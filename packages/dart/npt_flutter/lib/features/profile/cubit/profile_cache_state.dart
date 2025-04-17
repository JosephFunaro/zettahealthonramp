part of 'profile_cache_cubit.dart';

class ProfileCacheState extends Loggable {
  final Map<String, ProfileBloc> profileBlocs;
  const ProfileCacheState(this.profileBlocs);

  ProfileCacheState withAdded(String uuid, ProfileBloc bloc) {
    return ProfileCacheState({...profileBlocs, uuid: bloc});
  }

  ProfileCacheState withRemoved(String uuid) {
    final updatedBlocs = Map<String, ProfileBloc>.from(profileBlocs);
    updatedBlocs.remove(uuid);
    return ProfileCacheState(updatedBlocs);
  }

  @override
  List<Object> get props => [profileBlocs];

  @override
  String toString() {
    return 'ProfileCacheState(uuids:${profileBlocs.keys})';
  }
}
