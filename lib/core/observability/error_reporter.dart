import 'package:flutter/foundation.dart';

class ErrorReporter {
  static void report(
    Object error,
    StackTrace? stack, {
    String? context,
  }) {
    final prefix = context == null ? 'Error' : 'Error ($context)';
    debugPrint('$prefix: $error');
    if (stack != null) {
      debugPrint(stack.toString());
    }
  }
}
