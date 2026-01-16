import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  InterstitialAd? _interstitialAd;
  int _requestCount = 0;
  bool _isAdLoading = false;

  final String _adUnitId = 'ca-app-pub-4812394189441495/2951672714';

  void loadInterstitialAd() {
    if (_isAdLoading || _interstitialAd != null) return;
    _isAdLoading = true;

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoading = false;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _interstitialAd = null;
                  loadInterstitialAd();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  ad.dispose();
                  _interstitialAd = null;
                  loadInterstitialAd();
                },
              );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isAdLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  void incrementRequestCountAndShow() {
    _requestCount++;
    if (_requestCount >= 3) {
      if (_interstitialAd != null) {
        _interstitialAd!.show();
        _requestCount = 0;
      } else {
        loadInterstitialAd();
      }
    }
  }
}
