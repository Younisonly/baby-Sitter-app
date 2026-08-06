import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/storage/local_storage.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final mode = await LocalStorage.getThemeMode();
    switch (mode) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      default:
        state = ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    String modeStr;
    switch (mode) {
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      default:
        modeStr = 'system';
    }
    await LocalStorage.setThemeMode(modeStr);
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(newMode);
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(const AppLanguage('en')) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final hasStored = await LocalStorage.hasLanguageCode();
    if (hasStored) {
      final code = await LocalStorage.getLanguageCode();
      state = AppLanguage(code);
    } else {
      final systemLocale = ui.PlatformDispatcher.instance.locale.languageCode;
      final code = ['en', 'ar'].contains(systemLocale) ? systemLocale : 'en';
      state = AppLanguage(code);
      await LocalStorage.setLanguageCode(code);
    }
  }

  Future<void> setLanguage(String code) async {
    state = AppLanguage(code);
    await LocalStorage.setLanguageCode(code);
    _syncLanguageToApi(code);
  }

  Future<void> _syncLanguageToApi(String code) async {
    try {
      final dio = DioClient.dio;
      await dio.put('/profile', data: {'preferred_language': code});
    } catch (_) {
      // Silently ignore — language is saved locally regardless
    }
  }
}

class AppLanguage {
  final String code;
  const AppLanguage(this.code);

  Locale get locale => Locale(code);
  bool get isRtl => code == 'ar';
  String get name => AppLocalization.languageNames[code] ?? 'English';
}
