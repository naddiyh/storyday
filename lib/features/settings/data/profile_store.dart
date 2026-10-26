import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalProfile {
  const LocalProfile(
      {this.name = 'Journal keeper',
      this.bio = 'Making today count, pelan-pelan',
      this.email = '',
      this.buddyAvatar = false});
  final String name, bio, email;
  final bool buddyAvatar;
  Map<String, dynamic> toMap() =>
      {'name': name, 'bio': bio, 'email': email, 'buddy': buddyAvatar};
  factory LocalProfile.fromMap(Map<String, dynamic> m) => LocalProfile(
      name: m['name'] as String? ?? 'Journal keeper',
      bio: m['bio'] as String? ?? '',
      email: m['email'] as String? ?? '',
      buddyAvatar: m['buddy'] as bool? ?? false);
}

abstract interface class ProfileStore {
  Future<LocalProfile?> load();
  Future<void> save(LocalProfile profile);
}

class PreferencesProfileStore implements ProfileStore {
  PreferencesProfileStore(this.preferences);
  final SharedPreferencesAsync preferences;
  static const key = 'local-profile.v1';
  @override
  Future<LocalProfile?> load() async {
    final raw = await preferences.getString(key);
    return raw == null
        ? null
        : LocalProfile.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(LocalProfile profile) =>
      preferences.setString(key, jsonEncode(profile.toMap()));
}

class MemoryProfileStore implements ProfileStore {
  LocalProfile? value;
  @override
  Future<LocalProfile?> load() async => value;
  @override
  Future<void> save(LocalProfile profile) async {
    value = profile;
  }
}

final profileStoreProvider =
    Provider<ProfileStore>((ref) => MemoryProfileStore());
final initialProfileProvider =
    Provider<LocalProfile>((ref) => const LocalProfile());
final profileProvider = StateNotifierProvider<ProfileController, LocalProfile>(
    (ref) => ProfileController(
        ref.watch(profileStoreProvider), ref.watch(initialProfileProvider)));

class ProfileController extends StateNotifier<LocalProfile> {
  ProfileController(this.store, super.state);
  final ProfileStore store;
  Future<void> save(LocalProfile profile) async {
    await store.save(profile);
    if (mounted) state = profile;
  }
}
