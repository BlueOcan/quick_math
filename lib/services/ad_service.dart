import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AD UNIT IDs
// Replace these with your real AdMob IDs before publishing.
// These are Google's official test IDs — safe to use during development.
// ─────────────────────────────────────────────────────────────────────────────
class AdIds {
  // ── Android ───────────────────────────────────────────────────
  static const String _androidRewarded =
      'ca-app-pub-8934941458065542/5543557632';
  static const String _androidInterstitial =
      'ca-app-pub-8934941458065542/9834156439';

  // ── iOS ───────────────────────────────────────────────────────
  static const String _iosRewarded =
      'ca-app-pub-3940256099942544/1712485313'; // TODO: replace
  static const String _iosInterstitial =
      'ca-app-pub-3940256099942544/4411468910'; // TODO: replace

  static String get rewarded =>
      Platform.isIOS ? _iosRewarded : _androidRewarded;
  static String get interstitial =>
      Platform.isIOS ? _iosInterstitial : _androidInterstitial;
}

// ─────────────────────────────────────────────────────────────────────────────
// In-App Purchase ID
// ─────────────────────────────────────────────────────────────────────────────
const String kProProductId =
    'mathvibe_pro_lifetime'; // TODO: match Play/App Store

// ─────────────────────────────────────────────────────────────────────────────
// AdService — singleton, call AdService.instance everywhere
// ─────────────────────────────────────────────────────────────────────────────
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // ── State ──────────────────────────────────────────────────────
  bool _isPro = false;
  bool get isPro => _isPro;

  // Session interstitial counter
  int _sessionCount = 0;

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _rewardedLoading = false;
  bool _interstitialLoading = false;

  // IAP stream subscription
  StreamSubscription<List<PurchaseDetails>>? _iapSub;

  // ── Init ───────────────────────────────────────────────────────
  Future<void> init() async {
    // Load pro status from local prefs
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool('is_pro') ?? false;

    // Init AdMob SDK
    await MobileAds.instance.initialize();

    // Start IAP listener
    _iapSub = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (_) {},
    );

    // Restore purchases silently on launch
    await InAppPurchase.instance.restorePurchases();

    // Pre-load both ad types (only if not pro)
    if (!_isPro) {
      _loadRewarded();
      _loadInterstitial();
    }
  }

  void dispose() {
    _iapSub?.cancel();
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
  }

  // ── Rewarded Ad ────────────────────────────────────────────────
  // Call this to show "watch ad to continue" after a wrong answer
  // Returns true if user watched and earned the reward
  Future<bool> showRewardedAd(BuildContext context) async {
    if (_isPro) return false; // Pro users never see ads

    if (_rewardedAd == null) {
      // Ad not ready — show a snackbar and return false
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad not ready yet, try again shortly.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      _loadRewarded(); // Try to load for next time
      return false;
    }

    final completer = Completer<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewarded(); // Pre-load for next time
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

    return completer.future;
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
          // Retry after 30s
          Future.delayed(const Duration(seconds: 30), _loadRewarded);
        },
      ),
    );
  }

  // ── Interstitial Ad ────────────────────────────────────────────
  // Call this at the result screen. Shows ad every 3rd session.
  Future<void> maybeShowInterstitial(BuildContext context) async {
    if (_isPro) return;

    _sessionCount++;
    if (_sessionCount % 3 != 0) return; // Only every 3rd session

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

  // ── In-App Purchase ────────────────────────────────────────────
  Future<void> buyPro() async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) return;

    final response =
        await InAppPurchase.instance.queryProductDetails({kProProductId});
    if (response.productDetails.isEmpty) return;

    final purchaseParam = PurchaseParam(
      productDetails: response.productDetails.first,
    );
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID == kProProductId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await _setPro(true);
        }
        if (purchase.status == PurchaseStatus.error) {
          // Silently handle — user sees Store error dialog
        }
        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _setPro(bool value) async {
    _isPro = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', value);
    // Dispose loaded ads — pro users don't need them
    if (value) {
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _interstitialAd?.dispose();
      _interstitialAd = null;
    }
  }
}
