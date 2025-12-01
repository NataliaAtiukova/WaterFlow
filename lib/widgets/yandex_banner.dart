import 'package:flutter/material.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

/// Sticky bottom banner widget that can be reused on any screen.
class YandexStickyBanner extends StatefulWidget {
  const YandexStickyBanner({
    super.key,
    this.adUnitId = 'R-M-17907836-1',
    this.backgroundColor,
    this.padding = const EdgeInsets.only(top: 8),
  });

  final String adUnitId;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  @override
  State<YandexStickyBanner> createState() => _YandexStickyBannerState();
}

class _YandexStickyBannerState extends State<YandexStickyBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  double? _bannerHeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null && !_isLoading) {
      _createAndLoadBanner();
    }
  }

  Future<void> _createAndLoadBanner() async {
    final width = MediaQuery.sizeOf(context).width.toInt();
    final size = BannerAdSize.sticky(width: width);
    _isLoading = true;
    final calculatedSize = await size.getCalculatedBannerAdSize();
    if (!mounted) {
      return;
    }
    final banner = BannerAd(
      adUnitId: widget.adUnitId,
      adSize: size,
      adRequest: const AdRequest(),
      onAdLoaded: () {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoaded = true;
          _isLoading = false;
        });
      },
      onAdFailedToLoad: (error) {
        debugPrint(
          'Yandex banner failed to load: code=${error.code}, message=${error.description}',
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoaded = false;
          _isLoading = false;
        });
      },
      onAdClicked: () => debugPrint('Yandex banner clicked'),
      onImpression: (data) =>
          debugPrint('Yandex banner impression: ${data.getRawData()}'),
      onLeftApplication: () =>
          debugPrint('Yandex banner left the application'),
      onReturnedToApplication: () =>
          debugPrint('Yandex banner returned to app'),
      onAdClose: () {
        if (!mounted) {
          return;
        }
        debugPrint('Yandex banner closed by user');
        setState(() {
          _isLoaded = false;
        });
        _bannerAd?.destroy();
        _bannerAd = null;
        _isLoading = false;
        _createAndLoadBanner();
      },
    );
    setState(() {
      _bannerAd = banner;
      _bannerHeight = calculatedSize.height.toDouble();
    });
    banner.loadAd(adRequest: const AdRequest());
  }

  /// Manually trigger a reload (for example, after network changes).
  void reload() {
    final banner = _bannerAd;
    if (banner == null) {
      _createAndLoadBanner();
    } else {
      banner.loadAd(adRequest: const AdRequest());
    }
  }

  @override
  void dispose() {
    _bannerAd?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.backgroundColor ?? Colors.transparent;
    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        color: background,
        padding: widget.padding,
        child: _isLoaded && _bannerAd != null
            ? AdWidget(bannerAd: _bannerAd!)
            : SizedBox(height: _bannerHeight ?? 0),
      ),
    );
  }
}
