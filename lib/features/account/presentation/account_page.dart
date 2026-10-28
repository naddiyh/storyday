import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/cloud/cloud_connection.dart';
import '../../../core/widgets/page_content.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key, this.mode = 'login'});
  final String mode;
  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  final _current = TextEditingController(), _confirm = TextEditingController();
  bool _busy = false;
  String? _message;
  @override
  void dispose() {
    for (final c in [_email, _password, _current, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    final client = ref.read(cloudConnectionProvider).client;
    if (client == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final redirect = Uri.base.scheme.startsWith('http')
          ? '${Uri.base.origin}/#/account/password'
          : null;
      switch (widget.mode) {
        case 'signup':
          final response = await client.auth
              .signUp(email: _email.text.trim(), password: _password.text);
          if (mounted && response.session == null) {
            setState(() => _message =
                'Check your email to confirm your account, then log in.');
          }
        case 'reset':
          await client.auth
              .resetPasswordForEmail(_email.text.trim(), redirectTo: redirect);
          if (mounted) {
            setState(
                () => _message = 'Check your email for a password reset link.');
          }
        case 'password':
          final recovery = ref.read(authEventsProvider).valueOrNull?.event ==
              AuthChangeEvent.passwordRecovery;
          final user = client.auth.currentUser;
          if (user == null) throw const AuthException('Sign in first.');
          if (!recovery) {
            await client.auth.signInWithPassword(
                email: user.email!, password: _current.text);
          }
          await client.auth
              .updateUser(UserAttributes(password: _password.text));
          if (mounted) setState(() => _message = 'Password updated.');
        default:
          await client.auth.signInWithPassword(
              email: _email.text.trim(), password: _password.text);
      }
      if (mounted &&
          client.auth.currentSession != null &&
          widget.mode != 'password' &&
          widget.mode != 'reset') {
        context.go('/profile');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message =
            'Could not complete this request. Check your details and connection, then try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(cloudConnectionProvider);
    final enabled = connection.client != null;
    final reset = widget.mode == 'reset', change = widget.mode == 'password';
    final signup = widget.mode == 'signup';
    final recovery = ref.watch(authEventsProvider).valueOrNull?.event ==
        AuthChangeEvent.passwordRecovery;
    final canSubmit =
        enabled && !(_busy || (change && ref.watch(cloudUserProvider) == null));
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.chevron_left),
              onPressed: _busy
                  ? null
                  : () => context.canPop()
                      ? context.pop()
                      : context.go('/profile'))),
      body: SafeArea(
          child: PageContent(children: [
        Text(
            change
                ? 'Change password'
                : reset
                    ? 'Forgot password?'
                    : signup
                        ? 'Create your account'
                        : 'Welcome back!',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Text(enabled
            ? 'Your local journal works without an account. Only notes in your signed-in journal sync to this account.'
            : connection.problem ??
                'Cloud is not configured in this build. You can continue with your local journal.'),
        const SizedBox(height: 24),
        Form(
            key: _form,
            child: Column(children: [
              if (!change)
                TextFormField(
                    controller: _email,
                    enabled: enabled && !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(v?.trim() ?? '')
                        ? null
                        : 'Enter a valid email'),
              if (change && !recovery) ...[
                TextFormField(
                    controller: _current,
                    enabled: canSubmit,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Current password'),
                    validator: (v) => v?.isNotEmpty == true
                        ? null
                        : 'Enter your current password'),
                const SizedBox(height: 12),
              ],
              if (!reset) ...[
                const SizedBox(height: 12),
                TextFormField(
                    controller: _password,
                    enabled: enabled && !_busy,
                    obscureText: true,
                    autofillHints: [
                      signup || change
                          ? AutofillHints.newPassword
                          : AutofillHints.password
                    ],
                    decoration: InputDecoration(
                        labelText: change ? 'New password' : 'Password'),
                    validator: (v) => (v?.length ?? 0) >=
                            (signup || change ? 8 : 1)
                        ? null
                        : 'Enter ${signup || change ? 'at least 8 characters' : 'your password'}'),
              ],
              if (signup || change) ...[
                const SizedBox(height: 12),
                TextFormField(
                    controller: _confirm,
                    enabled: enabled && !_busy,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Confirm password'),
                    validator: (v) =>
                        v == _password.text ? null : 'Passwords do not match'),
              ],
            ])),
        if (_message != null)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(_message!, semanticsLabel: _message)),
        const SizedBox(height: 20),
        FilledButton(
            onPressed: canSubmit ? submit : null,
            child: Text(_busy
                ? 'Please wait...'
                : change
                    ? 'Update password'
                    : reset
                        ? 'Send reset link'
                        : signup
                            ? 'Create account'
                            : 'Log in')),
        if (!change && !reset)
          TextButton(
              onPressed: _busy ? null : () => context.push('/account/reset'),
              child: const Text('Forgot password?')),
        if (!change && !reset)
          TextButton(
              onPressed: _busy
                  ? null
                  : () => context
                      .push(signup ? '/account/login' : '/account/signup'),
              child: Text(signup
                  ? 'Already have an account? Log in'
                  : 'New here? Create an account')),
        TextButton(
            onPressed: _busy ? null : () => context.go('/calendar'),
            child: const Text('Continue with local journal')),
      ])),
    );
  }
}
