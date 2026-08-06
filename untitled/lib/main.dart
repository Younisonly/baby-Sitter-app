import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:babysitter/core/services/firebase_options.dart';
import 'package:babysitter/core/constants/app_constants.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/network/auth_interceptor.dart';
import 'package:babysitter/core/network/dedupe_interceptor.dart';
import 'package:babysitter/core/network/dio_client.dart';
import 'package:babysitter/core/network/language_interceptor.dart';
import 'package:babysitter/core/routing/app_router.dart';
import 'package:babysitter/core/routing/app_router_guard.dart';
import 'package:babysitter/core/services/auth_provider.dart';
import 'package:babysitter/core/services/cache_service.dart';
import 'package:babysitter/core/services/deep_link_service.dart';
import 'package:babysitter/core/services/fcm_service.dart';
import 'package:babysitter/core/services/heartbeat_service.dart';
import 'package:babysitter/core/services/role_manager.dart';
import 'package:babysitter/core/services/theme_language_providers.dart';
import 'package:babysitter/core/storage/local_storage.dart';
import 'package:babysitter/core/themes/app_theme.dart';

void main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception.toString().contains('_HighlightModeManager')) return;
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    return true;
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await LocalStorage.init();
    await CacheService.init();
    await AppRouterGuard.init();

    DioClient.addInterceptors([
      AuthInterceptor(),
      RetryInterceptor(dio: DioClient.dio),
      LanguageInterceptor(),
    ]);
    DioClient.addInterceptor(DedupeInterceptor());

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {}

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    runApp(
      const ProviderScope(
        child: BabySitterApp(),
      ),
    );
  }, (Object error, StackTrace stack) {});
}

class BabySitterApp extends ConsumerStatefulWidget {
  const BabySitterApp({super.key});

  @override
  ConsumerState<BabySitterApp> createState() => _BabySitterAppState();
}

class _BabySitterAppState extends ConsumerState<BabySitterApp> with WidgetsBindingObserver {
  final HeartbeatService _heartbeatService = HeartbeatService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatService.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _heartbeatService.onLifecycleChange(state);
  }

  Future<void> _startHeartbeatIfAuthenticated() async {
    final token = await LocalStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      _heartbeatService.start();
    }
  }

  Future<void> _initServices() async {
    final fcmService = ref.read(fcmServiceProvider);
    await fcmService.init();

    final roleState = ref.read(roleManagerProvider);

    DeepLinkNavigation.init((type, id) {
      DeepLinkService.navigate(AppRouter.router, type, id, role: roleState.activeRole);
    });

    final pending = await LocalStorage.getPendingDeepLink();
    if (pending != null) {
      await LocalStorage.clearPendingDeepLink();
      final parts = pending.split('|');
      if (parts.length >= 2) {
        DeepLinkService.navigate(AppRouter.router, parts[0], parts[1], role: roleState.activeRole);
      }
    }

    await _startHeartbeatIfAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);
    ref.watch(roleManagerProvider);

    ref.listen(authProvider, (_, next) {
      if (next.isAuthenticated) {
        _heartbeatService.start();
      } else {
        _heartbeatService.stop();
      }
    });

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppThemeData.lightTheme,
          darkTheme: AppThemeData.darkTheme,
          themeMode: themeMode,
          routerConfig: AppRouter.router,
          locale: language.locale,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale?.languageCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
          builder: (context, child) {
            return Directionality(
              textDirection:
                  language.isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.0)),
                child: child!,
              ),
            );
          },
        );
      },
    );
  }
}
