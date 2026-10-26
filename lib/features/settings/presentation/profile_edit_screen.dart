import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/scrapbook.dart';
import '../../../core/widgets/journal_character.dart';
import '../data/profile_store.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.profile, this.radius = 30});
  final LocalProfile profile;
  final double radius;
  @override
  Widget build(BuildContext context) => CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: profile.buddyAvatar
          ? JournalCharacter(width: radius * 1.7, height: radius * 1.8)
          : Text(
              profile.name.trim().isEmpty
                  ? 'J'
                  : profile.name.trim().characters.first.toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800)));
}

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, bio, email;
  late bool buddy;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    name = TextEditingController(text: p.name);
    bio = TextEditingController(text: p.bio);
    email = TextEditingController(text: p.email);
    buddy = p.buddyAvatar;
  }

  @override
  void dispose() {
    name.dispose();
    bio.dispose();
    email.dispose();
    super.dispose();
  }

  void close() => context.canPop() ? context.pop() : context.go('/profile');
  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ref.read(profileProvider.notifier).save(LocalProfile(
          name: name.text.trim(),
          bio: bio.text.trim(),
          email: email.text.trim(),
          buddyAvatar: buddy));
      if (mounted) close();
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = 'Could not save your profile. Your changes are still here.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageContent(children: [
      const ScrapbookHeader(title: 'Profile', subtitle: ''),
      ScrapbookPanel(
          child: Form(
              key: form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Edit profile',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ProfileAvatar(
                              profile: LocalProfile(
                                  name: name.text, buddyAvatar: buddy),
                              radius: 36),
                          FilledButton.tonal(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      final value = await showModalBottomSheet<
                                              bool>(
                                          context: context,
                                          builder: (context) => SafeArea(
                                                  child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                    ListTile(
                                                        title: const Text(
                                                            'Use my initial'),
                                                        leading: const Icon(Icons
                                                            .person_outline),
                                                        onTap: () =>
                                                            Navigator.pop(
                                                                context,
                                                                false)),
                                                    ListTile(
                                                        title: const Text(
                                                            'Use buddy illustration'),
                                                        leading: const SizedBox(
                                                            width: 32,
                                                            height: 40,
                                                            child:
                                                                JournalCharacter(
                                                                    width: 32,
                                                                    height:
                                                                        40)),
                                                        onTap: () =>
                                                            Navigator.pop(
                                                                context, true)),
                                                  ])));
                                      if (value != null && mounted) {
                                        setState(() => buddy = value);
                                      }
                                    },
                              child: const Text('Change photo')),
                        ]),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: name,
                        maxLength: 40,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                            labelText: 'Name', counterText: ''),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter your name'
                                : null),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: bio,
                        maxLength: 40,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                            labelText:
                                'Short bio (${bio.text.characters.length}/40)',
                            counterText: '')),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) => value != null &&
                                value.trim().isNotEmpty &&
                                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(value.trim())
                            ? 'Enter a valid email'
                            : null),
                    const SizedBox(height: 16),
                    const ListTile(
                        contentPadding: EdgeInsets.zero,
                        enabled: false,
                        leading: Icon(Icons.lock_outline),
                        title: Text('Change password'),
                        subtitle: Text('No sign-in account is connected.'),
                        trailing: Icon(Icons.chevron_right)),
                    if (error != null)
                      Text(error!,
                          style: TextStyle(color: theme.colorScheme.error)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: TextButton(
                              onPressed: saving ? null : close,
                              child: const Text('Cancel'))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: FilledButton(
                              onPressed: saving ? null : save,
                              child: Text(saving ? 'Saving…' : 'Save')))
                    ]),
                  ]))),
    ]);
  }
}
