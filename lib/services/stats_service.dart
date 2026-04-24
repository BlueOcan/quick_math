import 'package:shared_preferences/shared_preferences.dart';

class StatsService {
  StatsService._();
  static final StatsService instance = StatsService._();

  static const String _keyHighScore = 'hs_overall';
  static const String _keyCoins = 'coins';

  int _highScore = 0;
  int _coins = 0;

  int get highScore => _highScore;
  int get coins => _coins;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _highScore = prefs.getInt(_keyHighScore) ?? 0;
    _coins = prefs.getInt(_keyCoins) ?? 0;
  }

  // Returns true if this session set a new high score
  Future<bool> saveSession({
    required int score,
    required int correctAnswers,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 1 correct answer = 1 coin
    _coins += correctAnswers;
    await prefs.setInt(_keyCoins, _coins);

    // Combined high score — beats both random and training
    bool isNew = false;
    if (score > _highScore) {
      _highScore = score;
      await prefs.setInt(_keyHighScore, _highScore);
      isNew = true;
    }
    return isNew;
  }
}
