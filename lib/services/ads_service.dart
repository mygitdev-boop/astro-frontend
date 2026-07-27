import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralized AdMob logic -- banner, interstitial, and rewarded ads.
///
/// IMPORTANT: Ads only work on Android/iOS, NOT Flutter Web. If you're
/// testing with `flutter run -d chrome` (as this project has been so far),
/// you will see NO ads at all -- that's expected, not a bug. You'll need
/// an Android emulator or physical device to actually see these render.
///
/// SETUP STILL NEEDED (can't be done from code alone):
/// 1. Get real ad unit IDs from https://apps.admob.com once you have an
///    AdMob account + app registered. Replace the TEST IDs below.
/// 2. Add your AdMob App ID to android/app/src/main/AndroidManifest.xml,
///    inside the <application> tag:
///      <meta-data
///        android:name="com.google.android.gms.ads.APPLICATION_ID"
///        android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/>
/// 3. For iOS, add to ios/Runner/Info.plist:
///      <key>GADApplicationIdentifier</key>
///      <string>ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy</string>
/// These files live in your local Flutter project's platform folders,
/// which aren't part of this lib/-only repo -- edit them directly on
/// your machine.
class AdsService {
  static bool _initialized = false;

  // --- Google's official TEST ad unit IDs -- safe to use during
  // development, will only ever show Google's test ads, never real ones,
  // never earn revenue. Swap these for your real IDs before release.
  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
    return '';
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    return '';
  }

  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
    return '';
  }

  /// Call once, early in app startup (see main.dart).
  static Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  // ---------------------------------------------------------------------
  // Interstitial ads -- shown at natural breakpoints (e.g. every few chat
  // exchanges), never mid-action. Loaded ahead of time so it's ready
  // instantly when needed, then a fresh one is loaded for next time.
  // ---------------------------------------------------------------------
  static InterstitialAd? _interstitialAd;

  static void loadInterstitial() {
    if (kIsWeb) return;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => _interstitialAd = null,
      ),
    );
  }

  static void showInterstitialIfReady({void Function()? onDismissed}) {
    if (kIsWeb || _interstitialAd == null) {
      onDismissed?.call();
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial(); // pre-load the next one
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        onDismissed?.call();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // ---------------------------------------------------------------------
  // Rewarded ads -- used for "watch an ad to unlock more free questions"
  // when the free-tier daily chat limit is hit.
  // ---------------------------------------------------------------------
  static RewardedAd? _rewardedAd;

  static void loadRewarded() {
    if (kIsWeb) return;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) => _rewardedAd = null,
      ),
    );
  }

  static bool get isRewardedReady => _rewardedAd != null;

  static void showRewarded({
    required void Function() onRewardEarned,
    void Function()? onNotReady,
  }) {
    if (kIsWeb || _rewardedAd == null) {
      onNotReady?.call();
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewarded(); // pre-load the next one
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        onNotReady?.call();
      },
    );
    _rewardedAd!.show(onUserEarnedReward: (ad, reward) => onRewardEarned());
    _rewardedAd = null;
  }
}
