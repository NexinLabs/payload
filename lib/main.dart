import "./config.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payload/core/theme/app_theme.dart';
import 'package:payload/core/router/app_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:payload/core/services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(const ProviderScope(child: PayloadApp()));

  // Move heavy tasks after runApp to avoid blocking the initial frame
  MobileAds.instance.initialize().then((_) {
    AdsService().loadInterstitialAd(showImmediately: true);
  });
}

class PayloadApp extends StatelessWidget {
  const PayloadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: Config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
