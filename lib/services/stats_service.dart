import 'package:shared_preferences/shared_preferences.dart';

class StatsService {
  StatsService._();
  static final StatsService instance = StatsService._();

  static const String _keyCoins = 'coins';

  int _coins = 0;

  int get coins => _coins;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _coins = prefs.getInt(_keyCoins) ?? 0;
  }

  Future<void> saveSession({
    required int score,
    required int correctAnswers,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 1 correct answer = 1 coin
    _coins += correctAnswers;
    await prefs.setInt(_keyCoins, _coins);
  }
}
