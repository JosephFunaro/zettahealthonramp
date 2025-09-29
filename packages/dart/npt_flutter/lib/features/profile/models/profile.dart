import 'package:json_annotation/json_annotation.dart';
import 'package:noports_core/sshnp.dart';
import 'package:npt_flutter/app.dart';
import 'package:npt_flutter/features/favorite/favorite.dart';
import 'package:npt_flutter/util/uuid.dart';

part 'profile.g.dart';

@JsonSerializable()
final class Profile extends Loggable with Favoritable {
  // Manually handle the json for uuid since we only sometimes want it
  @JsonKey(defaultValue: '', includeToJson: false)
  final String uuid;
  final String displayName;
  final String? relayAtsign;
  final String sshnpdAtsign;
  final String deviceName;
  final String friendlyName;
  final String startUpOption;
  final String remoteHost;
  final int remotePort;
  final int localPort;
  final String serverClientGUID;

  const Profile(
    this.uuid, {
    required this.displayName,
    this.relayAtsign,
    required this.sshnpdAtsign,
    required this.deviceName,
    required this.friendlyName,
    required this.startUpOption,
    this.remoteHost = 'localhost',
    required this.remotePort,
    required this.localPort,
    required this.serverClientGUID,
  });

  Profile copyWith({
    String? uuid,
    String? displayName,
    String? relayAtsign,
    String? sshnpdAtsign,
    String? deviceName,
    String? friendlyName,
    String? startUpOption,
    String? remoteHost,
    int? remotePort,
    int? localPort,
    String? serverClientGUID,
  }) {
    return Profile(
      uuid ?? this.uuid,
      displayName: displayName ?? this.displayName,
      relayAtsign: relayAtsign ?? this.relayAtsign,
      sshnpdAtsign: sshnpdAtsign ?? this.sshnpdAtsign,
      deviceName: deviceName ?? this.deviceName,
      friendlyName: friendlyName ?? this.friendlyName,
      startUpOption: startUpOption ?? this.startUpOption,
      remoteHost: remoteHost ?? this.remoteHost,
      remotePort: remotePort ?? this.remotePort,
      localPort: localPort ?? this.localPort,
      serverClientGUID: serverClientGUID ?? this.serverClientGUID,
    );
  }

  /// Json but without the uuid
  Map<String, dynamic> toExportableJson() => _$ProfileToJson(this);

  Map<String, dynamic> toJson() {
    var json = _$ProfileToJson(this);
    json['uuid'] = uuid;
    return json;
  }

  factory Profile.fromJson(Map<String, dynamic> json, {String? uuid}) {
    var profile = _$ProfileFromJson(json);
    if (uuid != null || profile.uuid.isEmpty) {
      return profile.copyWith(uuid: uuid ?? Uuid.generate());
    }
    return profile;
  }

  @override
  List<Object?> get props => [
    uuid,
    displayName,
    relayAtsign,
    sshnpdAtsign,
    deviceName,
    remoteHost,
    remotePort,
    localPort,
    only443,
    keepAlive,
  ];

  @override
  bool get stringify => true;

  NptParams toNptParams({
    required String clientAtsign,
    required String rootDomain,
    required String fallbackRelayAtsign,
    bool overrideRelayWithFallback = false,
  }) {
    String srvdAtSign = fallbackRelayAtsign;
    if (!overrideRelayWithFallback &&
        relayAtsign != null &&
        relayAtsign!.isNotEmpty) {
      srvdAtSign = relayAtsign!;
    }
    return NptParams(
      clientAtSign: clientAtsign,
      sshnpdAtSign: sshnpdAtsign,
      srvdAtSign: srvdAtSign,
      remoteHost: remoteHost,
      remotePort: remotePort,
      device: deviceName,
      localPort: localPort,
      rootDomain: rootDomain,
      only443: only443,
      // When using 443, we must use ESCR relay auth mode
      relayAuthMode: only443 ? RelayAuthMode.escr : RelayAuthMode.payload,

      // hardcoded for now, because it makes the app simpler
      // and there's very few use-cases where you wouldn't want these settings
      inline: true,
      timeout: keepAlive ? const Duration(hours: 24) : const Duration(hours: 1),
    );
  }

  static Profile empty() {
    return const Profile(
      '',
      displayName: '',
      relayAtsign: '',
      sshnpdAtsign: '',
      deviceName: '',
      friendlyName: '',
      startUpOption: '',
      remotePort: 0,
      localPort: 0,
      serverClientGUID: '',
    );
  }

  bool get isNotEmpty =>
      uuid.isNotEmpty; // Helper to check if the profile is not empty

  @override
  String toString() {
    return 'Profile(displayName: $displayName, sshnpd: $sshnpdAtsign, '
        'deviceName: $deviceName, relayAtsign: $relayAtsign, uuid: $uuid)';
  }
}
