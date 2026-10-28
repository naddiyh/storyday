import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CloudConfig {
  const CloudConfig(this.url, this.key);
  factory CloudConfig.environment() => const CloudConfig(
      String.fromEnvironment('SUPABASE_URL'),
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY',
          defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY')));
  final String url, key;
  bool get isEmpty => url.isEmpty && key.isEmpty;
  void validate() {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.scheme != 'https' &&
            !(uri.scheme == 'http' &&
                ['localhost', '127.0.0.1'].contains(uri.host))) ||
        key.isEmpty) {
      throw const FormatException(
          'Set a valid Supabase URL and public client key.');
    }
    if (key.startsWith('sb_secret_')) {
      throw const FormatException(
          'Use a public client key, never a secret key.');
    }
    if (!key.startsWith('sb_publishable_')) {
      try {
        final claims = jsonDecode(utf8.decode(
            base64Url.decode(base64Url.normalize(key.split('.')[1])))) as Map;
        if (claims['role'] != 'anon') {
          throw const FormatException('Not an anon client key.');
        }
      } catch (_) {
        throw const FormatException('Use a publishable or anon client key.');
      }
    }
  }
}

class CloudConnection {
  const CloudConnection({this.client, this.problem});
  final SupabaseClient? client;
  final String? problem;
  static Future<CloudConnection> initialize(CloudConfig config) async {
    if (config.isEmpty) return const CloudConnection();
    try {
      config.validate();
      await Supabase.initialize(url: config.url, anonKey: config.key);
      return CloudConnection(client: Supabase.instance.client);
    } catch (_) {
      return const CloudConnection(
          problem:
              'Cloud setup could not start. Local journaling is available.');
    }
  }
}

final cloudConnectionProvider =
    Provider<CloudConnection>((ref) => const CloudConnection());
final authEventsProvider = StreamProvider<AuthState>((ref) =>
    ref.watch(cloudConnectionProvider).client?.auth.onAuthStateChange ??
    const Stream.empty());
final cloudUserProvider = Provider<User?>((ref) {
  ref.watch(authEventsProvider);
  return ref.watch(cloudConnectionProvider).client?.auth.currentUser;
});
final journalSyncStatusProvider =
    StateProvider<String>((ref) => 'Saved on this device.');
