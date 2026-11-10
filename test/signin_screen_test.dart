// The redesigned sign-in screen: the 8-digit clinic code (format, counter, validation, one
// request at a time, clear errors), help and account sheets, Emergency without sign-in, and
// small phones with large text.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:safari_ya_mama/app/app.dart';
import 'package:safari_ya_mama/app/providers.dart';
import 'package:safari_ya_mama/config.dart';
import 'package:safari_ya_mama/data/local_store.dart';
import 'package:safari_ya_mama/data/remote.dart';
import 'package:safari_ya_mama/features/auth/domain/clinic_code.dart';
import 'package:safari_ya_mama/state/app_state.dart';

import 'fakes.dart';

TextEditingValue _type(String old, String typed) =>
    ClinicCodeFormatter().formatEditUpdate(TextEditingValue(text: old), TextEditingValue(text: typed, selection: TextSelection.collapsed(offset: typed.length)));

void main() {
  group('clinic code', () {
    test('digits only, at most 8, shown as 1234 5678', () {
      expect(_type('', '12345').text, '1234 5');
      expect(_type('', '12345678').text, '1234 5678');
      expect(_type('', '1234-56ab78 9').text, '1234 5678');
      expect(_type('', 'abc').text, '');
      expect(ClinicCode.isComplete('1234 5678'), isTrue);
      expect(ClinicCode.isComplete('1234 567'), isFalse);
    });

    test('a backspace after the space removes the digit before it', () {
      final v = ClinicCodeFormatter().formatEditUpdate(
        const TextEditingValue(text: '1234 5', selection: TextSelection.collapsed(offset: 5)),
        const TextEditingValue(text: '12345', selection: TextSelection.collapsed(offset: 4)),
      );
      expect(v.text, '1235');
    });

    test('server answers become reasons she can act on', () {
      expect(classifyClinicCodeError(RemoteError('bad', permanent: true, status: 400)), ClinicCodeFailure.refused);
      expect(classifyClinicCodeError(RemoteError('slow down', permanent: true, status: 429)), ClinicCodeFailure.tooManyTries);
      expect(classifyClinicCodeError(RemoteError('SocketException')), ClinicCodeFailure.noConnection);
      expect(classifyClinicCodeError(Exception('x')), ClinicCodeFailure.noConnection);
    });
  });

  late LocalStore store;
  late FakeRemote remote;
  setUp(() async {
    store = LocalStore();
    await store.open(inMemory: true);
    remote = FakeRemote()..uid = null;
  });
  tearDown(() {
    AppConfig.smsSignIn = false;
    return Hive.close();
  });

  Future<AppState> open(WidgetTester t, {Size size = const Size(1080, 2340), double ratio = 2.75, double text = 1}) async {
    final s = AppState(store, remote: remote);
    await s.setLang('en');
    t.view.physicalSize = size;
    t.view.devicePixelRatio = ratio;
    t.platformDispatcher.textScaleFactorTestValue = text;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await t.pumpWidget(ProviderScope(overrides: [appStateProvider.overrideWith((ref) => s)], child: const SafariYaMamaApp()));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const Key('get-started')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('get-started')));
    await t.pumpAndSettle();
    return s;
  }

  FilledButton signInButton(WidgetTester t) => t.widget<FilledButton>(find.descendant(of: find.byKey(const Key('signin-clinic')), matching: find.byType(FilledButton)));

  testWidgets('the screen in order: welcome, clinic code, help, create an account, privacy', (t) async {
    await open(t);
    for (final text in [
      'Sign in',
      'Welcome back, Mama!',
      'Sign in with your clinic code',
      'Clinic verification code',
      'Get your 8-digit code from a health worker at your clinic.',
      'Need help signing in?',
      'New to Safari ya Mama?',
      'Create an account',
      'Your health information is private and secure.',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(find.text('0/8'), findsOneWidget);
  });

  testWidgets('Sign in stays off until all 8 digits are in; the counter follows', (t) async {
    await open(t);
    expect(signInButton(t).onPressed, isNull);
    await t.enterText(find.byKey(const Key('signin-clinic-code')), '1234567');
    await t.pump();
    expect(find.text('1234 567'), findsOneWidget);
    expect(find.text('7/8'), findsOneWidget);
    expect(signInButton(t).onPressed, isNull);
    await t.enterText(find.byKey(const Key('signin-clinic-code')), '12345678');
    await t.pump();
    expect(find.text('8/8'), findsOneWidget);
    expect(find.text('All 8 digits are in. Tap Sign in.'), findsOneWidget);
    expect(signInButton(t).onPressed, isNotNull);
  });

  testWidgets('one request at a time, with a spinner while it runs', (t) async {
    remote.setupCodes.add('48213907');
    remote.setupHold = Completer<void>();
    final s = await open(t);
    await t.enterText(find.byKey(const Key('signin-clinic-code')), '48213907');
    await t.pump();
    await t.tap(find.byKey(const Key('signin-clinic')));
    await t.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await t.tap(find.byKey(const Key('signin-clinic')), warnIfMissed: false);
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump();
    expect(remote.calls.where((c) => c.startsWith('setup')), hasLength(1));
    remote.setupHold!.complete();
    await t.pumpAndSettle();
    expect(s.signedIn, isTrue);
  });

  testWidgets('no internet: she is told to check her connection, and the code stays', (t) async {
    remote.setupFails = RemoteError('SocketException: failed host lookup');
    final s = await open(t);
    await t.enterText(find.byKey(const Key('signin-clinic-code')), '48213907');
    await t.pump();
    await t.tap(find.byKey(const Key('signin-clinic')));
    await t.pumpAndSettle();
    expect(s.signedIn, isFalse);
    expect(find.text('We could not connect. Check your internet, then try again.'), findsOneWidget);
    expect(find.text('4821 3907'), findsOneWidget);
    // typing again clears the message
    await t.enterText(find.byKey(const Key('signin-clinic-code')), '4821390');
    await t.pumpAndSettle();
    expect(find.textContaining('We could not connect'), findsNothing);
  });

  testWidgets('too many wrong codes has its own message', (t) async {
    remote.setupFails = RemoteError('function 429', permanent: true, status: 429);
    await open(t);
    await t.enterText(find.byKey(const Key('signin-clinic-code')), '48213907');
    await t.pump();
    await t.tap(find.byKey(const Key('signin-clinic')));
    await t.pumpAndSettle();
    expect(find.textContaining('Too many wrong codes'), findsOneWidget);
  });

  testWidgets('help sheet explains a lost code or phone and opens Emergency', (t) async {
    await open(t);
    await t.ensureVisible(find.byKey(const Key('signin-help')));
    await t.tap(find.byKey(const Key('signin-help')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('signin-help-sheet')), findsOneWidget);
    expect(find.text('I lost my phone or have a new one'), findsOneWidget);
    await t.ensureVisible(find.byKey(const Key('signin-help-emergency')));
    await t.tap(find.byKey(const Key('signin-help-emergency')));
    await t.pumpAndSettle();
    expect(find.text('Need urgent help?'), findsOneWidget);
  });

  testWidgets('create an account: the clinic makes it; with SMS on she can start on her own', (t) async {
    await open(t);
    await t.ensureVisible(find.byKey(const Key('signin-create')));
    await t.tap(find.byKey(const Key('signin-create')));
    await t.pumpAndSettle();
    expect(find.text('At your clinic'), findsOneWidget);
    expect(find.byKey(const Key('signin-create-phone')), findsNothing, reason: 'no SMS in this build');
    await t.tap(find.byKey(const Key('signin-create-ok')));
    await t.pumpAndSettle();

    AppConfig.smsSignIn = true;
    await t.ensureVisible(find.byKey(const Key('signin-create')));
    await t.tap(find.byKey(const Key('signin-create')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('signin-create-phone')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('signin-phone')), findsOneWidget);
  });

  testWidgets('Emergency works before sign-in', (t) async {
    await open(t);
    await t.tap(find.byKey(const Key('emergency')));
    await t.pumpAndSettle();
    expect(find.text('Need urgent help?'), findsOneWidget);
  });

  testWidgets('small phone, largest text, keyboard open: nothing overflows', (t) async {
    await open(t, size: const Size(720, 1280), ratio: 2, text: 2);
    t.view.viewInsets = const FakeViewPadding(bottom: 600);
    await t.ensureVisible(find.byKey(const Key('signin-clinic-code')));
    await t.tap(find.byKey(const Key('signin-clinic-code')));
    await t.enterText(find.byKey(const Key('signin-clinic-code')), '12345678');
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.byKey(const Key('signin-clinic')).hitTestable(), findsOneWidget, reason: 'Sign in stays reachable above the keyboard');
  });
}
