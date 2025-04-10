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
Map<String, dynamic> generateQuestions(
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

    // 二桁以上の掛け算の条件を満たすための A, B, intermediate を選定する
    bool valid = false;
    // ここで初期値を設定しておく
    int A = 0;
    int B = 0;
    int intermediate = 0;
    int attempts = 0;
    while (!valid && attempts < 100) {
      attempts++;
      int B_min = 10;
      int B_max = min(99, ((answer + 99) ~/ 10));
      if (B_min > B_max) {
        // この場合、条件を満たす B が存在しないので break
        break;
      }
      B = B_min + rand.nextInt(B_max - B_min + 1);

      // A の最小値を計算: A は最低でも 10 であり、(answer + A) >= 10 * B となる必要がある
      int A_min = max(10, 10 * B - answer);
      if (A_min > 99) continue;

      // (answer + A) % B == 0 となる A を探索
      int modNeeded = ((B - (answer % B)) % B);
      int candidate = modNeeded;
      if (candidate < A_min) {
        candidate += ((A_min - candidate + B - 1) ~/ B) * B;
      }
      if (candidate > 99) continue;
      List<int> validAs = [];
      for (int x = candidate; x <= 99; x += B) {
        if (x >= A_min) validAs.add(x);
      }
      if (validAs.isEmpty) continue;
      A = validAs[rand.nextInt(validAs.length)];
      intermediate = (answer + A) ~/ B;
      if (intermediate >= 10) {
        valid = true;
      }
    }

    // 二桁以上の掛け算が作れなかった場合、旧方式で式を作成する
    if (!valid) {
      B = rand.nextInt(4) + 2; // 2〜5
      A = rand.nextInt(90) + 10; // 10〜99
      while ((answer + A) % B != 0) {
        A++;
      }
      intermediate = (answer + A) ~/ B;
    }

    String expr = '($intermediate × $B) - $A';
    questionTexts.add(expr);
    questionAnswers.add(answer);
    index += segmentLength;
  }
  return {'texts': questionTexts, 'answers': questionAnswers};
}

/// ------------------ PiGameScreen（ゲーム画面） ------------------
class PiGameScreen extends StatefulWidget {
  const PiGameScreen({Key? key}) : super(key: key);

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
    // ファイル読み込み後、trim()で前後の空白・改行を削除し、
    // 必要ならreplaceAllで全ての空白文字を削除する
    String rawPiDigits = await rootBundle.loadString('assets/pi_digits.txt');
    String piDigits = rawPiDigits.replaceAll(RegExp(r'\s+'), '');

    // ファイル内容に合わせて totalDigits を設定する（例: piDigits.length）
    int totalDigits = piDigits.length;

    final questionsData = generateQuestions(piDigits, totalDigits: totalDigits);
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

  void _goToResult() async {
    _countdownTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    final highScore = prefs.getInt('highScore') ?? 0;
    if (_score > highScore) {
      await prefs.setInt('highScore', _score);
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ResultScreen(score: _score)),
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
  const ResultScreen({Key? key, required this.score}) : super(key: key);

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
    setState(() {
      _highScore = prefs.getInt('highScore') ?? 0;
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
                'ゲーム終了',
                style: TextStyle(color: Colors.white, fontSize: 32),
              ),
              const SizedBox(height: 24),
              Text(
                'あなたのスコア: $score',
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontSize: 24,
                ),
              ),
              if (_highScore != null)
                Text(
                  '最高スコア: $_highScore',
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
                child: const Text('Home /)৺৺(\\'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
