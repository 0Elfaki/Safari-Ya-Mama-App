/// Build-time configuration:
///   `flutter run --dart-define=SUPABASE_URL=https://REF.supabase.co --dart-define=SUPABASE_ANON_KEY=KEY`
/// Without these the app runs fully on the phone (offline demo): nothing is sent anywhere.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const appVersion = '1.0.0';
  static bool get hasBackend => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Push (optional): the public Firebase app identifiers from the Firebase console
  /// (Project settings → Your apps). They are not secrets; the server key never ships.
  static const fcmApiKey = String.fromEnvironment('FCM_API_KEY');
  static const fcmAppId = String.fromEnvironment('FCM_APP_ID');
  static const fcmSenderId = String.fromEnvironment('FCM_SENDER_ID');
  static const fcmProjectId = String.fromEnvironment('FCM_PROJECT_ID');

  /// Google sign-in (optional): the OAuth client IDs from Google Cloud (not secrets).
  /// GOOGLE_WEB_CLIENT_ID is the "Web application" client also entered in Supabase → Auth → Google.
  static const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  /// Sign-in by SMS code. Off until an SMS provider is connected in Supabase (Auth → Phone);
  /// build with `--dart-define=SMS_SIGNIN=true` to show it. Without it, mothers sign in with a
  /// code from their clinic (or Google, when built in).
  static bool smsSignIn = const bool.fromEnvironment('SMS_SIGNIN');

  static bool get hasPush => fcmApiKey.isNotEmpty && fcmAppId.isNotEmpty && fcmSenderId.isNotEmpty && fcmProjectId.isNotEmpty;
}
