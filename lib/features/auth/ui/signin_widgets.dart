import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router.dart';
import '../../../core/content_assets.dart';
import '../../../ui/content_widgets.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets.dart';
import '../domain/clinic_code.dart';

/// Fades and lifts the sign-in sections in, one after another (about half a second in all).
/// With "remove animations" on, everything is simply there.
class StaggeredEntrance extends StatefulWidget {
  final List<Widget> children;
  const StaggeredEntrance({super.key, required this.children});
  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  bool started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    if (MediaQuery.of(context).disableAnimations) {
      c.value = 1;
    } else {
      c.forward();
    }
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.children.length;
    final step = n <= 1 ? 0.0 : 0.4 / (n - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < n; i++)
          Builder(
            builder: (_) {
              final a = CurvedAnimation(
                parent: c,
                curve: Interval(i * step, i * step + 0.6, curve: const Cubic(0.23, 1, 0.32, 1)),
              );
              return FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, .06), end: Offset.zero).animate(a),
                  child: widget.children[i],
                ),
              );
            },
          ),
      ],
    );
  }
}

/// The sign-in picture (ONB-SIGNIN): a rounded frame whose height follows the screen, so the
/// code field and the button stay close on a small phone.
class SignInIllustration extends StatelessWidget {
  const SignInIllustration({super.key});
  @override
  Widget build(BuildContext context) {
    if (!ContentAssets.has('ONB-SIGNIN')) return const SizedBox.shrink();
    final h = (MediaQuery.sizeOf(context).height * .22).clamp(130.0, 210.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.lg),
      child: Container(
        height: h,
        decoration: BoxDecoration(color: C.primarySoft, borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ContentPicture(
          'ONB-SIGNIN',
          height: h,
          radius: 20,
          fit: BoxFit.cover,
          fallback: const SizedBox.shrink(),
          semanticLabel: context.t('A mother at home holding her phone', 'Mama nyumbani akiwa ameshika simu yake'),
        ),
      ),
    );
  }
}

/// The 8-digit clinic code field: numbers only, shown as "1234 5678", a 0/8 counter, a tick
/// when all 8 digits are in, and the server's answer as an error under the box.
class ClinicCodeField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? error;
  final bool busy;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  const ClinicCodeField({
    super.key,
    required this.controller,
    this.focusNode,
    this.error,
    this.busy = false,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final n = ClinicCode.digits(controller.text).length;
    final complete = n == ClinicCode.length;
    const digitStyle = TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.5, fontFeatures: [FontFeature.tabularFigures()]);
    return Labeled(
      label: context.t('Clinic verification code', 'Namba ya uthibitisho ya kliniki'),
      error: error != null,
      child: TextField(
        key: const Key('signin-clinic-code'),
        controller: controller,
        focusNode: focusNode,
        readOnly: busy,
        keyboardType: TextInputType.number,
        inputFormatters: [ClinicCodeFormatter()],
        autofillHints: const [AutofillHints.oneTimeCode],
        textInputAction: TextInputAction.done,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted(),
        // keep the Sign in button in view above the keyboard
        scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 200),
        style: digitStyle.copyWith(color: C.ink),
        decoration: InputDecoration(
          hintText: '1234 5678',
          hintStyle: digitStyle.copyWith(color: C.ink3, fontWeight: FontWeight.w400),
          counterText: '$n/${ClinicCode.length}',
          counterStyle: const TextStyle(fontSize: 14, color: C.ink2, fontFeatures: [FontFeature.tabularFigures()]),
          errorText: error,
          helperText: complete
              ? context.t('All 8 digits are in. Tap Sign in.', 'Tarakimu zote 8 zimeingia. Bonyeza Ingia.')
              : context.t('Get your 8-digit code from a health worker at your clinic.', 'Pata namba yako ya tarakimu 8 kutoka kwa mhudumu wa afya kliniki.'),
          helperMaxLines: 2,
          helperStyle: TextStyle(fontSize: 14, height: 1.35, color: complete ? C.green : C.ink2, fontWeight: complete ? FontWeight.w600 : FontWeight.w400),
          suffixIcon: complete && error == null
              ? Icon(Icons.check_circle_rounded, color: C.green, semanticLabel: context.t('Code complete', 'Namba imekamilika'))
              : null,
        ),
      ),
    );
  }
}

/// Shrinks a button a little while it is pressed (feedback lands on press-in).
class PressFeedback extends StatefulWidget {
  final Widget child;
  final bool enabled;
  const PressFeedback({super.key, required this.child, this.enabled = true});
  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback> {
  bool down = false;
  void set(bool v) {
    if (widget.enabled && down != v) setState(() => down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Listener(
      onPointerDown: (_) => set(true),
      onPointerUp: (_) => set(false),
      onPointerCancel: (_) => set(false),
      child: AnimatedScale(
        scale: down && !reduce ? .97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// "Your health information is private and secure." with a small shield.
class PrivacyNote extends StatelessWidget {
  const PrivacyNote({super.key});
  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified_user_outlined, size: 18, color: C.ink3),
        const SizedBox(width: Sp.sm),
        Flexible(
          child: Text(
            context.t('Your health information is private and secure.', 'Taarifa zako za afya ni siri na ziko salama.'),
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: C.ink3),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}

Future<void> _sheet(BuildContext context, Widget Function(BuildContext) body) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: C.bg,
  builder: (ctx) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .85),
      child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(Sp.screen, 0, Sp.screen, Sp.lg), child: body(ctx)),
    ),
  ),
);

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title, body;
  const _HelpItem(this.icon, this.title, this.body);
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.md),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: C.primarySoft, shape: BoxShape.circle),
              child: Icon(icon, color: C.primary, size: 22),
            ),
            const SizedBox(width: Sp.smd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: tt.titleMedium),
                  const SizedBox(height: 2),
                  Text(body, style: tt.bodyMedium!.copyWith(color: C.ink2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Need help signing in?": what to do without a code, with a code that fails, or on a new or
/// lost phone. Her records are on the server, so a new code brings them back on any phone.
Future<void> showSignInHelp(BuildContext context) {
  final phone = '${context.appRead.facility?['phone'] ?? ''}'.trim();
  return _sheet(context, (ctx) {
    final tt = Theme.of(ctx).textTheme;
    return Column(
      key: const Key('signin-help-sheet'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(ctx.t('Need help signing in?', 'Unahitaji msaada kuingia?'), style: tt.headlineSmall)),
        const Gap(Sp.lg),
        _HelpItem(
          Icons.confirmation_number_outlined,
          ctx.t('I do not have a code', 'Sina namba'),
          ctx.t(
            'Go to your clinic. A health worker sets up your account and gives you an 8-digit code.',
            'Nenda kliniki yako. Mhudumu wa afya atakuandalia akaunti na kukupa namba ya tarakimu 8.',
          ),
        ),
        _HelpItem(
          Icons.error_outline,
          ctx.t('My code does not work', 'Namba yangu haifanyi kazi'),
          ctx.t(
            'Each code works once, for 24 hours. Check all 8 digits. If it still does not work, ask your clinic for a new code.',
            'Kila namba inafanya kazi mara moja, kwa saa 24. Hakiki tarakimu zote 8. Ikishindikana, omba kliniki namba mpya.',
          ),
        ),
        _HelpItem(
          Icons.phone_android_outlined,
          ctx.t('I lost my phone or have a new one', 'Nimepoteza simu au nina simu mpya'),
          ctx.t(
            'Your checks, visits and vaccines are saved safely. Ask your clinic for a new code and sign in on this phone. Your records come back.',
            'Ukaguzi, kliniki na chanjo zako zimehifadhiwa salama. Omba kliniki namba mpya na uingie kwenye simu hii. Kumbukumbu zako zitarudi.',
          ),
        ),
        _HelpItem(
          Icons.wifi_off_outlined,
          ctx.t('No internet', 'Hakuna intaneti'),
          ctx.t(
            'Sign-in needs internet once. After that the app works without a signal.',
            'Kuingia kunahitaji intaneti mara moja. Baada ya hapo programu inafanya kazi bila mtandao.',
          ),
        ),
        if (phone.isNotEmpty) ...[
          const Gap(Sp.sm),
          OutlineButton(
            key: const Key('signin-help-call'),
            ctx.t('Call my clinic', 'Piga simu kliniki'),
            icon: Icons.call_outlined,
            onPressed: () => launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', ''))),
          ),
        ],
        const Gap(Sp.sm),
        DangerButton(
          key: const Key('signin-help-emergency'),
          ctx.t('I need help now', 'Nahitaji msaada sasa'),
          icon: Icons.emergency,
          onPressed: () {
            Navigator.of(ctx).pop();
            context.push(Routes.emergency);
          },
        ),
      ],
    );
  });
}

/// "Create an account". Her account is made by her clinic, which links it to her clinic
/// records. When SMS sign-in or Google is switched on in this build, she can also start on her
/// own; she links her clinic later in her profile.
Future<void> showCreateAccount(BuildContext context, {VoidCallback? onPhone, VoidCallback? onGoogle}) => _sheet(context, (ctx) {
  final tt = Theme.of(ctx).textTheme;
  final self = onPhone != null || onGoogle != null;
  return Column(
    key: const Key('signin-create-sheet'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(header: true, child: Text(ctx.t('Create your account', 'Fungua akaunti yako'), style: tt.headlineSmall)),
      const Gap(Sp.lg),
      _HelpItem(
        Icons.local_hospital_outlined,
        ctx.t('At your clinic', 'Kliniki yako'),
        ctx.t(
          'A health worker creates your account in a few minutes and links it to your clinic records. Bring your clinic card. You get an 8-digit code to sign in.',
          'Mhudumu wa afya atafungua akaunti yako kwa dakika chache na kuiunganisha na kumbukumbu zako za kliniki. Beba kadi yako ya kliniki. Utapata namba ya tarakimu 8 ya kuingia.',
        ),
      ),
      if (self) ...[
        _HelpItem(
          Icons.verified_outlined,
          ctx.t('On your own', 'Mwenyewe'),
          ctx.t(
            'Confirm it is you, then answer a few questions. Later, choose your clinic in your profile so your records are linked.',
            'Thibitisha kuwa ni wewe, kisha jibu maswali machache. Baadaye, chagua kliniki yako kwenye wasifu ili kumbukumbu ziunganishwe.',
          ),
        ),
        if (onPhone != null) ...[
          PrimaryButton(
            key: const Key('signin-create-phone'),
            ctx.t('Sign up with my phone number', 'Jisajili kwa namba yangu ya simu'),
            icon: Icons.sms_outlined,
            onPressed: () {
              Navigator.of(ctx).pop();
              onPhone();
            },
          ),
          const Gap(Sp.sm),
        ],
        if (onGoogle != null)
          OutlineButton(
            key: const Key('signin-create-google'),
            ctx.t('Continue with Google', 'Endelea na Google'),
            icon: Icons.account_circle_outlined,
            onPressed: () {
              Navigator.of(ctx).pop();
              onGoogle();
            },
          ),
      ] else
        PrimaryButton(
          key: const Key('signin-create-ok'),
          ctx.t('I have my code', 'Nina namba yangu'),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
    ],
  );
});
