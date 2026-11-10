import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config.dart';
import '../../data/google_auth.dart';
import '../../data/remote.dart';
import '../../features/auth/domain/clinic_code.dart';
import '../../features/auth/ui/signin_widgets.dart';
import '../theme.dart';
import '../widgets.dart';

/// Sign-in (required when the app has a server, so her records are never only on one phone).
/// The main way in is the 8-digit code a health worker makes for her on the staff dashboard;
/// no SMS, email or password needed. When this build has them, she can also use her Google
/// account or her phone number with an SMS code (AppConfig.smsSignIn).
/// After sign-in the router takes her on: to Home if her records are already on the server,
/// otherwise to the setup questions. Emergency help in the top bar never needs sign-in.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final phone = TextEditingController(), code = TextEditingController(), clinicCode = TextEditingController();
  final clinicFocus = FocusNode();
  String mode = 'clinic'; // clinic | sms | google
  bool sent = false, busy = false;
  String? err, codeError;

  @override
  void dispose() {
    phone.dispose();
    code.dispose();
    clinicCode.dispose();
    clinicFocus.dispose();
    super.dispose();
  }

  /// Tanzanian numbers: 07xx… or 06xx… → +2557xx…
  String get e164 {
    var p = phone.text.replaceAll(RegExp(r'[^0-9+]'), '');
    if (p.startsWith('0')) p = '+255${p.substring(1)}';
    if (!p.startsWith('+')) p = '+$p';
    return p;
  }

  void _closeIfPushed() {
    // she came from Welcome: close this screen once she is in (the router moves her on)
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  /// The clinic code: one request at a time, and a clear reason when it does not work.
  Future<void> _signInWithClinicCode() async {
    if (busy || !ClinicCode.isComplete(clinicCode.text)) return;
    final s = context.appRead;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      mode = 'clinic';
      codeError = null;
      err = null;
    });
    try {
      await s.redeemSetupCode(ClinicCode.digits(clinicCode.text));
      HapticFeedback.lightImpact();
      _closeIfPushed();
    } catch (e) {
      final sw = s.lang == 'sw';
      codeError = switch (classifyClinicCodeError(e)) {
        ClinicCodeFailure.refused =>
          sw
              ? 'Namba hii haikufanya kazi. Huenda si sahihi, imeshatumika au imepita saa 24. Omba kliniki yako namba mpya.'
              : 'This code did not work. It may be wrong, already used or older than 24 hours. Ask your clinic for a new one.',
        ClinicCodeFailure.tooManyTries =>
          sw
              ? 'Namba nyingi zisizo sahihi. Subiri saa moja kisha jaribu tena, au omba msaada kliniki.'
              : 'Too many wrong codes. Wait one hour and try again, or ask your clinic for help.',
        ClinicCodeFailure.noConnection =>
          sw
              ? 'Hatukuweza kufika kwenye mtandao. Kagua intaneti yako, kisha jaribu tena.'
              : 'We could not connect. Check your internet, then try again.',
      };
      HapticFeedback.mediumImpact();
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _run(Future<void> Function() f, {required String failEn, required String failSw, bool signsIn = true}) async {
    if (busy) return;
    final sw = context.appRead.lang == 'sw';
    setState(() {
      busy = true;
      err = null;
    });
    try {
      await f();
      if (signsIn) _closeIfPushed();
    } on RemoteError catch (e) {
      err = e.permanent
          ? (sw ? failSw : failEn)
          : (sw ? 'Hatukuweza kufika kwenye mtandao. Kagua intaneti yako, kisha jaribu tena.' : 'We could not connect. Check your internet, then try again.');
    } catch (_) {
      err = sw ? 'Imeshindikana. Kagua mtandao, kisha jaribu tena.' : 'That did not work. Check your connection, then try again.';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _google() async {
    setState(() => mode = 'google');
    await _run(
      () => context.appRead.signInWithGoogle(GoogleAuth.idToken),
      failEn: 'Google sign-in did not work. Try again, or use the code from your clinic.',
      failSw: 'Kuingia kwa Google hakukufanya kazi. Jaribu tena, au tumia namba kutoka kliniki.',
    );
    if (mounted && mode == 'google') setState(() => mode = 'clinic');
  }

  void _usePhone() => setState(() {
    mode = 'sms';
    sent = false;
    err = null;
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final sms = mode == 'sms';
    return Scaffold(
      appBar: AppBar(title: Text(context.t('Sign in', 'Ingia')), actions: const [EmergencyShortcut()]),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Sp.screen, Sp.sm, Sp.screen, Sp.xl),
          children: [
            StaggeredEntrance(
              children: [
                const SignInIllustration(),
                // welcome
                Semantics(
                  header: true,
                  child: Text(context.t('Welcome back, Mama!', 'Karibu tena, Mama!'), style: tt.headlineMedium),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: Sp.sm, bottom: Sp.xl),
                  child: Text(
                    context.t(
                      'Your health journey matters. Sign in to access your pregnancy and baby records.',
                      'Safari yako ya afya ni muhimu. Ingia uone kumbukumbu za ujauzito wako na za mtoto.',
                    ),
                    style: tt.bodyLarge!.copyWith(color: C.ink2, height: 1.5),
                  ),
                ),
                // sign in
                if (!sms) ..._clinicSection(tt) else ..._phoneSection(tt),
                if (err != null) ...[const Gap(Sp.md), ErrorState(err!)],
                const Gap(Sp.md),
                Center(
                  child: TextButton.icon(
                    key: const Key('signin-help'),
                    style: TextButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: C.primary),
                    onPressed: () => showSignInHelp(context),
                    icon: const Icon(Icons.help_outline, size: 20),
                    label: Text(
                      context.t('Need help signing in?', 'Unahitaji msaada kuingia?'),
                      style: const TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
                if (GoogleAuth.available && !sms) ...[
                  const Gap(Sp.md),
                  _OrDivider(context.t('or', 'au')),
                  const Gap(Sp.md),
                  OutlineButton(
                    key: const Key('signin-google'),
                    context.t('Continue with Google', 'Endelea na Google'),
                    icon: Icons.account_circle_outlined,
                    loading: busy && mode == 'google',
                    onPressed: busy ? null : _google,
                  ),
                ],
                // registration
                const Gap(Sp.lg),
                const Divider(),
                const Gap(Sp.lg),
                Text(
                  context.t('New to Safari ya Mama?', 'Mgeni kwa Safari ya Mama?'),
                  style: tt.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const Gap(Sp.smd),
                OutlineButton(
                  key: const Key('signin-create'),
                  context.t('Create an account', 'Fungua akaunti'),
                  icon: Icons.person_add_alt_1_outlined,
                  onPressed: busy
                      ? null
                      : () => showCreateAccount(
                          context,
                          onPhone: AppConfig.smsSignIn ? _usePhone : null,
                          onGoogle: GoogleAuth.available ? _google : null,
                        ),
                ),
                const Gap(Sp.xl),
                const PrivacyNote(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _clinicSection(TextTheme tt) {
    final ready = ClinicCode.isComplete(clinicCode.text);
    return [
      Semantics(
        header: true,
        child: Text(context.t('Sign in with your clinic code', 'Ingia kwa namba ya kliniki'), style: tt.titleLarge),
      ),
      const Gap(Sp.md),
      ClinicCodeField(
        controller: clinicCode,
        focusNode: clinicFocus,
        error: codeError,
        busy: busy,
        onChanged: (_) => setState(() => codeError = null),
        onSubmitted: _signInWithClinicCode,
      ),
      const Gap(Sp.md),
      PressFeedback(
        enabled: ready && !busy,
        child: PrimaryButton(
          key: const Key('signin-clinic'),
          context.t('Sign in', 'Ingia'),
          loading: busy && mode == 'clinic',
          onPressed: ready && !busy ? _signInWithClinicCode : null,
        ),
      ),
      if (AppConfig.smsSignIn) ...[
        const Gap(Sp.sm),
        Center(
          child: TextButton(
            key: const Key('signin-use-phone'),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: busy ? null : _usePhone,
            child: Text(context.t('Sign in with your phone number instead', 'Ingia kwa namba ya simu badala yake')),
          ),
        ),
      ],
    ];
  }

  List<Widget> _phoneSection(TextTheme tt) {
    final digits = phone.text.replaceAll(RegExp(r'[^0-9]'), '');
    return [
      Semantics(
        header: true,
        child: Text(context.t('Sign in with your phone number', 'Ingia kwa namba ya simu'), style: tt.titleLarge),
      ),
      const Gap(Sp.md),
      if (!sent) ...[
        Labeled(
          label: context.t('Phone number', 'Namba ya simu'),
          child: TextField(
            key: const Key('signin-phone'),
            controller: phone,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 200),
            decoration: const InputDecoration(hintText: '0712 345 678'),
          ),
        ),
        const Gap(Sp.md),
        PrimaryButton(
          key: const Key('signin-send'),
          context.t('Send me a code', 'Nitumie namba'),
          loading: busy,
          onPressed: digits.length < 9
              ? null
              : () => _run(
                  () async {
                    await context.appRead.sendCode(e164);
                    sent = true;
                  },
                  signsIn: false,
                  failEn: 'We could not send the code. Check the number, or use a code from your clinic.',
                  failSw: 'Hatukuweza kutuma namba. Kagua namba, au tumia namba kutoka kliniki.',
                ),
        ),
      ] else ...[
        Text(context.t('We sent a 6-digit code to $e164.', 'Tumetuma namba ya tarakimu 6 kwa $e164.'), style: tt.bodyLarge),
        const Gap(Sp.md),
        Labeled(
          label: context.t('Code', 'Namba'),
          child: TextField(
            key: const Key('signin-code'),
            controller: code,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 6,
            scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 200),
            decoration: const InputDecoration(),
          ),
        ),
        PrimaryButton(
          key: const Key('signin-verify'),
          context.t('Sign in', 'Ingia'),
          loading: busy,
          onPressed: code.text.trim().length < 6
              ? null
              : () => _run(
                  () => context.appRead.verifyCode(e164, code.text.trim()),
                  failEn: 'That code did not work. Check it, or ask for a new one.',
                  failSw: 'Namba hiyo haikufanya kazi. Ihakiki, au omba mpya.',
                ),
        ),
        Center(
          child: TextButton(onPressed: busy ? null : () => setState(() => sent = false), child: Text(context.t('Change number', 'Badilisha namba'))),
        ),
      ],
      Center(
        child: TextButton(
          key: const Key('signin-use-clinic'),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: busy
              ? null
              : () => setState(() {
                  mode = 'clinic';
                  err = null;
                }),
          child: Text(context.t('Use a code from my clinic instead', 'Tumia namba kutoka kliniki badala yake')),
        ),
      ),
    ];
  }
}

class _OrDivider extends StatelessWidget {
  final String text;
  const _OrDivider(this.text);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.smd),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      ),
      const Expanded(child: Divider()),
    ],
  );
}
