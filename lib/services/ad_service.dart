import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdIds {
  static const String _androidRewarded =
      'ca-app-pub-8934941458065542/8712986739';
  static const String _androidInterstitial =
      'ca-app-pub-8934941458065542/6134835563';
  static const String _androidBanner = 'ca-app-pub-8934941458065542/7208333371';

  static const String _iosRewarded = 'ca-app-pub-3940256099942544/1712485313';
  static const String _iosInterstitial =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _iosBanner = 'ca-app-pub-3940256099942544/2934735716';

  static String get rewarded =>
      Platform.isIOS ? _iosRewarded : _androidRewarded;
  static String get interstitial =>
      Platform.isIOS ? _iosInterstitial : _androidInterstitial;
  static String get banner => Platform.isIOS ? _iosBanner : _androidBanner;
}

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isPro = false;
  bool get isPro => _isPro;

  int _sessionCount = 0;

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _rewardedLoading = false;
  bool _interstitialLoading = false;

  bool _isShowingAd = false;
  bool get isShowingAd => _isShowingAd;

  // ── TIMER PAUSE/RESUME CALLBACKS ───────────────────────────────
  VoidCallback? onAdWillShow;
  VoidCallback? onAdDidDismiss;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool('is_pro') ?? false;
    await MobileAds.instance.initialize();
    if (!_isPro) {
      _loadRewarded();
      _loadInterstitial();
    }
  }

  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    onAdWillShow = null;
    onAdDidDismiss = null;
  }

  BannerAd createBanner() {
    return BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    );
  }

  Future<bool> showRewardedAd(BuildContext context) async {
    if (_isPro) return false;
    if (_isShowingAd) return false;

    if (_rewardedAd == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad not ready yet, try again shortly.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      _loadRewarded();
      return false;
    }

    _isShowingAd = true;
    onAdWillShow?.call();

    final completer = Completer<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isShowingAd = false;
        onAdDidDismiss?.call();
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _isShowingAd = false;
        onAdDidDismiss?.call();
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (_, reward) {
        if (!completer.isCompleted) completer.complete(true);
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _isShowingAd = false;
        onAdDidDismiss?.call();
        return false;
      },
    );
  }

  void _loadRewarded() {
    if (_rewardedLoading || _isPro) return;
    _rewardedLoading = true;
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedLoading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedLoading = false;
          Future.delayed(const Duration(seconds: 30), _loadRewarded);
        },
      ),
    );
  }

  Future<void> maybeShowInterstitial(BuildContext context) async {
    if (_isPro) return;
    if (_isShowingAd) return;

    _sessionCount++;
    if (_sessionCount % 3 != 0) return;

    if (_interstitialAd == null) {
      _loadInterstitial();
      return;
    }

    _isShowingAd = true;
    onAdWillShow?.call();

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isShowingAd = false;
        onAdDidDismiss?.call();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitialAd = null;
        _isShowingAd = false;
        onAdDidDismiss?.call();
        _loadInterstitial();
      },
    );

    await _interstitialAd!.show();
  }

  void _loadInterstitial() {
    if (_interstitialLoading || _isPro) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          _interstitialLoading = false;
          Future.delayed(const Duration(seconds: 30), _loadInterstitial);
        },
      ),
    );
  }

  Future<void> setPro(bool value) async {
    _isPro = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', value);
    if (value) {
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _interstitialAd?.dispose();
      _interstitialAd = null;
    }
  }
}
