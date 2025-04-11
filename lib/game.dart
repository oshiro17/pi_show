import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // rootBundle を利用するため
import 'package:audioplayers/audioplayers.dart';
import 'package:pi_racer/main.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

// 以前のような硬コードされたpiDigitsは削除する

/// 指定桁数分（例では totalDigits で指定）から、ランダムな長さ（3～6桁）のセグメント毎に
/// 「((answer + A) ÷ B) × B - A」という式を生成し、正解（answer）とともに返す。
Map<String, dynamic> generateQuestions1(
  String piDigits, {
  int totalDigits = 300,
}) {
  List<String> questionTexts = [];
  List<int> questionAnswers = [];
  int index = 0;
  Random rand = Random();

  while (index < totalDigits) {
    int segmentLength = rand.nextInt(4) + 3; // 3〜6桁
    if (index + segmentLength > totalDigits) {
      segmentLength = totalDigits - index;
    }
    // 次の桁が存在して「0」なら、セグメントに含める
    while ((index + segmentLength < totalDigits) &&
        (piDigits[index + segmentLength] == '0')) {
      segmentLength++;
    }
    String segment = piDigits.substring(index, index + segmentLength);
    int answer = int.parse(segment);

    // ここから「数字２桁 × 数字１桁 ＋ 数字」の式を生成する部分
    // int X, Y, C;
    int X = 0, Y = 0, C = 0;
    bool valid = false;
    int attempts = 0;
    while (!valid && attempts < 100) {
      attempts++;
      X = rand.nextInt(90) + 10; // 10〜99 の2桁の数
      Y = rand.nextInt(9) + 1; // 1〜9 の1桁の数
      if (X * Y <= answer) {
        // 積が answer 以下なら有効
        C = answer - (X * Y);
        valid = true;
      }
    }
    if (!valid) {
      // 万が一条件を満たす組み合わせが見つからなければ
      X = 10;
      Y = 1;
      C = answer - (10 * 1);
    }

    String expr = '($X × $Y) + $C';
    questionTexts.add(expr);
    questionAnswers.add(answer);
    index += segmentLength;
  }
  return {'texts': questionTexts, 'answers': questionAnswers};
}

Map<String, dynamic> generateQuestions2(
  String piDigits, {
  int totalDigits = 300,
}) {
  List<String> questionTexts = [];
  List<int> questionAnswers = [];
  int index = 0;
  Random rand = Random();

  while (index < totalDigits) {
    int segmentLength = rand.nextInt(4) + 3; // 3～6桁
    if (index + segmentLength > totalDigits) {
      segmentLength = totalDigits - index;
    }
    // 次の桁が存在して「0」なら、セグメントに含める
    while ((index + segmentLength < totalDigits) &&
        (piDigits[index + segmentLength] == '0')) {
      segmentLength++;
    }
    String segment = piDigits.substring(index, index + segmentLength);
    int answer = int.parse(segment);

    // 「数字２桁 × 数字２桁 ＋ 数字」の式を生成する部分
    int X = 0, Y = 0, C = 0;
    bool valid = false;
    int attempts = 0;
    while (!valid && attempts < 100) {
      attempts++;
      X = rand.nextInt(90) + 10; // 10〜99 の2桁の数
      Y = rand.nextInt(90) + 10; // 10〜99 の2桁の数
      if (X * Y <= answer) {
        // 積が answer 以下なら有効
        C = answer - (X * Y);
        valid = true;
      }
    }
    if (!valid) {
      // 万が一条件を満たす組み合わせが見つからなければ
      X = 10;
      Y = 10;
      C = answer - (10 * 10);
    }

    String expr = '($X × $Y) + $C';
    questionTexts.add(expr);
    questionAnswers.add(answer);
    index += segmentLength;
  }
  return {'texts': questionTexts, 'answers': questionAnswers};
}

Map<String, dynamic> generateQuestions3(
  String piDigits, {
  int totalDigits = 300,
}) {
  List<String> questionTexts = [];
  List<int> questionAnswers = [];
  int index = 0;
  Random rand = Random();

  // 必ず6桁ずつ切り出す（answerが十分大きくなることを想定）
  while (index < totalDigits) {
    int segmentLength = 6;
    if (index + segmentLength > totalDigits) {
      // 残りの桁数が6未満の場合は終了
      break;
    }
    // 次の桁が存在して「0」であればセグメントに含める（連続性を保つため）
    while ((index + segmentLength < totalDigits) &&
        (piDigits[index + segmentLength] == '0')) {
      segmentLength++;
      if (index + segmentLength > totalDigits) break;
    }
    String segment = piDigits.substring(index, index + segmentLength);
    int answer = int.parse(segment);

    // 「数字3桁 × 数字3桁 ＋ 数字」の式を生成する部分
    int X = 0, Y = 0, C = 0;
    bool valid = false;
    int attempts = 0;
    while (!valid && attempts < 100) {
      attempts++;
      X = rand.nextInt(900) + 100; // 100〜999 の3桁の数
      Y = rand.nextInt(900) + 100; // 100〜999 の3桁の数
      if (X * Y <= answer) {
        C = answer - (X * Y);
        valid = true;
      }
    }
    if (!valid) {
      // 万が一条件を満たす組み合わせが見つからなければ
      X = 100;
      Y = 100;
      C = answer - (100 * 100);
    }

    String expr = '($X × $Y) + $C';
    questionTexts.add(expr);
    questionAnswers.add(answer);
    index += segmentLength;
  }

  return {'texts': questionTexts, 'answers': questionAnswers};
}

/// ------------------ PiGameScreen（ゲーム画面） ------------------
class PiGameScreen extends StatefulWidget {
  final bool usePi;
  final int level;

  const PiGameScreen({Key? key, required this.usePi, required this.level})
    : super(key: key);

  @override
  State<PiGameScreen> createState() => _PiGameScreenState();
}

class _PiGameScreenState extends State<PiGameScreen> {
  late final AudioPlayer _audioPlayer;
  late List<String> questionTexts;
  late List<int> questionAnswers;

  int _currentIndex = 0;
  String _userInput = '';
  int _score = 0;
  int _secondsLeft = 10;
  Timer? _countdownTimer;
  bool _isLoading = true; // 読み込み中かどうかを管理する変数

  // 音楽のオン／オフ状態を管理（true: 音楽再生中、false: 一時停止中）
  bool _musicOn = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.play(AssetSource('music.mp3'));
    _loadPiDigitsAndSetup();
  }

  Future<void> _loadPiDigitsAndSetup() async {
    String fileName =
        widget.usePi ? 'assets/pi_digits.txt' : 'assets/e_digits.txt';
    String rawDigits = await rootBundle.loadString(fileName);
    String digits = rawDigits.replaceAll(RegExp(r'\s+'), '');
    int totalDigits = digits.length;

    Map<String, dynamic> questionsData;

    switch (widget.level) {
      case 1:
        questionsData = generateQuestions1(digits, totalDigits: totalDigits);
        break;
      case 2:
        questionsData = generateQuestions2(digits, totalDigits: totalDigits);
        break;
      case 3:
        questionsData = generateQuestions3(digits, totalDigits: totalDigits);
        break;
      default:
        questionsData = generateQuestions1(digits, totalDigits: totalDigits);
        break;
    }

    questionTexts = questionsData['texts'];
    questionAnswers = questionsData['answers'];

    _startTimer();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  // タイマー関係のコードはそのまま利用…
  void _resetTimer() {
    _countdownTimer?.cancel();
    _secondsLeft = 10;
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
        _goToResult();
      }
    });
  }

  void _onButtonPressed(String label) {
    setState(() {
      if (label == 'C') {
        _userInput = '';
      } else if (label == 'BS') {
        if (_userInput.isNotEmpty) {
          _userInput = _userInput.substring(0, _userInput.length - 1);
        }
      } else {
        _userInput += label;
        if (_userInput == questionAnswers[_currentIndex].toString()) {
          _checkAnswer();
          _resetTimer();
        } else if (_userInput.length >= 18) {
          _userInput = '';
        }
      }
    });
  }

  void _checkAnswer() async {
    if (_userInput.isEmpty) return;
    await Future.delayed(const Duration(milliseconds: 100));
    if (int.tryParse(_userInput) == questionAnswers[_currentIndex]) {
      _score += questionAnswers[_currentIndex].toString().length;
      _userInput = '';
      if (_currentIndex < questionTexts.length - 1) {
        _currentIndex++;
      } else {
        _goToResult();
      }
    }
  }

  // void _goToResult() async {
  //   _countdownTimer?.cancel();
  //   final prefs = await SharedPreferences.getInstance();
  //   final highScore = prefs.getInt('highScore') ?? 0;
  //   if (_score > highScore) {
  //     await prefs.setInt('highScore', _score);
  //   }
  //   if (!mounted) return;
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(builder: (_) => ResultScreen(score: _score)),
  //   );
  // }
  void _goToResult() async {
    _countdownTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();

    // ここでキーを分ける
    final scoreKey = widget.usePi ? 'highScore' : 'highScore_e';
    final highScore = prefs.getInt(scoreKey) ?? 0;

    if (_score > highScore) {
      await prefs.setInt(scoreKey, _score);
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(score: _score, usePi: widget.usePi),
      ),
    );
  }

  void _giveUp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('(｡ )( ｡)', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to give up?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Bring it on',
                style: TextStyle(color: Colors.lightBlueAccent),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じるだけ
              },
            ),
            TextButton(
              child: const Text(
                'Rage Quit',
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
                _goToResult(); // リザルト画面に遷移
              },
            ),
          ],
        );
      },
    );
  }

  // 音楽のオン／オフを切り替えるメソッド
  void _toggleMusic() {
    setState(() {
      _musicOn = !_musicOn;
    });
    if (_musicOn) {
      // 音楽を再生（再開）
      _audioPlayer.resume();
    } else {
      // 音楽を一時停止
      _audioPlayer.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 読み込み中はローディング画面を表示
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = questionTexts[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // トップバー：問題番号、タイマー、次の問題プレビュー、音楽のオン／オフボタンを表示
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左側に現在の問題番号
                  Text(
                    '${_currentIndex + 1}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  // 右側にタイマー、次の問題プレビューと音楽の切替ボタンをまとめる
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$_secondsLeft s',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 18,
                            ),
                          ),
                          if (_currentIndex < questionTexts.length - 1)
                            Text(
                              'next: ${questionTexts[_currentIndex + 1]}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      // 音楽のオン／オフボタン
                      IconButton(
                        onPressed: _toggleMusic,
                        icon: Icon(
                          _musicOn ? Icons.music_note : Icons.music_off,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 問題文表示
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                currentQuestion,
                style: const TextStyle(color: Colors.white, fontSize: 24),
                textAlign: TextAlign.center,
              ),
            ),
            // ユーザー入力の表示＋、残り4秒以下の場合は正解も小さく表示
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(
                    _userInput,
                    style: const TextStyle(
                      color: Colors.lightBlueAccent,
                      fontSize: 32,
                    ),
                  ),
                  if (_secondsLeft <= 4)
                    Text(
                      'Answer: ${questionAnswers[_currentIndex]}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            // 数字入力パッド（以下、既存のコードの入力パッド）
            _buildKeypad(),
            ElevatedButton(
              onPressed: _giveUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Give Up 🏳️',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKeypadButton('C'),
              _buildKeypadButton('0'),
              _buildKeypadButton('BS'),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String label) {
    return SizedBox(
      width: 100,
      height: 70,
      child: ElevatedButton(
        onPressed: () => _onButtonPressed(label),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.grey[850],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}

// 以下、ResultScreenはそのまま利用…
class ResultScreen extends StatefulWidget {
  final int score;
  final bool usePi;
  const ResultScreen({Key? key, required this.score, required this.usePi})
    : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int? _highScore;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.usePi ? 'highScore' : 'highScore_e';
    setState(() {
      _highScore = prefs.getInt(key) ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.score;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Game Over',
                style: TextStyle(color: Colors.white, fontSize: 32),
              ),
              const SizedBox(height: 24),
              Text(
                'Your Score: $score',
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontSize: 24,
                ),
              ),
              if (_highScore != null)
                Text(
                  'High Score: $_highScore',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MyApp()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Back to Home\\'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
