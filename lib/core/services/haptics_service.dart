import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticsService {
  HapticsService._();

  static const _hapticsEnabledKey = 'haptics_enabled_v1';
  static final ValueNotifier<bool> enabledNotifier = ValueNotifier<bool>(true);
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    enabledNotifier.value = prefs.getBool(_hapticsEnabledKey) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    enabledNotifier.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsEnabledKey, enabled);
  }

  static void lightImpact() {
    if (!enabledNotifier.value) return;
    HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    if (!enabledNotifier.value) return;
    HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    if (!enabledNotifier.value) return;
    HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    if (!enabledNotifier.value) return;
    HapticFeedback.selectionClick();
  }
}

