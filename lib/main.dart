import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pi_racer/game.dart';
import 'package:pi_racer/pi_digits.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

// MyAppをStatefulWidgetに変更して、言語切替用の状態と現在のレベルを管理する
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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

  bool isJapanese = true;
  int currentLevel = 1;

  // 言語を切り替える関数
  void toggleLanguage() {
    setState(() {
      isJapanese = !isJapanese;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 指定のアクセントカラーとボタンカラー
    final Color accentColor = Colors.lightBlueAccent;
    final Color buttonColor = const Color(0xFF424242);

    // 表示テキストを言語状態に応じて定義
    String levelOneLabel = isJapanese ? "レベル 1" : "Level 1";
    String levelOneDesc =
        isJapanese ? "2桁 × 1桁 の問題に挑戦！" : "2-digit × 1-digit Challenge";

    String levelTwoLabel = isJapanese ? "レベル 2" : "Level 2";
    String levelTwoDesc =
        isJapanese ? "2桁 × 2桁 の問題に挑戦！" : "2-digit × 2-digit Challenge";

    String levelThreeLabel = isJapanese ? "レベル 3" : "Level 3";
    String levelThreeDesc =
        isJapanese ? "3桁 × 3桁 の問題に挑戦！" : "3-digit × 3-digit Challenge";

    String titleText =
        isJapanese ? 'ただの暗算アプリ。\n 暗算チャレンジ' : 'Mental Math \nChallenge';
    String supportText = isJapanese ? '開発者を支援' : 'Support Developer';
    // 言語ボタンは切替用の表示（現在日本語なら「English」と表示）
    String languageButtonText = isJapanese ? 'English' : '日本語';
    String startButtonText = isJapanese ? 'スタート' : 'Start';
    String subtitleText =
        isJapanese ? 'さあ、君も暗算王だ(?)' : "Let's be the mental math champion(?)";
    String currentLevelText =
        isJapanese
            ? '現在のレベル :  $_highScore'
            : 'Current Level : $_highScore(𝄑.𝄑)';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: titleText,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: accentColor,
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.montserratTextTheme(Theme.of(context).textTheme),
      ),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                titleText,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Builder(
                  builder: (context) {
                    return IconButton(
                      icon: const Icon(Icons.help_outline, color: Colors.white),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: Colors.black,
                              title: Text(
                                isJapanese ? "アプリの説明" : "About this App",
                                style: const TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                isJapanese
                                    ? "このアプリは、円周率を打つことで計算が早いふりができます。\n円周率を覚えて楽しもう"
                                    : "This app creates an illusion of fast calculation by entering digits of pi.\nBy memorizing pi and typing 314... you get the calculation answer.",
                                style: const TextStyle(color: Colors.white),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    isJapanese ? "閉じる" : "Close",
                                    style: TextStyle(
                                      color: Colors.lightBlueAccent,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12.0,
                runSpacing: 8.0,
                children: [
                  _MenuButton(
                    title: supportText,
                    color: buttonColor,
                    textColor: accentColor,
                    onPressed: () async {
                      const url =
                          'https://www.amazon.jp/hz/wishlist/ls/TZLH9Q88S3EZ?ref_=wl_share';
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                  ),
                  _MenuButton(
                    title: languageButtonText,
                    color: buttonColor,
                    textColor: accentColor,
                    onPressed: toggleLanguage, // タップで言語切替
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              // 現在のレベルをかっこよく表示するウィジェット
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: accentColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentLevelText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(
                        builder:
                            (context) => ElevatedButton(
                              onPressed: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PiGameScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                foregroundColor: accentColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40.0,
                                  vertical: 16.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(levelOneLabel),
                                  const SizedBox(height: 4),
                                  Text(
                                    levelOneDesc,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                      ),

                      const SizedBox(height: 16.0),
                      Builder(
                        builder:
                            (context) => ElevatedButton(
                              onPressed: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PiGameScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                foregroundColor: accentColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40.0,
                                  vertical: 16.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(levelTwoLabel),
                                  const SizedBox(height: 4),
                                  Text(
                                    levelTwoDesc,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                      ),
                      const SizedBox(height: 16.0),
                      Builder(
                        builder:
                            (context) => ElevatedButton(
                              onPressed: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PiGameScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                foregroundColor: accentColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40.0,
                                  vertical: 16.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(levelThreeLabel),
                                  const SizedBox(height: 4),
                                  Text(
                                    levelThreeDesc,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        subtitleText,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          color: Colors.black,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start, // 両端に寄せる配置に変更
              children: [
                // ボタン部分
                Builder(
                  builder:
                      (context) => GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PiDigitsScreen(
                                    highScore: _highScore ?? 0,
                                  ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.lightBlueAccent.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'パイチェック',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                ),
                // ボタンと右側テキストの間のスペース
                const SizedBox(width: 16),
                // 右側のテキスト。Expandedで余白を埋めるようにする
                const Expanded(
                  child: Text(
                    "© 2024 nonoka. All rights reserved.╰o╯╰o╯",
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ),

        // // Bottom Navigation Bar
        // bottomNavigationBar: BottomAppBar(
        //   color: Colors.black,
        //   child: Padding(
        //     padding: const EdgeInsets.symmetric(
        //       horizontal: 16.0,
        //       vertical: 8.0,
        //     ),
        //     child: Row(
        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //       children: [
        //         IconButton(
        //           icon: const Icon(Icons.menu_book, color: Colors.white),
        //           onPressed: () {
        //             Navigator.push(
        //               context,
        //               MaterialPageRoute(
        //                 builder:
        //                     (context) =>
        //                         PiDigitsScreen(highScore: _highScore ?? 0),
        //               ),
        //             );
        //           },
        //         ),

        //         const Text(
        //           "© 2024 nonoka. All rights reserved.",
        //           style: TextStyle(color: Colors.grey, fontSize: 13),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
      ),
    );
  }
}

// _MenuButtonを、タップ時のコールバックを受け取るように修正
class _MenuButton extends StatelessWidget {
  final String title;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;
  const _MenuButton({
    Key? key,
    required this.title,
    required this.color,
    required this.textColor,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed ?? () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      child: Text(title),
    );
  }
}
