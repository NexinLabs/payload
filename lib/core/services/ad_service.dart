import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdsService {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoading = false;
  bool _hasShownInitialAd = false;

  // Google Test ID: ca-app-pub-3940256099942544/1033173712
  final String _adUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-4812394189441495/2951672714';

  void loadInterstitialAd({bool showImmediately = false}) {
    if (_isAdLoading || (_interstitialAd != null && !showImmediately)) return;
    _isAdLoading = true;
    debugPrint('AdsService: Loading Interstitial Ad...');

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AdsService: Interstitial Ad Loaded.');
          _interstitialAd = ad;
          _isAdLoading = false;

          if (showImmediately && !_hasShownInitialAd) {
            _showAd();
            _hasShownInitialAd = true;
          }

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  debugPrint('AdsService: Ad dismissed.');
                  ad.dispose();
                  _interstitialAd = null;
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  debugPrint('AdsService: Ad failed to show: $error');
                  ad.dispose();
                  _interstitialAd = null;
                },
              );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('AdsService: Interstitial Ad failed to load: $error');
          _isAdLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  void _showAd() {
    if (_interstitialAd != null) {
      debugPrint('AdsService: Showing Interstitial Ad.');
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }
}
