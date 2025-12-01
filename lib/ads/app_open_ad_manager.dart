import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

/// Loads and shows App Open ads when the app returns to foreground.
class AppOpenAdManager with WidgetsBindingObserver {
  AppOpenAdManager({
    required this.adUnitId,
    this.minTimeBetweenDisplays = const Duration(hours: 1),
  });

  final String adUnitId;
  final Duration minTimeBetweenDisplays;

  AppOpenAd? _appOpenAd;
  late final Future<AppOpenAdLoader> _loader = _createLoader();
  bool _isLoading = false;
  bool _isShowing = false;
  bool _isObserverAttached = false;
  DateTime? _lastShownAt;

  /// Call once from main.dart after MobileAds.initialize().
  void start() {
    if (!_isObserverAttached) {
      WidgetsBinding.instance.addObserver(this);
      _isObserverAttached = true;
    }
    loadAppOpenAd();
  }

  Future<void> loadAppOpenAd() async {
    if (_isLoading || _appOpenAd != null) {
      return;
    }
    _isLoading = true;
    final loader = await _loader;
    await loader.loadAd(
      adRequestConfiguration: AdRequestConfiguration(adUnitId: adUnitId),
    );
  }

  Future<void> showAdIfAvailable() async {
    if (_isShowing) {
      return;
    }
    final ad = _appOpenAd;
    if (ad == null) {
      await loadAppOpenAd();
      return;
    }
    if (!_canShowNow()) {
      return;
    }
    _isShowing = true;
    _setAdEventListener(ad);
    await ad.show();
    await ad.waitForDismiss();
  }

  bool _canShowNow() {
    final lastShownAt = _lastShownAt;
    if (lastShownAt == null) {
      return true;
    }
    return DateTime.now().difference(lastShownAt) >= minTimeBetweenDisplays;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      showAdIfAvailable();
    }
  }

  void dispose() {
    if (_isObserverAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserverAttached = false;
    }
    _clearAd();
  }

  void _setAdEventListener(AppOpenAd ad) {
    ad.setAdEventListener(
      eventListener: AppOpenAdEventListener(
        onAdShown: () => debugPrint('App open ad shown'),
        onAdClicked: () => debugPrint('App open ad clicked'),
        onAdImpression: (data) =>
            debugPrint('App open ad impression: ${data.getRawData()}'),
        onAdDismissed: () {
          debugPrint('App open ad dismissed');
          _isShowing = false;
          _lastShownAt = DateTime.now();
          _clearAd();
          loadAppOpenAd();
        },
        onAdFailedToShow: (error) {
          debugPrint(
            'App open ad failed to show: ${error.description}',
          );
          _isShowing = false;
          _clearAd();
          loadAppOpenAd();
        },
      ),
    );
  }

  void _clearAd() {
    _appOpenAd?.destroy();
    _appOpenAd = null;
    _isLoading = false;
  }

  Future<AppOpenAdLoader> _createLoader() {
    return AppOpenAdLoader.create(
      onAdLoaded: (AppOpenAd ad) {
        debugPrint('App open ad loaded');
        _appOpenAd = ad;
        _isLoading = false;
      },
      onAdFailedToLoad: (error) {
        debugPrint(
          'App open ad failed to load: code=${error.code}, description=${error.description}',
        );
        _clearAd();
      },
    );
  }
}
