import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kreengate/helper/global_function.dart';
import 'package:kreengate/helper/global_var.dart';
import 'package:kreengate/pages/splash_screen_page.dart';
import 'package:kreengate/services/lang_service.dart';
import 'package:kreengate/services/storage_services.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // SplashScreenActivity: onPreDraw mengembalikan false sampai showContent (postDelayed 500ms)
  binding.deferFirstFrame();
  Timer(const Duration(milliseconds: 500), binding.allowFirstFrame);

  // Firebase Analytics + Crashlytics (google-services)
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await StorageService.init();
  await LangService.preload();

  // MyApp.attachBaseContext: LanguageManager.updateResource(getLang())
  LangService.updateResource();

  edgeToEdge = await androidSdkInt() >= 35;
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kreen Gate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        colorScheme: ColorScheme.fromSeed(seedColor: colorPrimary).copyWith(
          primary: colorPrimary,
          secondary: colorPrimaryLight,
        ),
        scaffoldBackgroundColor: white,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: colorPrimaryLight,
          selectionHandleColor: colorPrimaryLight,
        ),
      ),
      navigatorObservers: [activityRouteObserver],
      builder: (context, child) {
        initSdp(context);
        final media = MediaQuery.of(context);
        // ukuran teks diset dalam dp (alias __Nssp -> _Msdp); ukuran "sp" dikali systemTextScale manual
        systemTextScale = media.textScaler.scale(100) / 100;
        Widget app = MediaQuery(data: media.copyWith(textScaler: TextScaler.noScaling), child: child!);
        if (!edgeToEdge) {
          // < API 35: navigation bar tidak transparan, konten berhenti di atasnya
          final bottom = media.padding.bottom;
          app = Column(children: [
            Expanded(child: MediaQuery.removePadding(context: context, removeBottom: true, child: app)),
            Container(height: bottom, color: black),
          ]);
        }
        return app;
      },
      home: const SplashScreenPage(),
    );
  }
}

