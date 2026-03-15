import 'dart:ui';
import 'package:flutter_riverpod/legacy.dart';

final localeProvider = StateProvider<Locale>((ref) {
  return const Locale('en'); // Default to English, or load from storage later
});
