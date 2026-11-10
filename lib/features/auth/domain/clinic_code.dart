import 'package:flutter/services.dart';

import '../../../data/remote.dart';

/// The 8-digit code a health worker makes for a mother on the staff dashboard ("Set up a
/// mother"). It is valid for 24 hours and works once; only its hash is kept on the server
/// (Edge Function `mother-setup`, action "redeem").
class ClinicCode {
  static const length = 8;

  static String digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  /// "12345678" → "1234 5678" (a space after the 4th digit).
  static String format(String digits) => digits.length <= 4 ? digits : '${digits.substring(0, 4)} ${digits.substring(4)}';

  static bool isComplete(String text) => digits(text).length == length;
}

/// Digits only, at most 8, shown as "1234 5678" while she types. Keeps the cursor where she
/// is typing, and a backspace just after the space removes the digit before it.
class ClinicCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    var cursor = newValue.selection.isValid ? newValue.selection.end.clamp(0, text.length) : text.length;
    // she deleted only the space: delete the digit in front of it instead
    if (text.length < oldValue.text.length && ClinicCode.digits(text) == ClinicCode.digits(oldValue.text) && cursor > 0) {
      text = text.substring(0, cursor - 1) + text.substring(cursor);
      cursor -= 1;
    }
    var d = ClinicCode.digits(text);
    if (d.length > ClinicCode.length) d = d.substring(0, ClinicCode.length);
    var before = ClinicCode.digits(text.substring(0, cursor)).length;
    if (before > d.length) before = d.length;
    final formatted = ClinicCode.format(d);
    final offset = before + (before > 4 ? 1 : 0);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset > formatted.length ? formatted.length : offset),
    );
  }
}

/// Why a sign-in with a clinic code did not work, so the screen can say what to do next.
enum ClinicCodeFailure {
  /// Wrong, already used, older than 24 hours, or the account is not ready: ask for a new code.
  refused,

  /// Too many wrong codes from this phone in the last hour.
  tooManyTries,

  /// No internet, or the server could not be reached.
  noConnection,
}

ClinicCodeFailure classifyClinicCodeError(Object e) {
  if (e is RemoteError) {
    if (e.status == 429) return ClinicCodeFailure.tooManyTries;
    if (e.permanent) return ClinicCodeFailure.refused;
  }
  return ClinicCodeFailure.noConnection;
}
