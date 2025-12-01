import 'package:flutter/foundation.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

/// Handles loading and showing of a single interstitial ad instance.
class InterstitialAdService {
  InterstitialAdService({
    required this.adUnitId,
  });

  final String adUnitId;

  InterstitialAd? _interstitialAd;
  late final Future<InterstitialAdLoader> _loader = _createLoader();
  bool _isLoading = false;
  bool _isShowing = false;

  bool get isAdReady => _interstitialAd != null;
  bool get isLoading => _isLoading;

  /// Starts loading the ad if there is no cached ad and nothing is loading yet.
  Future<void> load() async {
    if (_isLoading || _interstitialAd != null) {
      return;
    }
    _isLoading = true;
    final loader = await _loader;
    await loader.loadAd(
      adRequestConfiguration: AdRequestConfiguration(adUnitId: adUnitId),
    );
  }

  /// Shows the cached ad and requests the next one right after dismissal.
  Future<bool> show() async {
    final ad = _interstitialAd;
    if (ad == null) {
      await load();
      return false;
    }
    if (_isShowing) {
      return false;
    }
    _isShowing = true;
    _setAdEventListener(ad);
    await ad.show();
    await ad.waitForDismiss();
    return true;
  }

  /// Releases resources to avoid leaks.
  void dispose() {
    _clearAd();
  }

  void _clearAd() {
    _interstitialAd?.destroy();
    _interstitialAd = null;
    _isLoading = false;
  }

  void _setAdEventListener(InterstitialAd ad) {
    ad.setAdEventListener(
      eventListener: InterstitialAdEventListener(
        onAdShown: () => debugPrint('Interstitial shown'),
        onAdClicked: () => debugPrint('Interstitial clicked'),
        onAdImpression: (data) =>
            debugPrint('Interstitial impression: ${data.getRawData()}'),
        onAdDismissed: () {
          debugPrint('Interstitial dismissed');
          _isShowing = false;
          _clearAd();
          load();
        },
        onAdFailedToShow: (error) {
          debugPrint(
            'Interstitial failed to show: ${error.description}',
          );
          _isShowing = false;
          _clearAd();
          load();
        },
      ),
    );
  }

  Future<InterstitialAdLoader> _createLoader() {
    return InterstitialAdLoader.create(
      onAdLoaded: (InterstitialAd ad) {
        debugPrint('Interstitial loaded');
        _interstitialAd = ad;
        _isLoading = false;
      },
      onAdFailedToLoad: (error) {
        debugPrint(
          'Interstitial failed to load: code=${error.code}, message=${error.description}',
        );
        _clearAd();
      },
    );
  }
}
