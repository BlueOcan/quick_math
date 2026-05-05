import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AD UNIT IDs — Google official test IDs
// Replace with real AdMob IDs before publishing
// ─────────────────────────────────────────────────────────────────────────────
class AdIds {
  // ── Android ───────────────────────────────────────────────────
  static const String _androidRewarded =
      'ca-app-pub-8934941458065542/8712986739';
  static const String _androidInterstitial =
      'ca-app-pub-8934941458065542/6134835563';
  static const String _androidBanner = 'ca-app-pub-8934941458065542/7208333371';

  // ── iOS ───────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
// AdService — singleton, call AdService.instance everywhere
// ─────────────────────────────────────────────────────────────────────────────
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // ── State ──────────────────────────────────────────────────────
  bool _isPro = false;
  bool get isPro => _isPro;

  int _sessionCount = 0;

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _rewardedLoading = false;
  bool _interstitialLoading = false;

  // ── Init ───────────────────────────────────────────────────────
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
  }

  // ── Banner Ad ──────────────────────────────────────────────────
  // Use BannerAdWidget() in your UI directly
  BannerAd createBanner() {
    return BannerAd(
      adUnitId: AdIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    );
  }

  // ── Rewarded Ad ────────────────────────────────────────────────
  Future<bool> showRewardedAd(BuildContext context) async {
    if (_isPro) return false;

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

    final completer = Completer<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
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
      onTimeout: () => false,
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

  // ── Interstitial Ad ────────────────────────────────────────────
  Future<void> maybeShowInterstitial(BuildContext context) async {
    if (_isPro) return;

    _sessionCount++;
    if (_sessionCount % 3 != 0) return;

    if (_interstitialAd == null) {
      _loadInterstitial();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitialAd = null;
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

  // ── Set Pro manually (for future use) ─────────────────────────
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
